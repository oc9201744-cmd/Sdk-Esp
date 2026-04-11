#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include <dlfcn.h>
#include "dobby.h"

// Log prefix for debugging via Console.app
#define LOG_TAG "[BaybarsBypass]"
#define NSLog(...) NSLog(@LOG_TAG " " __VA_ARGS__)

// Hedef kütüphanenin ASLR (Address Space Layout Randomization) slide'ını bulmak için yardımcı fonksiyon
uintptr_t get_target_image_slide(const char* image_name_substring) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char* name = _dyld_get_image_name(i);
        if (strstr(name, image_name_substring)) {
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    // Eğer framework değil de ana binary içine gömülüyse (statically linked)
    return _dyld_get_image_vmaddr_slide(0);
}

#pragma mark - 1. Exported API Hooks

// Exported: AnoSDKInitEx_0
static int (*orig_AnoSDKInitEx_0)(void* a1, void* a2, void* a3);
int repl_AnoSDKInitEx_0(void* a1, void* a2, void* a3) {
    NSLog(@"AnoSDKInitEx_0 tetiklendi. Init argümanları filtreleniyor...");
    // Init akışını tamamen bozmamak için orijinali çağırıyoruz, 
    // ancak dilersen burada a2/a3 konfigürasyon pointer'larını manipüle edebilirsin.
    return orig_AnoSDKInitEx_0(a1, a2, a3);
}

// Exported: AnoSDKGetReportData
// Sunucuya gönderilecek telemetri/tespit verilerini buradan çekiyor. İçini boşaltıyoruz.
static int (*orig_AnoSDKGetReportData)(void* buffer, int* length);
int repl_AnoSDKGetReportData(void* buffer, int* length) {
    NSLog(@"AnoSDKGetReportData çağrıldı. Payload sıfırlanıyor!");
    if (length != NULL) {
        *length = 0; // Gönderilecek veri boyutunu 0 yapıyoruz
    }
    // 0 genelde başarılı/veri yok anlamına gelir. Gerekirse return 1 yapılabilir.
    return 0; 
}

#pragma mark - 2. Offset (Internal) Hooks

// Offset: REPORT (sub_3667C)
static void* (*orig_report_sub_3667C)(void* a1, void* a2, void* a3);
void* repl_report_sub_3667C(void* a1, void* a2, void* a3) {
    NSLog(@"[!] Ana REPORT kanalı (sub_3667C) engellendi.");
    return NULL; // Rapor gönderimini drop et
}

// Offset: COREREPORT (sub_371E0+D8) -> Çekirdek güvenlik raporu
static void* (*orig_corereport)(void* a1, void* a2);
void* repl_corereport(void* a1, void* a2) {
    NSLog(@"[!] COREREPORT TDM / Core raporu engellendi.");
    return NULL; 
}

// Offset: HBCheck (sub_447B0) -> Heartbeat
static bool (*orig_hbcheck)(void* a1);
bool repl_hbcheck(void* a1) {
    // Oyundan atılmamak için heartbeat kontrolünü her zaman "True" (Başarılı) döndürüyoruz.
    NSLog(@"[~] HBCheck (Heartbeat) bypass edildi.");
    return true; 
}

// Offset: sub_AC484 -> /config Endpoint İndirme
static void* (*orig_config_download)(void* a1, void* a2);
void* repl_config_download(void* a1, void* a2) {
    NSLog(@"[~] /config indirme talebi yakalandı. Dinamik kurallar (custom_tcj) engelleniyor.");
    return NULL; // Yeni hile tespit kurallarının (custom_tcj.zip) inmesini engeller
}


#pragma mark - Constructor / Injection Entry

__attribute__((constructor)) static void init_baybars_bypass() {
    // Binary belleğe tamamen otursun diye ufak bir gecikme ekliyoruz
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"BaybarsBypass başlatılıyor... Memory hesaplamaları yapılıyor.");
        
        // Hedef kütüphanenin adını girin (Örn: "Tersafe", "Tss", veya ana binary ise hedef oyunun adı)
        uintptr_t aslr_slide = get_target_image_slide("AnaOyunBinaryAdiVeyaSDK"); 
        NSLog(@"ASLR Slide: 0x%lx", aslr_slide);

        // 1. EXPORT EDILEN SEMBOLLERI HOOKLA (dlsym ile)
        void *ptr_AnoSDKInitEx_0 = dlsym(RTLD_DEFAULT, "AnoSDKInitEx_0");
        if (ptr_AnoSDKInitEx_0) {
            DobbyHook(ptr_AnoSDKInitEx_0, (void *)repl_AnoSDKInitEx_0, (void **)&orig_AnoSDKInitEx_0);
        }

        void *ptr_AnoGetReport = dlsym(RTLD_DEFAULT, "AnoSDKGetReportData");
        if (ptr_AnoGetReport) {
            DobbyHook(ptr_AnoGetReport, (void *)repl_AnoSDKGetReportData, (void **)&orig_AnoSDKGetReportData);
        }

        // 2. OFFSET BAZLI İÇ FONKSİYONLARI HOOKLA (ASLR + Offset)
        // Not: Offset adresleri IDA'daki Base Adres'e göre (genelde 0x100000000) hesaplanmalıdır. 
        // Eğer IDA base 0 ise direkt offseti toplayın.
        
        void *ptr_report = (void *)(aslr_slide + 0x3667C);
        DobbyHook(ptr_report, (void *)repl_report_sub_3667C, (void **)&orig_report_sub_3667C);

        void *ptr_corereport = (void *)(aslr_slide + 0x371E0); // +D8 branch'inin başı
        DobbyHook(ptr_corereport, (void *)repl_corereport, (void **)&orig_corereport);

        void *ptr_hbcheck = (void *)(aslr_slide + 0x447B0);
        DobbyHook(ptr_hbcheck, (void *)repl_hbcheck, (void **)&orig_hbcheck);

        void *ptr_config = (void *)(aslr_slide + 0xAC484);
        DobbyHook(ptr_config, (void *)repl_config_download, (void **)&orig_config_download);

        NSLog(@"Tüm ACE endpoint ve raporlama hookları başarıyla uygulandı.");
    });
}
