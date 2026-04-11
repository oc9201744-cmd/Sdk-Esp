#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import "dobby.h"

// --- Global Değişkenler ---
uintptr_t anogs_base = 0;

// --- 1. Raporlama ve Veri İletişimini Manipüle Et ---
// sub_3667C: Veri paketleme ve raporlama merkezi.
// Burayı susturmak, hile verisinin paketlenmesini engeller.
int (*orig_sub_3667C)(void *a1, void *a2, void *a3);
int repl_sub_3667C(void *a1, void *a2, void *a3) {
    // Paket oluşumunu engelle ama SDK'yı çökertme
    return 0; 
}

// sub_EC584: Güvenlik kontrolü doğrulama flag'i.
// Sürekli '1' (Güvenli) dönmesi gerekir.
int repl_is_secure(void *a1) {
    return 1;
}

// --- 2. Syscall (SVC 0) Kontrolleri ---
// ptrace anti-debug kontrolünü susturur.
int (*orig_ptrace)(int request, pid_t pid, caddr_t addr, int data);
int repl_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    if (request == 31) return 0; // PT_DENY_ATTACH bypass
    return orig_ptrace(request, pid, addr, data);
}

// --- 3. Stealth Patching ve Hooking ---
void perform_bypass() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        if (strstr(_dyld_get_image_name(i), "Anogs")) {
            anogs_base = _dyld_get_image_vmaddr_slide(i);
            break;
        }
    }

    if (!anogs_base) return;

    // A. INSTRUMENTATION PATCHING (DobbyCodePatch)
    // Bu yöntem DobbyHook'tan daha gizlidir, CRC'ye daha az takılır.
    uint8_t ret_opcode[] = {0xC0, 0x03, 0x5F, 0xD6}; // RET (ARM64)
    uint8_t mov_w0_1_ret[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6}; // MOV W0, #1; RET

    // Jailbreak/Hile Tespit Raporu (sub_B43B4)
    DobbyCodePatch((void *)(anogs_base + 0xB43B4), ret_opcode, 4);
    
    // B. INLINE HOOKING (Kritik Fonksiyonlar)
    // Raporlama kanalı (0x3667C)
    DobbyHook((void *)(anogs_base + 0x3667C), (void *)repl_sub_3667C, (void **)&orig_sub_3667C);
    
    // Güvenlik Onayı (0xEC584)
    DobbyCodePatch((void *)(anogs_base + 0xEC584), mov_w0_1_ret, 8);

    // C. SYSCALL BYPASS
    void *ptrace_addr = dlsym(RTLD_DEFAULT, "ptrace");
    if (ptrace_addr) {
        DobbyHook(ptrace_addr, (void *)repl_ptrace, (void **)&orig_ptrace);
    }
    
    NSLog(@"[Baybars-X] Tüm güvenlik katmanları susturuldu.");
}

__attribute__((constructor))
static void init() {
    // Oyunun ve Anogs'un tamamen yüklenmesi için 2 saniye bekle.
    // Çok erken hook atarsan crash, geç kalırsan ban yersin.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        perform_bypass();
    });
}
