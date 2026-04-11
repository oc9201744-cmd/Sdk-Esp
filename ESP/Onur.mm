#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import "dobby.h" // Dobby kütüphanesini projene eklediğinden emin ol

// --- Orijinal Fonksiyon Saklayıcıları ---
static int (*orig_AnoSDKInitEx_0)(void *a1);
static int (*orig_sub_3667C)(void *a1, void *a2, void *a3);

// --- Hook Fonksiyonları ---

// Raporlama kanalı (Logları susturur)
int repl_sub_3667C(void *a1, void *a2, void *a3) {
    // Rapor göndermeyi engellemek için sadece 0 dönüyoruz
    return 0;
}

// SDK Başlatma
int repl_AnoSDKInitEx_0(void *a1) {
    NSLog(@"[Baybars] AnoSDKInitEx_0 Hook Tetiklendi!");
    return 0; // Başarılı süsü ver
}

// --- Yardımcı Fonksiyon: Anogs Slide Bulucu ---
uintptr_t get_module_base_address(const char *moduleName) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (strstr(name, moduleName)) {
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0;
}

// --- Ana Yükleyici ---
__attribute__((constructor))
static void start_dobby_hooks() {
    // Anogs'un belleğe yüklenmesi için kısa bir süre tanı
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 1. Kütüphane Slide Değerini Al
        uintptr_t anogs_slide = get_module_base_address("Anogs");
        
        if (anogs_slide == 0) {
            NSLog(@"[Baybars] HATA: Anogs kütüphanesi bulunamadı!");
            return;
        }

        NSLog(@"[Baybars] Anogs Base Slide: 0x%lx", anogs_slide);

        // 2. Offset Hook (0x3667C - Log Raporlama)
        // Logda EXC_BAD_ACCESS veren yer burasıydı, artık doğru adresteyiz.
        void *target_ptr = (void *)(anogs_slide + 0x3667C);
        
        DobbyHook(target_ptr, (void *)repl_sub_3667C, (void **)&orig_sub_3667C);
        NSLog(@"[Baybars] Dobby: sub_3667C hooklandı.");

        // 3. Sembol Hook (AnoSDKInitEx_0)
        // Semboller dlsym ile daha güvenli bulunur.
        void *symbol_ptr = dlsym(RTLD_DEFAULT, "AnoSDKInitEx_0");
        if (symbol_ptr) {
            DobbyHook(symbol_ptr, (void *)repl_AnoSDKInitEx_0, (void **)&orig_AnoSDKInitEx_0);
            NSLog(@"[Baybars] Dobby: AnoSDKInitEx_0 hooklandı.");
        }
    });
}
