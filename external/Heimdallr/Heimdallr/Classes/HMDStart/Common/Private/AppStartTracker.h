//
//
//  Created by 谢俊逸 on 30/1/2018.
//

#import <Foundation/Foundation.h>

extern CFTimeInterval hmd_load_timestamp;
extern NSDate *HMDMainDate;
extern NSDate *HMDWillFinishLaunchingDate;
extern NSDate *HMDWillFinishLaunchingAccurateDate;

extern NSMutableArray *objc_load_infos;
extern NSTimeInterval app_load_to_didFinshLaunch_time;
extern NSMutableArray *cpp_init_infos;

// first_render_time ≈ viewDidAppear:
extern CFTimeInterval from_load_to_first_render_time;


extern CFTimeInterval from_didFinshedLaunching_to_first_render_time;
extern CFTimeInterval from_load_to_didFinshedLaunching_time;

typedef void(start_time_log_t)(CFTimeInterval from_load_to_first_render_time,
                               CFTimeInterval from_didFinshedLaunching_to_first_render_time,
                               CFTimeInterval from_load_to_didFinshedLaunching_time,
                               CFTimeInterval hmd_load_timestamp,
                               bool prewarm,
                               NSMutableArray *objc_load_infos,
                               NSMutableArray *cpp_init_infos
                               );
extern start_time_log_t *start_time_log;

typedef NS_ENUM(NSInteger, HMDPrewarmSpan) {
    HMDPrewarmUnknown,
    HMDPrewarmNone,
    HMDPrewarmExecToLoad,
    HMDPrewarmLoadToDidFinishLaunching
};

#ifdef __cplusplus
extern "C" {
#endif
    bool appStartTrackerEnabled(void);
    void setAppStartTrackerEnabled(bool);
    HMDPrewarmSpan isPrewarm(void);
    int isUIScene(void);
#ifdef __cplusplus
}
#endif

@interface HMDLoadTracker : NSObject

@end
