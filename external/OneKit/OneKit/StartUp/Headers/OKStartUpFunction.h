//
//  OKStartUpGaia.h
//  OKStartUp
//
//  Created by bob on 2020/1/14.
//

#import <OneKit/OKSectionFunction.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef OKStartUpFunction_h
#define OKStartUpFunction_h

#define OKSwiftFunctionNamespace "OneKit"

#define OKAppLoadService "OKAppLoadService"
#define OKAppLoadServiceFunction OK_FUNCTION_EXPORT(OKAppLoadService)

/// Application Info配置
#define OKAppInfoConfigKey "OKAppInfoConfigKey"
#define OKAppInfoConfigFunction OK_FUNCTION_EXPORT(OKAppInfoConfigKey)

#define OKAppTaskConfigKey "OKAppTaskConfigKey"
#define OKAppTaskConfigFunction OK_FUNCTION_EXPORT(OKAppTaskConfigKey)

#define OKAppTaskAddKey "OKAppTaskAddKey"
#define OKAppTaskAddFunction OK_FUNCTION_EXPORT(OKAppTaskAddKey)

#endif

/**
 OC使用示例：
 
OKAppInfoConfigFunction (void) {
 OKApplicationInfo *info = [OKApplicationInfo sharedInstance];
 info.xxx = xxx;
 
}

OKAppTaskConfigFunction(void) {
     [XXXStartUpTask sharedInstance].xxx = xxx;
}
 
OKAppTaskAddFunction (void) {
 OKReachabilityTask *task = xxx
 [task scheduleTask];
}

 */

NS_ASSUME_NONNULL_END
