#import <Foundation/Foundation.h>
#include "dobby.h" // Ana dizindeki header
#include <mach-o/dyld.h>
#include <sys/sysctl.h>
#include <unistd.h>

// --- Offsets ---
#define OFFSET_HBCHECK          0x447B0
#define OFFSET_DATA_CHECK       0xE4554
#define OFFSET_REPORT_SYSTEM    0x3667C
#define OFFSET_CRC_CHECK        0x156F8
#define OFFSET_HASH_CHECK       0x30028
#define OFFSET_ENTRY_GATE       0x44A50
#define OFFSET_TCJ_CRASHER      0x4471C
#define OFFSET_CRASH_POINT      0xD5624

// --- Original Function Pointers (Dobby için void* yeterli) ---
static void* (*orig_heartbeat)(void* obj) = NULL;
static int (*orig_data_check)(void* data, int type) = NULL;
static void (*orig_report)(void* report_data) = NULL;
static uint32_t (*orig_crc)(void* data, size_t size) = NULL;
static uint32_t (*orig_hash)(void* data) = NULL;
static int (*orig_entry_gate)(void* obj, void* param) = NULL;
static void (*orig_tcj_crasher)(void* obj, void* list) = NULL;
static void (*orig_crash_point)(void* obj) = NULL;

// --- Hooked Functions ---
static void* hooked_heartbeat(void* obj) {
    if (obj) {
        *((uint8_t*)obj + 0x188) = 0;
        *((uint8_t*)obj + 0x189) = 0;
        *((uint8_t*)obj + 0x18A) = 0;
        *((uint8_t*)obj + 0x18B) = 0;
        *((uint8_t*)obj + 0x18C) = 0;
    }
    return obj; // Heartbeat loop'unu bozmamak için obj dönüyoruz
}

static int hooked_data_check(void* data, int type) { return 0; }
static void hooked_report(void* report_data) { return; }
static uint32_t hooked_crc(void* data, size_t size) { return 0; }
static uint32_t hooked_hash(void* data) { return 0; }
static int hooked_entry_gate(void* obj, void* param) { return 0; }
static void hooked_tcj_crasher(void* obj, void* list) { return; }
static void hooked_crash_point(void* obj) { return; }

__attribute__((constructor))
static void InitializeBypass() {
    // ASLR Slide
    intptr_t slide = (intptr_t)_dyld_get_image_vmaddr_slide(0);
    
    // DOBBY HOOKS
    // Format: DobbyHook((void*)adres, (void*)yeni, (void**)&eski);
    
    DobbyHook((void*)(slide + OFFSET_HBCHECK), (void*)hooked_heartbeat, (void**)&orig_heartbeat);
    DobbyHook((void*)(slide + OFFSET_DATA_CHECK), (void*)hooked_data_check, (void**)&orig_data_check);
    DobbyHook((void*)(slide + OFFSET_REPORT_SYSTEM), (void*)hooked_report, (void**)&orig_report);
    DobbyHook((void*)(slide + OFFSET_CRC_CHECK), (void*)hooked_crc, (void**)&orig_crc);
    DobbyHook((void*)(slide + OFFSET_HASH_CHECK), (void*)hooked_hash, (void**)&orig_hash);
    DobbyHook((void*)(slide + OFFSET_ENTRY_GATE), (void*)hooked_entry_gate, (void**)&orig_entry_gate);
    DobbyHook((void*)(slide + OFFSET_TCJ_CRASHER), (void*)hooked_tcj_crasher, (void**)&orig_tcj_crasher);
    DobbyHook((void*)(slide + OFFSET_CRASH_POINT), (void*)hooked_crash_point, (void**)&orig_crash_point);
    
    NSLog(@"[BYPASS] Dobby Hooks Active!");
}
