//
//  HMDCrashKit+private.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/23.
//

#import "HMDCrashKit+Internal.h"
#import "HMDCrashDirectory+Private.h"

@implementation HMDCrashKit (Internal)
#if !SIMPLIFYEXTENSION
@dynamic networkProvider;
#endif
@dynamic commitID;
@dynamic sdkVersion;
@dynamic needEncrypt;
@dynamic launchCrashThreshold;
@dynamic lastTimeCrash;
@dynamic workQueue;

@end
