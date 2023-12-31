//
//  BDBaseInternal.m
//  BDWebImage
//
//  Created by wby on 2021/2/18.
//

#import "BDBaseInternal.h"
#import "BDImageMonitorManager.h"
#import "BDImageManagerConfig.h"

@implementation BDBaseInternal 

- (void)setMonitorEvent:(nonnull NSDictionary *)attributes recorder:(nonnull BDImagePerformanceRecoder *)recorder {
    [BDImageMonitorManager trackData:attributes logTypeStr:@"image_monitor_v2"];
        
    if (recorder.error) {
        [BDImageMonitorManager trackData:[attributes copy] logTypeStr:@"image_monitor_error_v2"];
    }
}

- (BOOL)isSupportSuperResolution {
    return YES;
}

- (void)startUpWithConfig:(nonnull BDWebImageStartUpConfig *)config
{
    [BDImageManagerConfig sharedInstance].startUpConfig = config;
    [[BDImageManagerConfig sharedInstance] startFetchConfig];
}

- (nonnull NSString *)adaptiveDecodePolicy {
    // 判断自适应规则
    NSArray<NSString *> *staticAdpativePolicies = [BDImageManagerConfig sharedInstance].staticAdpativePolicies;
    if (staticAdpativePolicies.count == 0) return @"image/*";

    for (NSString *policy in staticAdpativePolicies) {
#if __has_include("BDImageDecoderHeic.h")
        if ([[policy lowercaseString] isEqual: @"heic"]) return @"image/heic";
#endif
#if __has_include("BDImageDecoderAVIF.h")
        if ([[policy lowercaseString] isEqual: @"avif"]) return @"image/avif";
#endif
#if __has_include("BDImageDecoderWebP.h")
        if ([[policy lowercaseString] isEqual: @"webp"]) return @"image/webp";
#endif
    }

    return @"image/*";
}

@end
