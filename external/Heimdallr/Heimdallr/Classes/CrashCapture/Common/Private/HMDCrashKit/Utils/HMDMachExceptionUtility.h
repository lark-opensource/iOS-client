//
//  HMDMachExceptionUtility.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/7/11.
//

#ifndef HMDMachExceptionUtility_h
#define HMDMachExceptionUtility_h

#include <stdio.h>
#include <mach/exception_types.h>
#include <mach/mach_types.h>

#ifdef __cplusplus
extern "C" {
#endif
    typedef struct
    {
        exception_mask_t        masks[EXC_TYPES_COUNT];
        exception_handler_t     ports[EXC_TYPES_COUNT];
        exception_behavior_t    behaviors[EXC_TYPES_COUNT];
        thread_state_flavor_t   flavors[EXC_TYPES_COUNT];
        mach_msg_type_number_t  count;
    } hmd_exception_ports;

    /*检测port是否正在监听此种异常类型，检测失败返回-1，正在监听返回1，没有监听返回0*/
    int hmdcrash_check_port_safe(mach_port_t port,exception_type_t type);
    
#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDMachExceptionUtility_h */
