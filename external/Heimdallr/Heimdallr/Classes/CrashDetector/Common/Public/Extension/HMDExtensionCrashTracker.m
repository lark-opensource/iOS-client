//
//  HMDExtensionCrashTracker.m
//  HeimdallrForExtension
//
//  Created by xuminghao.eric on 2020/8/14.
//

#import "HMDExtensionCrashTracker.h"
#import "HMDCrashTracker.h"
#import "HMDCrashAppGroupURL.h"
#import "HMDCrashConfig.h"
#import "NSObject+HMDAttributes.h"

@implementation HMDExtensionCrashTracker

+ (instancetype)sharedTracker{
    static HMDExtensionCrashTracker *sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [[HMDExtensionCrashTracker alloc] init];
    });
    return sharedTracker;
}

- (void)startWithGroupID:(NSString *)groupID{
    NSAssert([NSThread isMainThread], @"Heimdallr must be initialized synchronously on the main thread, otherwise the date from  Crash may be missing or inaccurate.");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!groupID || [groupID length] == 0) {
            return;
        }
        [HMDInjectedInfo defaultInfo].appGroupID = groupID;
        
        [self updateConfig];
        
        [[HMDCrashTracker sharedTracker] start];
    });
}

- (void)updateConfig {
    NSDictionary *configDictionary = [NSDictionary dictionaryWithContentsOfFile:[HMDCrashAppGroupURL appGroupCrashSettingsURL].resourceSpecifier];
    if (configDictionary) {
        HMDCrashConfig *config = [HMDCrashConfig hmd_objectWithDictionary:configDictionary];
        [[HMDCrashTracker sharedTracker] updateConfig:config];
    }
}

@end
