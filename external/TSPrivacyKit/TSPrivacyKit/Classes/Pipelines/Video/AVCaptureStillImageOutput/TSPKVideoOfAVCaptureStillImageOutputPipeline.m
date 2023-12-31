//
//  TSPKVideoOfAVCaptureStillImageOutputPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKVideoOfAVCaptureStillImageOutputPipeline.h"
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"
#import <AVFoundation/AVCaptureStillImageOutput.h>

@implementation AVCaptureStillImageOutput (TSPrivacyKitVideo)

+ (void)tspk_video_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKVideoOfAVCaptureStillImageOutputPipeline class] clazz:self];
}

- (void)tspk_video_captureStillImageAsynchronouslyFromConnection:(AVCaptureConnection *)connection completionHandler:(void (^)(CMSampleBufferRef _Nullable imageDataSampleBuffer, NSError * _Nullable error))handler {
    TSPKHandleResult *result = [TSPKVideoOfAVCaptureStillImageOutputPipeline handleAPIAccess:NSStringFromSelector(@selector(captureStillImageAsynchronouslyFromConnection:completionHandler:)) className:[TSPKVideoOfAVCaptureStillImageOutputPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (handler) {
            handler(nil, [TSPKUtils fuseError]);
        }
    } else {
        [self tspk_video_captureStillImageAsynchronouslyFromConnection:connection completionHandler:handler];
    }
    
}
@end
#endif

@implementation TSPKVideoOfAVCaptureStillImageOutputPipeline

+ (NSString *)pipelineType {
    return TSPKPipelineVideoOfAVCaptureStillImageOutput;
}

+ (NSString *)dataType {
    return TSPKDataTypeVideo;
}

+ (NSString *)stubbedClass
{
    return @"AVCaptureStillImageOutput";
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
    return @[
        NSStringFromSelector(@selector(captureStillImageAsynchronouslyFromConnection:completionHandler:))
    ];
#else
    return [NSArray array];
#endif
}

+ (void)preload {
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AVCaptureStillImageOutput tspk_video_preload];
    });
#endif
}

@end
