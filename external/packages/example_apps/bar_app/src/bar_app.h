/*
 * Auto-generated header for bar_app
 */
#ifndef EXT_PKG_BAR_APP_H_
#define EXT_PKG_BAR_APP_H_

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define BAR_APP_VERSION_MAJOR 1
#define BAR_APP_VERSION_MINOR 0
#define BAR_APP_VERSION_PATCH 0

/* Universal Status Codes */
typedef enum {
    BAR_APP_SUCCESS    =  0,
    BAR_APP_FINISHED   =  1,  
    BAR_APP_ERR_INVAL  = -1,
    BAR_APP_ERR_NOMEM  = -2,
    BAR_APP_ERR_IO     = -3
} bar_app_status_t;

/* Opaque context pointer */
typedef struct bar_app_ctx bar_app_ctx_t;

/* Core API */


#ifdef __cplusplus
}
#endif
#endif /* EXT_PKG_BAR_APP_H_ */
