//
//  HMDInjectedInfo+StabilityTest.m
//  Pods
//
//  Created by shenxy on 2022/7/22.
//

#import "HMDInjectedInfo+StabilityTest.h"
#import <objc/runtime.h>
#import "HMDSwizzle.h"
#import "HMDInfo+AppInfo.h"
#import "NSDictionary+HMDSafe.h"

@interface HMDInjectedInfo (mock)

@property(nonatomic, readonly) NSString *mock_appID;

@end

@implementation HMDInjectedInfo (StabilityTest)

+ (void)load {
    NSString *appID = [NSBundle.mainBundle objectForInfoDictionaryKey:@"StabilityTestAppID"];
    if([appID isKindOfClass:NSString.class]) return;
    
    id info = [NSBundle.mainBundle objectForInfoDictionaryKey:@"AutomationTestInfo"];
    NSDictionary *infoDict = ([info isKindOfClass:NSDictionary.class]) ? info : nil;
    NSString *taskID = [infoDict hmd_objectForKey:@"task_id" class:NSString.class];
    
    if(taskID) {
        [HMDInjectedInfo.defaultInfo setCustomFilterValue:taskID  forKey:@"taskID"];
        [HMDInjectedInfo.defaultInfo setCustomContextValue:taskID forKey:@"taskID"];
    }
    
    [HMDInjectedInfo.defaultInfo  setCustomFilterValue:kHeimdallrPodVersion forKey:@"HeimdallrVersion"];
    [HMDInjectedInfo.defaultInfo setCustomContextValue:kHeimdallrPodVersion forKey:@"HeimdallrVersion"];
    
    hmd_swizzle_instance_method_with_block(HMDInjectedInfo.class, @selector(appID), @selector(mock_appID), ^ NSString *(HMDInjectedInfo *info){
        NSString *appID = [NSBundle.mainBundle objectForInfoDictionaryKey:@"StabilityTestAppID"];
        if(appID != nil) return appID;
        return info.mock_appID;
    });
}

@end
