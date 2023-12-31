//
//  HMDStartDetector.h
//  Heimdallr
//
//  Created by 谢俊逸 on 22/2/2018.
//

#import <Foundation/Foundation.h>
#import "HeimdallrModule.h"

#ifdef __cplusplus
extern "C" {
#endif
    void setAppStartTrackerEnabled(bool);
#ifdef __cplusplus
}
#endif

@class HMDStartRecord;

@interface HMDStartDetector : HeimdallrModule

+ (void)markMainDate;
+ (void)markWillFinishingLaunchDate;

+ (instancetype _Nullable)share;
- (NSTimeInterval)didFnishConcurrentRendering;

@property (nonatomic, strong, readonly, nullable) NSArray<HMDStartRecord*>*records;


@end
