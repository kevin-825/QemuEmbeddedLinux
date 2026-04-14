/*
 * Auto-generated header for LFD401_lab1_lib
 */
#ifndef EXT_PKG_LFD401_LAB1_LIB_H_
#define EXT_PKG_LFD401_LAB1_LIB_H_

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define LFD401_LAB1_LIB_VERSION_MAJOR 1
#define LFD401_LAB1_LIB_VERSION_MINOR 0
#define LFD401_LAB1_LIB_VERSION_PATCH 0

/* Universal Status Codes */
typedef enum {
    LFD401_LAB1_LIB_SUCCESS    =  0,
    LFD401_LAB1_LIB_FINISHED   =  1,  
    LFD401_LAB1_LIB_ERR_INVAL  = -1,
    LFD401_LAB1_LIB_ERR_NOMEM  = -2,
    LFD401_LAB1_LIB_ERR_IO     = -3
} LFD401_lab1_lib_status_t;

/* Opaque context pointer */
typedef struct LFD401_lab1_lib_ctx LFD401_lab1_lib_ctx_t;

/* Core API */


#ifdef __cplusplus
}
#endif
#endif /* EXT_PKG_LFD401_LAB1_LIB_H_ */
