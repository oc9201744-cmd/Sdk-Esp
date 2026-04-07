// ========================================
// ONURCAN BYPASS - FULL FIXED VERSION
// ========================================

#import <Foundation/Foundation.h>
#import <substrate.h>
#include <sys/sysctl.h>
#include <mach/mach.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>   // _dyld_get_image_vmaddr_slide için gerekli
#include <sys/stat.h>      // struct stat yapısı için gerekli
#include <unistd.h>        // ptrace ve sistem çağrıları için gerekli
#include <sys/types.h>
#include <errno.h>

// ptrace bazen headerlarda gizlidir, manuel tanımlıyoruz:
extern "C" int ptrace(int request, pid_t pid, caddr_t addr, int data);

// ========================================
// CRITICAL OFFSETS
// ========================================
#define OFFSET_HBCHECK          0x447B0
#define OFFSET_DATA_CHECK       0xE4554
#define OFFSET_REPORT_SYSTEM    0x3667C
#define OFFSET_CRC_CHECK        0x156F8
#define OFFSET_HASH_CHECK       0x30028
#define OFFSET_ENTRY_GATE       0x44A50
#define OFFSET_TCJ_CRASHER      0x4471C
#define OFFSET_CRASH_POINT      0xD5624

#define FLAG_OFFSET_188         0x188
#define FLAG_OFFSET_189         0x189
#define FLAG_OFFSET_18A         0x18A
#define FLAG_OFFSET_18B         0x18B
#define FLAG_OFFSET_18C         0x18C

// ========================================
// HOOK TYPE DEFINITIONS
// ========================================
typedef void* (*heartbeat_check_t)(void* obj);
typedef int (*data_check_t)(void* data, int type);
typedef void (*report_system_t)(void* report_data);
typedef uint32_t (*crc_check_t)(void* data, size_t size);
typedef uint32_t (*hash_check_t)(void* data);
typedef int (*entry_gate_t)(void* obj, void* param);
typedef void (*tcj_crasher_t)(void* obj, void* list);
typedef void (*crash_point_t)(void* obj);

static heartbeat_check_t original_heartbeat = NULL;
static data_check_t original_data_check = NULL;
static report_system_t original_report = NULL;
static crc_check_t original_crc = NULL;
static hash_check_t original_hash = NULL;
static entry_gate_t original_entry_gate = NULL;
static tcj_crasher_t original_tcj_crasher = NULL;
static crash_point_t original_crash_point = NULL;

// ========================================
// BYPASS HOOK FUNCTIONS
// ========================================

static void* hooked_heartbeat(void* obj) {
    if (obj) {
        *((uint8_t*)obj + FLAG_OFFSET_188) = 0;
        *((uint8_t*)obj + FLAG_OFFSET_189) = 0;
        *((uint8_t*)obj + FLAG_OFFSET_18A) = 0;
        *((uint8_t*)obj + FLAG_OFFSET_18B) = 0;
        *((uint8_t*)obj + FLAG_OFFSET_18C) = 0;
    }
    return obj;
}

static int hooked_data_check(void* data, int type) {
    return 0;
}

static void hooked_report(void* report_data) {
    return;
}

static uint32_t hooked_crc(void* data, size_t size) {
    return 0;
}

static uint32_t hooked_hash(void* data) {
    return 0;
}

static int hooked_entry_gate(void* obj, void* param) {
    if (obj) {
        *((uint8_t*)obj + FLAG_OFFSET_18B) = 0;
    }
    return 0;
}

static void hooked_tcj_crasher(void* obj, void* list) {
    return;
}

static void hooked_crash_point(void* obj) {
    return;
}

// ========================================
// SYSTEM HOOKS (Fixed stat & ptrace)
// ========================================

static int (*original_sysctl)(int*, u_int, void*, size_t*, void*, size_t) = NULL;
static int (*original_ptrace)(int, pid_t, caddr_t, int) = NULL;
// struct stat belirsizliğini gidermek için tam tanım:
static int (*original_stat)(const char*, struct stat*) = NULL;

static int hooked_sysctl(int *name, u_int namelen, void *oldp,
                        size_t *oldlenp, void *newp, size_t newlen) {
    int ret = original_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
    if (ret == 0 && oldp && namelen == 4 && 
        name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID) {
        ((struct kinfo_proc*)oldp)->kp_proc.p_flag &= ~P_TRACED;
    }
    return ret;
}

static int hooked_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    if (request == 31) return 0; // PT_DENY_ATTACH bypass
    return original_ptrace ? original_ptrace(request, pid, addr, data) : 0;
}

static int hooked_stat(const char *path, struct stat *buf) {
    const char* jb_paths[] = {
        "/Applications/Cydia.app", "/Library/MobileSubstrate",
        "/usr/sbin/sshd", "/bin/bash", NULL
    };
    for (int i = 0; jb_paths[i]; i++) {
        if (strstr(path, jb_paths[i])) {
            errno = ENOENT;
            return -1;
        }
    }
    return original_stat(path, buf);
}

// ========================================
// INITIALIZATION
// ========================================

__attribute__((constructor))
static void InitializeBypass() {
    // ASLR Slide Alınıyor
    intptr_t slide = _dyld_get_image_vmaddr_slide(0);
    
    // Anti-Cheat Hooks
    MSHookFunction((void*)(slide + OFFSET_HBCHECK), (void*)hooked_heartbeat, (void**)&original_heartbeat);
    MSHookFunction((void*)(slide + OFFSET_DATA_CHECK), (void*)hooked_data_check, (void**)&original_data_check);
    MSHookFunction((void*)(slide + OFFSET_REPORT_SYSTEM), (void*)hooked_report, (void**)&original_report);
    MSHookFunction((void*)(slide + OFFSET_CRC_CHECK), (void*)hooked_crc, (void**)&original_crc);
    MSHookFunction((void*)(slide + OFFSET_HASH_CHECK), (void*)hooked_hash, (void**)&original_hash);
    MSHookFunction((void*)(slide + OFFSET_ENTRY_GATE), (void*)hooked_entry_gate, (void**)&original_entry_gate);
    MSHookFunction((void*)(slide + OFFSET_TCJ_CRASHER), (void*)hooked_tcj_crasher, (void**)&original_tcj_crasher);
    MSHookFunction((void*)(slide + OFFSET_CRASH_POINT), (void*)hooked_crash_point, (void**)&original_crash_point);
    
    // System Hooks
    MSHookFunction((void*)sysctl, (void*)hooked_sysctl, (void**)&original_sysctl);
    MSHookFunction((void*)ptrace, (void*)hooked_ptrace, (void**)&original_ptrace);
    // Global stat fonksiyonunu belirtmek için :: kullanıyoruz
    MSHookFunction((void*)::stat, (void*)hooked_stat, (void**)&original_stat);
    
    NSLog(@"[ONURCAN BYPASS] All Fixes Applied Successfully!");
}
