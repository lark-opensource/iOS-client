//
//
//  Created by 谢俊逸 on 30/1/2018.
//

#import "AppStartTracker.h"
#import <objc/message.h>
#include <mach/mach_time.h>
#import "Heimdallr+Private.h"
#import "HMDStartDetectorConfig.h"
#import "HMDALogProtocol.h"
#import "HMDAppLaunchTool.h"
#import "UIApplication+HMDUtility.h"
#include <atomic>
#import "NSDictionary+HMDSafe.h"

CFTimeInterval hmd_load_timestamp;
NSDate *HMDMainDate = nil;
NSDate *HMDWillFinishLaunchingDate = nil;
NSDate *HMDWillFinishLaunchingAccurateDate = nil;
CFTimeInterval from_load_to_first_render_time;
CFTimeInterval from_didFinshedLaunching_to_first_render_time;
CFTimeInterval from_load_to_didFinshedLaunching_time;
static bool kHMDStartTrackerEnabled = false;
static const CFTimeInterval kPrewarmMainToWillFinishLaunchingThreshold = 1000;
static const CFTimeInterval kPrewarmExecToLoadThreshold = 10000; //prewarm 判定阈值

start_time_log_t *start_time_log = NULL;
void setAppStartTrackerEnabled(bool) {
    kHMDStartTrackerEnabled = true;
}

bool appStartTrackerEnabled(void) {
    NSDictionary *syncModules = [Heimdallr syncStartModuleSettings];
    if (syncModules) {
        return [syncModules.allKeys containsObject:NSStringFromClass([HMDStartDetectorConfig class])];
    }
    
    return kHMDStartTrackerEnabled;
}


HMDPrewarmSpan isPrewarm() {
    static std::atomic_int isPrewarmFlag(HMDPrewarmUnknown);
    if (isPrewarmFlag != HMDPrewarmUnknown) {
        return (HMDPrewarmSpan)isPrewarmFlag.load(std::memory_order_acquire);
    }
    
    if (hmd_load_timestamp <= 0) {
        return HMDPrewarmNone;
    }

    if (@available(iOS 15.0, *)) {
        long long execToLoadTimeInterval = hmd_load_timestamp*1000 - hmdTimeWithProcessExec();
        if (execToLoadTimeInterval > kPrewarmExecToLoadThreshold){
            isPrewarmFlag = HMDPrewarmExecToLoad;
            return HMDPrewarmExecToLoad;
        }
        
        if (!HMDWillFinishLaunchingDate || !HMDWillFinishLaunchingAccurateDate || !HMDMainDate) {
            return HMDPrewarmNone;
        }
        CFTimeInterval interval = [HMDWillFinishLaunchingDate timeIntervalSinceDate:HMDMainDate] * 1000;

        id activePrewarmVal = [[[NSProcessInfo processInfo] environment] objectForKey:@"ActivePrewarm"];
        // activePrewarmVal is NSTaggedPointerString
        if (activePrewarmVal && [activePrewarmVal respondsToSelector:@selector(boolValue)]) {
            if ([activePrewarmVal boolValue] == true) {
                if (execToLoadTimeInterval >= interval) {
                    isPrewarmFlag = HMDPrewarmExecToLoad;
                    return HMDPrewarmExecToLoad;
                } else {
                    isPrewarmFlag = HMDPrewarmLoadToDidFinishLaunching;
                    return HMDPrewarmLoadToDidFinishLaunching;
                }
            }
        }
        
        if (interval > kPrewarmMainToWillFinishLaunchingThreshold) {
            isPrewarmFlag = HMDPrewarmLoadToDidFinishLaunching;
            return HMDPrewarmLoadToDidFinishLaunching;
        }
    }
    return HMDPrewarmNone;
}

int isUIScene(){
    static std::atomic_int isUISceneFlag(-1);
    if(isUISceneFlag != -1){
        return isUISceneFlag;
    }
    isUISceneFlag = 0;
    if (@available(iOS 13.0, *)) {
        id info = [NSBundle.mainBundle objectForInfoDictionaryKey:@"UIApplicationSceneManifest"];
        NSDictionary *infoDict = ([info isKindOfClass:[NSDictionary class]]) ? info : nil;
        NSDictionary *config = [infoDict hmd_objectForKey:@"UISceneConfigurations" class:NSDictionary.class];
        if (config != nil) {
            isUISceneFlag = 1;
        }
    }
    return isUISceneFlag;
}

#pragma mark First Rendered Time
extern "C"
{
  
    void monitorAppStartTime() {
        if (hmd_load_timestamp <= 0) {
            return;
        }
        
        CFTimeInterval main_timestamp = [HMDMainDate timeIntervalSince1970];
        CFTimeInterval willFinishLaunching_timestamp = [HMDWillFinishLaunchingDate timeIntervalSince1970];
        CFTimeInterval didfinishLaunching_timestemp = [[NSDate date] timeIntervalSince1970];
        
        HMDPrewarmSpan isPrewarmFlag = isPrewarm();
        if (isPrewarmFlag == HMDPrewarmLoadToDidFinishLaunching) {
            from_load_to_didFinshedLaunching_time = didfinishLaunching_timestemp - willFinishLaunching_timestamp;
        }
        else {
            from_load_to_didFinshedLaunching_time = didfinishLaunching_timestemp - hmd_load_timestamp;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            CFTimeInterval hmd_first_render_time = [[NSDate date] timeIntervalSince1970];
            if (isPrewarmFlag == HMDPrewarmLoadToDidFinishLaunching) {
                from_load_to_first_render_time = hmd_first_render_time - willFinishLaunching_timestamp;
            }
            else {
                from_load_to_first_render_time = hmd_first_render_time - hmd_load_timestamp;
            }
            from_didFinshedLaunching_to_first_render_time = hmd_first_render_time - didfinishLaunching_timestemp;
            
            if (@available(iOS 13.0, *)) {
                UIApplicationState state = [UIApplication hmdSharedApplication].applicationState;
                BOOL isBackground = (state == UIApplicationStateBackground);
                if (isUIScene() && isBackground) {
                    return;
                }
            }
            
            if (hmd_log_enable()) {
                HMD_ALOG_PROTOCOL_INFO_TAG("Heimdallr", "HMDStart app start time info: isPrewarm:%d, load_timestamp:%f, main_timestamp:%f, willFinishLaunching: %f, didFinishLaunching_timestamp: %f, first_render:%f,from_load_to_first_render:%f,  from_load_to_didFinshedLaunching_time:%f, from_didFinshedLaunching_to_first_render_time: %f", (isPrewarmFlag != HMDPrewarmNone), hmd_load_timestamp, main_timestamp, willFinishLaunching_timestamp, didfinishLaunching_timestemp, hmd_first_render_time,from_load_to_first_render_time, from_load_to_didFinshedLaunching_time, from_didFinshedLaunching_to_first_render_time);
            }

            if (start_time_log){
                start_time_log(from_load_to_first_render_time, from_didFinshedLaunching_to_first_render_time, from_load_to_didFinshedLaunching_time, hmd_load_timestamp, (isPrewarmFlag != HMDPrewarmNone), NULL, NULL);
            }
        });

    }
}

#pragma mark OC Load Time

@implementation HMDLoadTracker

+ (void)load {
    hmd_load_timestamp = [[NSDate date] timeIntervalSince1970];
}

@end
