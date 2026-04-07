#ifndef dobby_h
#define dobby_h

// 1. Önce standart kütüphaneleri dışarıda dahil et (Hata buradaydı)
#include <stdbool.h>
#include <stdint.h>
#include <sys/types.h>
#include <string.h>

// 2. Şimdi C linkage başlat
#ifdef __cplusplus
extern "C" {
#endif

typedef uintptr_t addr_t;
typedef uint32_t addr32_t;
typedef uint64_t addr64_t;

typedef void *asm_func_t;

#if defined(__arm__)
typedef struct {
  uint32_t dummy_0;
  uint32_t dummy_1;
  uint32_t dummy_2;
  uint32_t sp;
  union {
    uint32_t r[13];
    struct {
      uint32_t r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12;
    } regs;
  } general;
  uint32_t lr;
} DobbyRegisterContext;
#elif defined(__arm64__) || defined(__aarch64__)
#define ARM64_TMP_REG_NDX_0 17

typedef union _FPReg {
  __int128_t q;
  struct {
    double d1;
    double d2;
  } d;
  struct {
    float f1;
    float f2;
    float f3;
    float f4;
  } f;
} FPReg;

typedef struct {
  uint64_t dummy_0;
  uint64_t dummy_1;
  uint64_t sp;
  union {
    uint64_t x[29];
    struct {
      uint64_t x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20, x21, x22, x23,
          x24, x25, x26, x27, x28;
    } regs;
  } general;
  uint64_t fp;
  uint64_t lr;
} DobbyRegisterContext;
#endif

// --- Dobby Temel Fonksiyonları ---

// Kod yamama (Memory Patch)
int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);

// Fonksiyon kancalama (Inline Hook)
int DobbyHook(void *address, void *fake_func, void **out_origin_func);

// Versiyon bilgisi
const char *DobbyGetVersion();

// Sembol çözücü
void *DobbySymbolResolver(const char *image_name, const char *symbol_name);

// Import tablosu değiştirme
int DobbyImportTableReplace(char *image_name, char *symbol_name, void *fake_func, void **orig_func);

#ifdef __cplusplus
}
#endif

#endif
