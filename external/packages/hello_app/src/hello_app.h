/*
 * Auto-generated header for hello_app
 */
#ifndef EXT_PKG_HELLO_APP_H_
#define EXT_PKG_HELLO_APP_H_

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define HELLO_APP_VERSION_MAJOR 1
#define HELLO_APP_VERSION_MINOR 0
#define HELLO_APP_VERSION_PATCH 0

/* Universal Status Codes */
typedef enum {
    HELLO_APP_SUCCESS    =  0,
    HELLO_APP_FINISHED   =  1,  
    HELLO_APP_ERR_INVAL  = -1,
    HELLO_APP_ERR_NOMEM  = -2,
    HELLO_APP_ERR_IO     = -3
} hello_app_status_t;

/* Opaque context pointer */
typedef struct hello_app_ctx hello_app_ctx_t;

/* Core API */


#ifdef __cplusplus
}
#endif
#endif /* EXT_PKG_HELLO_APP_H_ */
