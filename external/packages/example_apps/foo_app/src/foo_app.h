/*
 * Auto-generated header for foo_app
 */
#ifndef EXT_PKG_FOO_APP_H_
#define EXT_PKG_FOO_APP_H_

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define FOO_APP_VERSION_MAJOR 1
#define FOO_APP_VERSION_MINOR 0
#define FOO_APP_VERSION_PATCH 0

/* Universal Status Codes */
typedef enum {
    FOO_APP_SUCCESS    =  0,
    FOO_APP_FINISHED   =  1,  
    FOO_APP_ERR_INVAL  = -1,
    FOO_APP_ERR_NOMEM  = -2,
    FOO_APP_ERR_IO     = -3
} foo_app_status_t;

/* Opaque context pointer */
typedef struct foo_app_ctx foo_app_ctx_t;

/* Core API */


#ifdef __cplusplus
}
#endif
#endif /* EXT_PKG_FOO_APP_H_ */
