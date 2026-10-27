#include <stdint.h>
static int32_t masks_set(uint16_t cw, uint32_t mxcsr) {
  return (cw & UINT16_C(0x003f)) == UINT16_C(0x003f)
      && (mxcsr & UINT32_C(0x00001f80)) == UINT32_C(0x00001f80);
}
int32_t wrf_phy_interp_all_masked(void) {
#if defined(__i386__) || defined(__x86_64__)
  uint16_t cw;
  uint32_t mxcsr;
  __asm__ volatile ("fnstcw %0" : "=m" (cw));
  __asm__ volatile ("stmxcsr %0" : "=m" (mxcsr));
  return masks_set(cw, mxcsr);
#else
  return 0;
#endif
}
