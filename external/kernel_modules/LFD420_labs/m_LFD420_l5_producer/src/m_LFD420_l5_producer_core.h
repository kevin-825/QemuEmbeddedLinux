/*
 * Auto-generated header for m_LFD420_l5_producer
 * Author: Kevin
 * Date: 
 * Description: Core API definitions for m_LFD420_l5_producer.
 */

#ifndef _EXT_KMOD_M_LFD420_L5_PRODUCER_CORE_H_
#define _EXT_KMOD_M_LFD420_L5_PRODUCER_CORE_H_

/*
 * ============================================================================
 * Internal Return Status Codes
 * ============================================================================
 */
enum m_LFD420_l5_producer_status {
    M_LFD420_L5_PRODUCER_SUCCESS     =  0,
    M_LFD420_L5_PRODUCER_ERR_BUSY    = -1,
    M_LFD420_L5_PRODUCER_ERR_MEM     = -2,
    M_LFD420_L5_PRODUCER_ERR_IO      = -3,
    M_LFD420_L5_PRODUCER_ERR_TIMEOUT = -4
};

/* Future internal core definitions and state structures go here */
int m_LFD420_l5_producer_generate_fabonaci(int n);

#endif /* _EXT_KMOD_M_LFD420_L5_PRODUCER_CORE_H_ */
