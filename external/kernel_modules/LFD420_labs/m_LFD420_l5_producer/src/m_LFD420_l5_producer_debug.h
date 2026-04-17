#ifndef _EXT_KMOD_M_LFD420_L5_PRODUCER_DEBUG_H_
#define _EXT_KMOD_M_LFD420_L5_PRODUCER_DEBUG_H_

#ifdef DEBUG_MODE_ENABLED

/* * ============================================================================
 * 1. Smart Tracing Macros
 * ============================================================================
 * Automatically injects the function name and line number into the kernel log.
 * Usage: M_LFD420_L5_PRODUCER_DBG("Variable x is %d\n", x);
 */
#define M_LFD420_L5_PRODUCER_DBG(fmt, ...) \
    pr_info("[%s:%s:%d] " fmt, KBUILD_MODNAME, __func__, __LINE__, ##__VA_ARGS__)

/* * ============================================================================
 * 2. Debug Subsystem Prototypes
 * ============================================================================
 */
void m_LFD420_l5_producer_debug_init(void);
void m_LFD420_l5_producer_debug_cleanup(void);

/* Expose internal debug variables to core.c if needed */
extern u32 m_LFD420_l5_producer_debug_hit_count;

#else

/* * ============================================================================
 * Stubs for Production Build (Cost: 0 Bytes, 0 Cycles)
 * ============================================================================
 */
#define M_LFD420_L5_PRODUCER_DBG(fmt, ...) do { } while (0)

static inline void m_LFD420_l5_producer_debug_init(void) { }
static inline void m_LFD420_l5_producer_debug_cleanup(void) { }

#endif /* DEBUG_MODE_ENABLED */

#endif /* _EXT_KMOD_M_LFD420_L5_PRODUCER_DEBUG_H_ */
