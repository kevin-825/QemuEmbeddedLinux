/*
 * Auto-generated UAPI header for m_LFD420_l5_producer
 * Author: Kevin
 * Date: 
 * Description: User-Space API (UAPI) contract for m_LFD420_l5_producer.
 */

#ifndef _UAPI_LINUX_M_LFD420_L5_PRODUCER_H_
#define _UAPI_LINUX_M_LFD420_L5_PRODUCER_H_

#include <linux/ioctl.h>
#include <linux/types.h>

/*
 * ============================================================================
 * C++ Compatibility Guard
 * ============================================================================
 * Remember how we removed this from the internal `core.h` file? 
 * We put it BACK in here! Because this is a UAPI header, a User-Space 
 * C++ application might actually #include this file. This guard safely 
 * prevents the C++ compiler from mangling the struct and macro names.
 */
#ifdef __cplusplus
extern "C" {
#endif

/*
 * ============================================================================
 * 1. Data Structures
 * ============================================================================
 * STRICT RULE: Only use __u8, __u16, __u32, __u64 types to ensure 
 * perfect struct sizing between 32-bit and 64-bit user-space applications.
 */

struct m_LFD420_l5_producer_config {
    __u32 sample_rate;
    __u32 active_channels;
};

struct m_LFD420_l5_producer_data {
    __u32 hardware_status;
    __s32 sensor_value;
};

/*
 * ============================================================================
 * 2. IOCTL Magic Number
 * ============================================================================
 * Defines a unique identifier for this specific hardware driver to 
 * prevent collisions with other Linux drivers.
 */
#define M_LFD420_L5_PRODUCER_IOC_MAGIC  'K'

/*
 * ============================================================================
 * 3. IOCTL Command Definitions
 * ============================================================================
 * _IO   : An action with no data transfer.
 * _IOW  : Write data from User-Space to Kernel-Space.
 * _IOR  : Read data from Kernel-Space to User-Space.
 * _IOWR : Read and Write data simultaneously.
 */

/* Command 0: Hardware Reset (No data passed) */
#define M_LFD420_L5_PRODUCER_IOC_RESET       _IO(M_LFD420_L5_PRODUCER_IOC_MAGIC, 0)

/* Command 1: Write a configuration struct TO the driver */
#define M_LFD420_L5_PRODUCER_IOC_SET_CONFIG  _IOW(M_LFD420_L5_PRODUCER_IOC_MAGIC, 1, struct m_LFD420_l5_producer_config)

/* Command 2: Read a data struct FROM the driver */
#define M_LFD420_L5_PRODUCER_IOC_GET_DATA    _IOR(M_LFD420_L5_PRODUCER_IOC_MAGIC, 2, struct m_LFD420_l5_producer_data)

/* Command 3: Send a simple 32-bit integer and get a status integer back */
#define M_LFD420_L5_PRODUCER_IOC_CALIBRATE   _IOWR(M_LFD420_L5_PRODUCER_IOC_MAGIC, 3, __u32)


#ifdef __cplusplus
}
#endif

#endif /* _UAPI_LINUX_M_LFD420_L5_PRODUCER_H_ */
