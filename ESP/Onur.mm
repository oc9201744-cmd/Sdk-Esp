#include <stdint.h>
#include <stdio.h>
#include <mach-o/dyld.h>
#include <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Dobby'nin doğru dosya yoluyla eklenmesi (Typo düzeltildi: dooby -> dobby)
#include "dobby.h" 

// ============================================================
// MARK: - Anogs Slide Hesaplama
// ============================================================

static uintptr_t get_anogs_slide() {
    static uintptr_t anogs_slide = 0;
    if (anogs_slide == 0) {
        uint32_t count = _dyld_image_count();
        for (uint32_t i = 0; i < count; i++) {
            const char *name = _dyld_get_image_name(i);
            // Modül adını burada kontrol ediyoruz
            if (name && strstr(name, "anogs")) {
                anogs_slide = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
                NSLog(@"[BYPASS] Anogs modülü bulundu! Slide: 0x%lx", (long)anogs_slide);
                break;
            }
        }
    }
    return anogs_slide;
}

// Makroyu anogs_slide kullanacak şekilde tanımlıyoruz
#define DOBBY_HOOK(offset, fake_func) \
    if (get_anogs_slide() != 0) { \
        DobbyHook((void*)(get_anogs_slide() + 0x##offset), (void*)fake_func, NULL); \
    }

// ============================================================
// MARK: - Fake Fonksiyonlar (Aynı kalıyor)
// ============================================================

int Fake_sub_EC504(void) { return 1; }
int Fake_sub_EC7CC(void) { return 0; }
void Fake_sub_63D4(void* b) { return; }
void Fake_sub_6174(int t, void* d) { return; }
int Fake_sub_7EE4(void* a1, void* a2, void* a3, void* a4, void* a5, void* a6, void* a7, void* a8) { return 0; }
void Fake_sub_ECE4(void* o, void* i, size_t s) { return; }
void* Fake_sub_ED338(void* a1, int a2, void* a3) { static unsigned char fr[16] = {0}; return fr; }
int Fake_sub_EE0C(void* o, const char* f, void* b) { return 0; }
void* Fake_sub_52B0(void* s) { static unsigned char ace[0xA8] = {0}; return ace; }
int Fake_sub_5300(void* s, int c) { return 0; }
unsigned int Fake_sub_4C18(void* f) { return 0x0; }
void* Fake_sub_6BBFC(void) { static unsigned char c[4096] = {0}; return c; }
int Fake_sub_6996C(void) { return 0; }
int Fake_sub_1733C(void* o, const char* f) { if(o) *(uint32_t*)o = 0xDEADBEEF; return 0; }
int Fake_sub_6AC4(void* o, const char* m) { return 0; }

// App Delegate Hookları (Objective-C)
void Fake_applicationWillTerminate(id self, SEL _cmd, UIApplication* app) { 
    NSLog(@"[BYPASS] Terminate engellendi."); 
}

// ============================================================
// MARK: - Init
// ============================================================

__attribute__((constructor))
static void init() {
    // Anogs modülünün yüklenmesini garantiye almak için kısa bir gecikme
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // DOOBY_HOOK değil, DOBBY_HOOK olarak düzelttik
        DOBBY_HOOK(4C18, Fake_sub_4C18)
        DOBBY_HOOK(6BBFC, Fake_sub_6BBFC)
        DOBBY_HOOK(6996C, Fake_sub_6996C)
        DOBBY_HOOK(1733C, Fake_sub_1733C)
        DOBBY_HOOK(6AC4, Fake_sub_6AC4)
        DOBBY_HOOK(52B0, Fake_sub_52B0)
        DOBBY_HOOK(5300, Fake_sub_5300)
        
        // Kapalı/Kapanma Kontrolleri
        DOBBY_HOOK(EC504, Fake_sub_EC504)
        DOBBY_HOOK(EC7CC, Fake_sub_EC7CC)
        DOBBY_HOOK(63D4, Fake_sub_63D4)
        DOBBY_HOOK(6174, Fake_sub_6174)
        DOBBY_HOOK(7EE4, Fake_sub_7EE4)
        DOBBY_HOOK(ECE4, Fake_sub_ECE4)
        DOBBY_HOOK(ED338, Fake_sub_ED338)
        DOBBY_HOOK(EE0C, Fake_sub_EE0C)

        // Obj-C Hookları
        Class appDelegate = NSClassFromString(@"AppDelegate");
        if (appDelegate) {
            class_replaceMethod(appDelegate, @selector(applicationWillTerminate:), (IMP)Fake_applicationWillTerminate, "v@:@");
        }
        
        NSLog(@"[BYPASS] Anogs Bypass Başarıyla Yüklendi!");
    });
}
