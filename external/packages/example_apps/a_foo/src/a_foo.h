/*
 * Auto-generated header for a_foo
 */
#ifndef EXT_PKG_A_FOO_H_
#define EXT_PKG_A_FOO_H_

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define A_FOO_VERSION_MAJOR 1
#define A_FOO_VERSION_MINOR 0
#define A_FOO_VERSION_PATCH 0

/* Universal Status Codes */
typedef enum {
    A_FOO_SUCCESS    =  0,
    A_FOO_FINISHED   =  1,  
    A_FOO_ERR_INVAL  = -1,
    A_FOO_ERR_NOMEM  = -2,
    A_FOO_ERR_IO     = -3
} a_foo_status_t;

/* Opaque context pointer */
typedef struct a_foo_ctx a_foo_ctx_t;

/* Core API */


#ifdef __cplusplus
}
#endif
#endif /* EXT_PKG_A_FOO_H_ */
