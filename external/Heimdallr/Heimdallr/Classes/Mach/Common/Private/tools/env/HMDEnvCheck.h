//
//  HMDEnvCheck.h
//  AFgzipRequestSerializer-iOS13.0
//
//  Created by yuanzhangjing on 2020/2/6.
//

#ifndef HMDEnvCheck_h
#define HMDEnvCheck_h

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

    bool hmd_env_regular_check(bool is_mac);

    bool hmd_env_image_check(void); //比较耗时

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDEnvCheck_h */
