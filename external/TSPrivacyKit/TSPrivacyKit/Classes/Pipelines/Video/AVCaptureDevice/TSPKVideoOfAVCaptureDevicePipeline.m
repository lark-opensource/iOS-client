//
//  TSPKVideoOfAVCaptureDevicePipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKVideoOfAVCaptureDevicePipeline.h"

#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
#import <AVFoundation/AVCaptureDevice.h>
#import "NSObject+TSAddition.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation AVCaptureDevice (TSPrivacyKitVideo)

+ (void)tspk_video_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKVideoOfAVCaptureDevicePipeline class] clazz:self];
}

+ (void)tspk_video_requestAccessForMediaType:(AVMediaType)mediaType completionHandler:(void (^)(BOOL))handler
{
    if (mediaType == AVMediaTypeVideo) {
        NSDictionary *params = @{
            TSPKAPISubTypeKey : TSPKDataTypeVideo
        };
        TSPKHandleResult *result = [TSPKVideoOfAVCaptureDevicePipeline handleAPIAccess:NSStringFromSelector(@selector(requestAccessForMediaType:completionHandler:)) className:[TSPKVideoOfAVCaptureDevicePipeline stubbedClass] params:params];
        if (result.action == TSPKResultActionFuse) {
            if (handler) {
                handler(NO);
            }
        } else {
            [self tspk_video_requestAccessForMediaType:mediaType completionHandler:handler];
        }
    } else {
        [self tspk_video_requestAccessForMediaType:mediaType completionHandler:handler];
    }
}

+ (AVCaptureDevice *)tspk_video_defaultDeviceWithMediaType:(AVMediaType)mediaType {
    if (mediaType == AVMediaTypeVideo) {
        NSDictionary *params = @{
            TSPKAPISubTypeKey : TSPKDataTypeVideo
        };
        TSPKHandleResult *result = [TSPKVideoOfAVCaptureDevicePipeline handleAPIAccess:NSStringFromSelector(@selector(defaultDeviceWithMediaType:)) className:[TSPKVideoOfAVCaptureDevicePipeline stubbedClass] params:params];
        if (result.action == TSPKResultActionFuse) {
            return nil;
        } else {
            return [self tspk_video_defaultDeviceWithMediaType:mediaType];
        }
    }  else {
        return [self tspk_video_defaultDeviceWithMediaType:mediaType];
    }
}

+ (AVCaptureDevice *)tspk_video_defaultDeviceWithDeviceType:(AVCaptureDeviceType)deviceType mediaType:(AVMediaType)mediaType position:(AVCaptureDevicePosition)position  API_AVAILABLE(ios(10.0)){
    if (mediaType == AVMediaTypeVideo) {
        NSDictionary *params = @{
            TSPKAPISubTypeKey : TSPKDataTypeVideo
        };
        TSPKHandleResult *result = [TSPKVideoOfAVCaptureDevicePipeline handleAPIAccess:NSStringFromSelector(@selector(defaultDeviceWithDeviceType:mediaType:position:)) className:[TSPKVideoOfAVCaptureDevicePipeline stubbedClass] params:params];
        if (result.action == TSPKResultActionFuse) {
            return nil;
        } else {
            return [self tspk_video_defaultDeviceWithDeviceType:deviceType mediaType:mediaType position:position];
        }
    } else {
        return [self tspk_video_defaultDeviceWithDeviceType:deviceType mediaType:mediaType position:position];
    }
}

@end

#endif

@implementation TSPKVideoOfAVCaptureDevicePipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineVideoOfAVCaptureDevice;
}

+ (NSString *)dataType {
    return TSPKDataTypeVideo;
}

+ (NSString *)stubbedClass
{
    return @"AVCaptureDevice";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
    NSMutableArray<NSString *> *methods = [@[
        NSStringFromSelector(@selector(requestAccessForMediaType:completionHandler:)),
        NSStringFromSelector(@selector(defaultDeviceWithMediaType:)),
    ] mutableCopy];
    if (@available(iOS 10.0, *)) {
        [methods addObject:NSStringFromSelector(@selector(defaultDeviceWithDeviceType:mediaType:position:))];
    }
    return [methods copy];
#else
    return [NSArray array];
#endif
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return nil;
}

+ (void)preload
{
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AVCaptureDevice tspk_video_preload];
    });
#endif
}

@end
