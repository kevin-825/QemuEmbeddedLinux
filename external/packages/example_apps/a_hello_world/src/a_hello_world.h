/*
 * Auto-generated header for a_hello_world
 */
#ifndef EXT_PKG_A_HELLO_WORLD_H_
#define EXT_PKG_A_HELLO_WORLD_H_

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define A_HELLO_WORLD_VERSION_MAJOR 1
#define A_HELLO_WORLD_VERSION_MINOR 0
#define A_HELLO_WORLD_VERSION_PATCH 0

/* Universal Status Codes */
typedef enum {
    A_HELLO_WORLD_SUCCESS    =  0,
    A_HELLO_WORLD_FINISHED   =  1,  
    A_HELLO_WORLD_ERR_INVAL  = -1,
    A_HELLO_WORLD_ERR_NOMEM  = -2,
    A_HELLO_WORLD_ERR_IO     = -3
} a_hello_world_status_t;

/* Opaque context pointer */
typedef struct a_hello_world_ctx a_hello_world_ctx_t;

/* Core API */


#ifdef __cplusplus
}
#endif
#endif /* EXT_PKG_A_HELLO_WORLD_H_ */
