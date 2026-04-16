/*
 * Auto-generated header for lab0_primitive
 */
#ifndef EXT_PKG_LAB0_PRIMITIVE_H_
#define EXT_PKG_LAB0_PRIMITIVE_H_

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define LAB0_PRIMITIVE_VERSION_MAJOR 1
#define LAB0_PRIMITIVE_VERSION_MINOR 0
#define LAB0_PRIMITIVE_VERSION_PATCH 0

/* Universal Status Codes */
typedef enum {
    LAB0_PRIMITIVE_SUCCESS    =  0,
    LAB0_PRIMITIVE_FINISHED   =  1,  
    LAB0_PRIMITIVE_ERR_INVAL  = -1,
    LAB0_PRIMITIVE_ERR_NOMEM  = -2,
    LAB0_PRIMITIVE_ERR_IO     = -3
} lab0_primitive_status_t;

/* Opaque context pointer */
typedef struct lab0_primitive_ctx lab0_primitive_ctx_t;

/* Core API */


#ifdef __cplusplus
}
#endif
#endif /* EXT_PKG_LAB0_PRIMITIVE_H_ */
