// 1. ÖNCE Standart kütüphaneleri dışarıda yükle
#include <stdbool.h>
#include <stdint.h>
#include <sys/types.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <mach-o/dyld.h>

// 2. Dobby'nin içindeki hata veren satırları bypass et
#ifndef _STDBOOL_H
#define _STDBOOL_H
#endif
#ifndef _STDINT_H
#define _STDINT_H
#endif
#ifndef _SYS_TYPES_H
#define _SYS_TYPES_H
#endif

// 3. Şimdi Framework ve Dobby'yi güvenle çağırabiliriz
#import <Foundation/Foundation.h>
#include "dobby.h"

// --- OFFSETS ---
// Not: Oyun güncellendiyse bu offsetleri IDA'dan kontrol etmen gerekir.
#define OFFSET_HBCHECK          0x447B0
#define OFFSET_DATA_CHECK       0xE4554
#define OFFSET_REPORT_SYSTEM    0x3667C
#define OFFSET_CRC_CHECK        0x156F8
#define OFFSET_HASH_CHECK       0x30028
#define OFFSET_ENTRY_GATE       0x44A50
#define OFFSET_TCJ_CRASHER      0x4471C
#define OFFSET_CRASH_POINT      0xD5624

// --- ORIGINAL FUNCTION POINTERS ---
static void* (*orig_heartbeat)(void* obj) = NULL;
static int (*orig_data_check)(void* data, int type) = NULL;
static void (*orig_report)(void* report_data) = NULL;

// --- HOOK FUNCTIONS ---

// Heartbeat hook'u: Flagleri temizler ve orijinali çağırır.
static void* hooked_heartbeat(void* obj) {
    if (obj) {
        // Bellek adreslerine güvenli yazım
        uintptr_t addr = (uintptr_t)obj;
        *(uint8_t*)(addr + 0x188) = 0;
        *(uint8_t*)(addr + 0x189) = 0;
        *(uint8_t*)(addr + 0x18A) = 0;
        *(uint8_t*)(addr + 0x18B) = 0;
        *(uint8_t*)(addr + 0x18C) = 0;
    }
    return orig_heartbeat ? orig_heartbeat(obj) : obj;
}

static int hooked_data_check(void* data, int type) { return 0; }
static void hooked_report(void* report_data) { return; }
static uint32_t hooked_generic_zero(void* data) { return 0; }

// --- INITIALIZATION ---

__attribute__((constructor))
static void InitializeBypass() {
    // ASLR Slide değerini al (Oyunun base adresini bulur)
    intptr_t slide = (intptr_t)_dyld_get_image_vmaddr_slide(0);
    
    // Eğer slide 0 gelirse (bazı durumlarda) alternatif yöntem gerekebilir
    if (slide == 0) {
        for (uint32_t i = 0; i < _dyld_image_count(); i++) {
            if (strstr(_dyld_get_image_name(i), "ShadowTrackerExtra")) {
                slide = _dyld_get_image_vmaddr_slide(i);
                break;
            }
        }
    }

    if (slide != 0) {
        // DobbyHook: Fonksiyonları kancalar
        DobbyHook((void*)(slide + OFFSET_HBCHECK), (void*)hooked_heartbeat, (void**)&orig_heartbeat);
        DobbyHook((void*)(slide + OFFSET_DATA_CHECK), (void*)hooked_data_check, (void**)&orig_data_check);
        DobbyHook((void*)(slide + OFFSET_REPORT_SYSTEM), (void*)hooked_report, (void**)&orig_report);
        
        // Geri kalanları sadece etkisiz hale getiriyoruz
        DobbyHook((void*)(slide + OFFSET_CRC_CHECK), (void*)hooked_generic_zero, NULL);
        DobbyHook((void*)(slide + OFFSET_HASH_CHECK), (void*)hooked_generic_zero, NULL);
        DobbyHook((void*)(slide + OFFSET_ENTRY_GATE), (void*)hooked_generic_zero, NULL);
        DobbyHook((void*)(slide + OFFSET_TCJ_CRASHER), (void*)hooked_generic_zero, NULL);
        DobbyHook((void*)(slide + OFFSET_CRASH_POINT), (void*)hooked_generic_zero, NULL);
        
        NSLog(@"[BYPASS] Dobby Bypass Yuklendi. Slide: 0x%lx", (long)slide);
    } else {
        NSLog(@"[BYPASS] KRITIK HATA: Slide degeri bulunamadi!");
    }
}
