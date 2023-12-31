//
//  vcn_time.h
//  network-1
//
//  Created by thq on 17/2/17.
//  Copyright © 2017年 thq. All rights reserved.
//

#ifndef vcn_time_h
#define vcn_time_h
#include <stdint.h>

/**
 * Get the current time in microseconds.
 */
__attribute__((visibility ("default"))) int64_t vcn_av_gettime(void);

/**
 * Get the current time in microseconds since some unspecified starting point.
 * On platforms that support it, the time comes from a monotonic clock
 * This property makes this time source ideal for measuring relative time.
 * The returned values may not be monotonic on platforms where a monotonic
 * clock is not available.
 */
__attribute__((visibility ("default"))) int64_t vcn_av_gettime_relative(void);
__attribute__((visibility ("default"))) int vcn_av_usleep(unsigned usec);
//end from avutil.h
#endif /* vcn_time_h */
