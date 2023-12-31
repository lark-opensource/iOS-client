//
//  HMDMachExceptionUtility.c
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/7/11.
//

#include "HMDMachExceptionUtility.h"
#include <mach/task.h>
#include <mach/mach_init.h>

int hmdcrash_check_port_safe(mach_port_t port,exception_type_t type)
{
    if (port == MACH_PORT_NULL) {
        return 0;
    }
    const task_t this_task = mach_task_self();
    exception_mask_t        masks[EXC_TYPES_COUNT];
    exception_handler_t     ports[EXC_TYPES_COUNT];
    exception_behavior_t    behaviors[EXC_TYPES_COUNT];
    thread_state_flavor_t   flavors[EXC_TYPES_COUNT];
    mach_msg_type_number_t  count = EXC_TYPES_COUNT;
    kern_return_t kr = task_get_exception_ports(this_task,
                                                1<<type,
                                                masks,
                                                &count,
                                                ports,
                                                behaviors,
                                                flavors);
    if (kr == KERN_SUCCESS) {
        for (int i = 0; i < count; i++) {
            if (ports[i] == port) {
                return 1;
            }
        }
        return 0;
    }
    return -1;
}
