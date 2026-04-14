#ifndef _EXT_KMOD_HELLOMOD_DEBUG_H_
#define _EXT_KMOD_HELLOMOD_DEBUG_H_

#ifdef DEBUG_MODE_ENABLED

/* * ============================================================================
 * 1. Smart Tracing Macros
 * ============================================================================
 * Automatically injects the function name and line number into the kernel log.
 * Usage: HELLOMOD_DBG("Variable x is %d\n", x);
 */
#define HELLOMOD_DBG(fmt, ...) \
    pr_info("[%s:%s:%d] " fmt, KBUILD_MODNAME, __func__, __LINE__, ##__VA_ARGS__)

/* * ============================================================================
 * 2. Debug Subsystem Prototypes
 * ============================================================================
 */
void helloMod_debug_init(void);
void helloMod_debug_cleanup(void);

/* Expose internal debug variables to core.c if needed */
extern u32 helloMod_debug_hit_count;

#else

/* * ============================================================================
 * Stubs for Production Build (Cost: 0 Bytes, 0 Cycles)
 * ============================================================================
 */
#define HELLOMOD_DBG(fmt, ...) do { } while (0)

static inline void helloMod_debug_init(void) { }
static inline void helloMod_debug_cleanup(void) { }

#endif /* DEBUG_MODE_ENABLED */

#endif /* _EXT_KMOD_HELLOMOD_DEBUG_H_ */
