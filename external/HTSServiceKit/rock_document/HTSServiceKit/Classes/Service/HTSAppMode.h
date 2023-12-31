//
//  HTSAppContext.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTSServiceForMode.h"
#import "HTSLifeCycleForMode.h"

#define HTSAppDefaultMode NULL

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HTSAppModeServicePolicy) {
    HTSAppModeServiceExclusive, //Only search imp in current mode
    HTSAppModeServiceDowngradeToDefault //If imp is not found in current mode, try to search default mode
};

/// Setup provider in info.plist with Key：HTSAppModeProvider
@protocol HTSAppModeProvider <NSObject>

/*
 当前的模式，模式决定了执行哪些LifeCycle，mode和传入HTS_APP_LIFECYCLE_MODE宏的参数保持一致
 默认模式请返回HTSAppDefaultMode
 */
+ (const char *)bootMode;

@optional

+ (HTSAppModeServicePolicy)policyForService;

@end

NS_ASSUME_NONNULL_END

FOUNDATION_EXPORT BOOL HTSIsDefaultBootMode();
FOUNDATION_EXPORT const char * HTSSegmentNameForCurrentMode();
FOUNDATION_EXPORT HTSAppModeServicePolicy HTSGetCurrentModeServicePolicy();
