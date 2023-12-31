//
//  HMDInfo+DeviceEnv.m
//  Pods
//
//  Created by Nickyo on 2023/10/7.
//

#import "HMDInfo+DeviceEnv.h"
#import "HeimdallrUtilities.h"
#if !EMBED
#include "HMDEnvCheck.h"
#endif /* EMBED */

@implementation HMDInfo (DeviceEnv)

- (BOOL)isEnvAbnormal {
#if !EMBED
    static BOOL hmd_is_jailBroken = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bool is_mac = [HeimdallrUtilities isiOSAppOnMac] ? true : false;
        hmd_is_jailBroken = !hmd_env_regular_check(is_mac);
        if (!hmd_is_jailBroken) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                hmd_is_jailBroken = !hmd_env_image_check();
            });
        }
    });
    
    return hmd_is_jailBroken;
#else
    return NO;
#endif /* EMBED */
}

@end
