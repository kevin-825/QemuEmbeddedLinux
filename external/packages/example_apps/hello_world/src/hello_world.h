/*
 * Auto-generated header for hello_world
 */
#ifndef EXT_PKG_HELLO_WORLD_H_
#define EXT_PKG_HELLO_WORLD_H_

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define HELLO_WORLD_VERSION_MAJOR 1
#define HELLO_WORLD_VERSION_MINOR 0
#define HELLO_WORLD_VERSION_PATCH 0

/* Universal Status Codes */
typedef enum {
    HELLO_WORLD_SUCCESS    =  0,
    HELLO_WORLD_FINISHED   =  1,  
    HELLO_WORLD_ERR_INVAL  = -1,
    HELLO_WORLD_ERR_NOMEM  = -2,
    HELLO_WORLD_ERR_IO     = -3
} hello_world_status_t;

/* Opaque context pointer */
typedef struct hello_world_ctx hello_world_ctx_t;

/* Core API */


#ifdef __cplusplus
}
#endif
#endif /* EXT_PKG_HELLO_WORLD_H_ */
