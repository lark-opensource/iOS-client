//
//  hmd_debug.h
//
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

/* Utility functions for querying the mach kernel.
 */

#ifndef HDR_HMDDebug_h
#define HDR_HMDDebug_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>

/** Check if the current process is being traced or not.
 *
 * @return true if we're being traced.
 */
bool hmddebug_isBeingTraced(void);

#ifdef __cplusplus
}
#endif

#endif  // HDR_HMDDebug_h
