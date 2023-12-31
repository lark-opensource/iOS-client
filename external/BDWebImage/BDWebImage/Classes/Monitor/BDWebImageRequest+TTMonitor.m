//
//  BDWebImageRequest+TTMonitor.m
//  BDWebImage
//
//  Created by fengyadong on 2017/12/11.
//

#import "BDWebImageRequest.h"
//#import "BDWebImage.h"
#import "BDImagePerformanceRecoder.h"
#import "BDWebImageError.h"
#import "BDImageMonitorManager.h"
#import "BDWebImageManager.h"
#import "BDImageDecoderFactory.h"

@implementation BDWebImageRequest (TTMonitor)

- (void)ttMonitorRecordPerformance {
    //性能监控，上报
    [self setPerformanceBlock:^(BDImagePerformanceRecoder *recorder) {
        if (recorder.cacheType == BDImageCacheTypeNone && recorder.enableReport) {
            NSDictionary<NSString *, id> *_Nullable attributes = [recorder imageMonitorV2Log];
            
            [[[BDWebImageManager sharedManager] BDBaseManagerFromOption] setMonitorEvent:attributes recorder:recorder];
#ifdef DEBUG
            if (ENABLE_LOG) {
                NSLog(@"%@", recorder.description);
                NSLog(@"attributes = %@", attributes);
            }
#endif
        }
    }];
}

@end
