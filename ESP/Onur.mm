// 1. ÖNCE standart kütüphaneleri dışarıda yükle
#include <stdbool.h>
#include <stdint.h>
#include <sys/types.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <mach-o/dyld.h>

// 2. MODÜL HATASINI SİLİP SÜPÜREN MAKROLAR
// Derleyiciye bu kütüphanelerin zaten yüklendiğini zorla kabul ettiriyoruz
#ifndef _STDBOOL_H
#define _STDBOOL_H
#endif
#ifndef _STDINT_H
#define _STDINT_H
#endif
#ifndef _SYS_TYPES_H
#define _SYS_TYPES_H
#endif

// 3. EXTERN "C" ÇAKIŞMASINI ÖNLEMEK İÇİN DOBBY'Yİ KANDIRIYORUZ
// Dobby'nin içindeki extern "C" bloğunu biz burada manuel kontrol altına alıyoruz
#ifdef __cplusplus
extern "C" {
#endif

// Dobby'nin içindeki include'ları devre dışı bırakmak için geçici hile
#define dobby_h_include_guard
#import <Foundation/Foundation.h>

// 4. DOBBY'Yİ ÇAĞIR
#include "dobby.h"

#ifdef __cplusplus
}
#endif

// --- OFFSETS ---
#define OFFSET_HBCHECK          0x447B0
#define OFFSET_DATA_CHECK       0xE4554
#define OFFSET_REPORT_SYSTEM    0x3667C
#define OFFSET_CRC_CHECK        0x156F8
#define OFFSET_HASH_CHECK       0x30028
#define OFFSET_ENTRY_GATE       0x44A50
#define OFFSET_TCJ_CRASHER      0x4471C
#define OFFSET_CRASH_POINT      0xD5624

// --- POINTERS ---
static void* (*orig_heartbeat)(void* obj) = NULL;
static int (*orig_data_check)(void* data, int type) = NULL;
static void (*orig_report)(void* report_data) = NULL;

// --- HOOKS ---
static void* hooked_heartbeat(void* obj) {
    if (obj) {
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

// --- INIT ---
__attribute__((constructor))
static void InitializeBypass() {
    intptr_t slide = (intptr_t)_dyld_get_image_vmaddr_slide(0);
    
    // Eğer ana modül bulunamazsa ShadowTrackerExtra'yı ara (PUBG Fix)
    if (slide <= 0) {
        for (uint32_t i = 0; i < _dyld_image_count(); i++) {
            const char *name = _dyld_get_image_name(i);
            if (name && strstr(name, "ShadowTrackerExtra")) {
                slide = _dyld_get_image_vmaddr_slide(i);
                break;
            }
        }
    }

    if (slide != 0) {
        DobbyHook((void*)(slide + OFFSET_HBCHECK), (void*)hooked_heartbeat, (void**)&orig_heartbeat);
        DobbyHook((void*)(slide + OFFSET_DATA_CHECK), (void*)hooked_data_check, (void**)&orig_data_check);
        DobbyHook((void*)(slide + OFFSET_REPORT_SYSTEM), (void*)hooked_report, (void**)&orig_report);
        DobbyHook((void*)(slide + OFFSET_CRC_CHECK), (void*)hooked_generic_zero, NULL);
        DobbyHook((void*)(slide + OFFSET_HASH_CHECK), (void*)hooked_generic_zero, NULL);
        DobbyHook((void*)(slide + OFFSET_ENTRY_GATE), (void*)hooked_generic_zero, NULL);
        DobbyHook((void*)(slide + OFFSET_TCJ_CRASHER), (void*)hooked_generic_zero, NULL);
        DobbyHook((void*)(slide + OFFSET_CRASH_POINT), (void*)hooked_generic_zero, NULL);
        
        NSLog(@"[BYPASS] Dobby Basarili! Slide: 0x%lx", (long)slide);
    }
}
