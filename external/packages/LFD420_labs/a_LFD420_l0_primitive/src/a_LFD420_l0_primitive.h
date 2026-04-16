/*
 * Auto-generated header for a_LFD420_l0_primitive
 */
#ifndef EXT_PKG_A_LFD420_L0_PRIMITIVE_H_
#define EXT_PKG_A_LFD420_L0_PRIMITIVE_H_

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define A_LFD420_L0_PRIMITIVE_VERSION_MAJOR 1
#define A_LFD420_L0_PRIMITIVE_VERSION_MINOR 0
#define A_LFD420_L0_PRIMITIVE_VERSION_PATCH 0

/* Universal Status Codes */
typedef enum {
    A_LFD420_L0_PRIMITIVE_SUCCESS    =  0,
    A_LFD420_L0_PRIMITIVE_FINISHED   =  1,  
    A_LFD420_L0_PRIMITIVE_ERR_INVAL  = -1,
    A_LFD420_L0_PRIMITIVE_ERR_NOMEM  = -2,
    A_LFD420_L0_PRIMITIVE_ERR_IO     = -3
} a_LFD420_l0_primitive_status_t;

/* Opaque context pointer */
typedef struct a_LFD420_l0_primitive_ctx a_LFD420_l0_primitive_ctx_t;

/* Core API */


#ifdef __cplusplus
}
#endif
#endif /* EXT_PKG_A_LFD420_L0_PRIMITIVE_H_ */
