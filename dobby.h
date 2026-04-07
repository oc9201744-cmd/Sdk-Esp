#ifndef dobby_h
#define dobby_h

// 1. Kütüphaneleri DIŞARIYA aldık (Hata buradaydı, düzeltildi)
#include <stdbool.h>
#include <stdint.h>
#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef uintptr_t addr_t;
typedef uint32_t addr32_t;
typedef uint64_t addr64_t;
typedef void *asm_func_t;

// Register Context (Arm64 için düzeltildi)
#if defined(__arm64__) || defined(__aarch64__)
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

// --- Fonksiyon Tanımları ---
int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);
int DobbyHook(void *address, void *fake_func, void **out_origin_func);
int DobbyDestroy(void *address);
const char *DobbyGetVersion();
void *DobbySymbolResolver(const char *image_name, const char *symbol_name);

#ifdef __cplusplus
}
#endif

#endif
