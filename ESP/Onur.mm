#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <mach-o/dyld.h>
#import <Foundation/Foundation.h>

// Dobby'yi kütüphane çakışmalarını önleyerek çağırıyoruz
#include "dobby.h"

// --- Offsets ---
#define OFFSET_HBCHECK          0x447B0
#define OFFSET_DATA_CHECK       0xE4554
#define OFFSET_REPORT_SYSTEM    0x3667C
#define OFFSET_CRC_CHECK        0x156F8
#define OFFSET_HASH_CHECK       0x30028
#define OFFSET_ENTRY_GATE       0x44A50
#define OFFSET_TCJ_CRASHER      0x4471C
#define OFFSET_CRASH_POINT      0xD5624

// --- Orjinal Fonksiyon Tutucular ---
static void* (*orig_heartbeat)(void* obj) = NULL;
static int (*orig_data_check)(void* data, int type) = NULL;
static void (*orig_report)(void* report_data) = NULL;

// --- Hook Fonksiyonları ---
static void* hooked_heartbeat(void* obj) {
    if (obj) {
        *((uint8_t*)obj + 0x188) = 0;
        *((uint8_t*)obj + 0x189) = 0;
        *((uint8_t*)obj + 0x18A) = 0;
        *((uint8_t*)obj + 0x18B) = 0;
        *((uint8_t*)obj + 0x18C) = 0;
    }
    return orig_heartbeat ? orig_heartbeat(obj) : obj;
}

static int hooked_data_check(void* data, int type) { return 0; }
static void hooked_report(void* report_data) { return; }
static uint32_t hooked_generic_zero(void* data) { return 0; }

__attribute__((constructor))
static void InitializeBypass() {
    // ASLR Slide
    intptr_t slide = (intptr_t)_dyld_get_image_vmaddr_slide(0);
    
    if (slide > 0) {
        // DobbyHook kullanımı
        DobbyHook((void*)(slide + OFFSET_HBCHECK), (void*)hooked_heartbeat, (void**)&orig_heartbeat);
        DobbyHook((void*)(slide + OFFSET_DATA_CHECK), (void*)hooked_data_check, (void**)&orig_data_check);
        DobbyHook((void*)(slide + OFFSET_REPORT_SYSTEM), (void*)hooked_report, (void**)&orig_report);
        
        // Diğerleri için basit sıfırlama hookları
        DobbyHook((void*)(slide + OFFSET_CRC_CHECK), (void*)hooked_generic_zero, NULL);
        DobbyHook((void*)(slide + OFFSET_HASH_CHECK), (void*)hooked_generic_zero, NULL);
        
        NSLog(@"[BYPASS] Dobby bypass active on slide: 0x%lx", (long)slide);
    }
}
