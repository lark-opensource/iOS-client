//
//  HMDLaunchTimingDefine.h
//  Pods
//
//  Created by zhangxiao on 2021/7/19.
//

#ifndef HMDLaunchTimingDefine_h
#define HMDLaunchTimingDefine_h

typedef NS_ENUM(NSUInteger, HMDAPPLaunchModel) {
    HMDAPPLaunchTypeNormal = 1,
    HMDAPPLaunchTypeAfterUpdate,
};

/// default task define
static NSString * const kHMDLaunchTimingDefaultCustomEndName = @"custom_end";
static NSString * const kHMDLaunchTimingDefaultSpanModule = @"base";
static NSString * const kHMDLaunchTimingSpanFromExecToLoad = @"exec_to_load";
static NSString * const kHMDLaunchTimingSpanFromLoadToFinishLaunch = @"load_to_finishlaunch";
static NSString * const kHMDLaunchTimingSpanFromFishLaunchToRender = @"finishlaunch_to_firstrender";

#endif /* HMDLaunchTimingDefine_h */
