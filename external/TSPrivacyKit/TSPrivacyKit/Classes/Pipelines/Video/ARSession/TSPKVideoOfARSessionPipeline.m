//
//  TSPKVideoOfARSessionPipeline.m
//  Musically
//
//  Created by ByteDance on 2022/11/14.
//

#import "TSPKVideoOfARSessionPipeline.h"
#import "NSObject+TSAddition.h"
#import "TSPrivacyKitConstants.h"
#import <ARKit/ARKit.h>
#import <TSPrivacyKit/TSPKSignalManager+public.h>

@implementation ARSession (TSPrivacyKitVideo)

+ (void)tspk_video_preload {
    [self ts_swizzleInstanceMethod:@selector(init) with:@selector(tspk_init)];
}

- (instancetype)tspk_init {
    // only used to save signal currently
    [TSPKSignalManager addSignalWithType:TSPKSignalTypeCustom permissionType:[TSPKVideoOfARSessionPipeline dataType] content:@"ARSession init"];
    return [self tspk_init];
}

@end

@implementation TSPKVideoOfARSessionPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineVideoOfARSession;
}

+ (NSString *)dataType {
    return TSPKDataTypeVideo;
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 11.0, *)) {
            [ARSession tspk_video_preload];
        } else {
            // Fallback on earlier versions
        }
    });
}


@end
