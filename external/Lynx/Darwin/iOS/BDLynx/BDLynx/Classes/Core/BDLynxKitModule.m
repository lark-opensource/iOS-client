//
//  BDLynxKitModule.m
//  BDLynx
//
//  Created by bill on 2020/2/4.
//
#import "BDLynxKitModule.h"
#import "BDLGurdModuleProtocol.h"
#import "BDLSDKManager.h"
#import "BDLynxKitModule.h"

#import <objc/runtime.h>

@interface BDLynxKitPostLaunchTask : NSObject

@end

@implementation BDLynxKitPostLaunchTask

+ (void)execute {
  if ([BDL_SERVICE(BDLGurdModuleProtocol) enableGurd]) {
    [BDL_SERVICE(BDLGurdModuleProtocol) syncResourcesIfNeeded];
  }
}

@end

@interface BDLynxKitModule ()

@end

@implementation BDLynxKitModule

+ (void)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [BDLynxKitPostLaunchTask execute];
}

#if AWEGurdRNEnable

- (void)dealloc {
}

#pragma mark - AWEAppBytedSettingMessage

- (void)bytedSettingDidChange {
  [BDLynxGurdModule bytedSettingDidChange];
}

#endif

@end
