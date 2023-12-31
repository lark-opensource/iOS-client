//
//  TSPKAVCaptureDevice.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/12.
//

#import "TSPKAudioOfAVCaptureDevicePipeline.h"
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
#import <AVFoundation/AVCaptureDevice.h>
#import "NSObject+TSAddition.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation AVCaptureDevice (TSPrivacyKitAudio)

+ (void)tspk_audio_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKAudioOfAVCaptureDevicePipeline class] clazz:self];
}

+ (void)tspk_audio_requestAccessForMediaType:(AVMediaType)mediaType completionHandler:(void (^)(BOOL))handler
{
    
    if (mediaType == AVMediaTypeAudio) {
        NSDictionary *params = @{
            TSPKAPISubTypeKey : TSPKDataTypeAudio
        };
        TSPKHandleResult *result = [TSPKAudioOfAVCaptureDevicePipeline handleAPIAccess:NSStringFromSelector(@selector(requestAccessForMediaType:completionHandler:)) className:[TSPKAudioOfAVCaptureDevicePipeline stubbedClass] params:params];
        if (result.action == TSPKResultActionFuse) {
            if (handler) {
                handler(NO);
            }
        } else {
            [self tspk_audio_requestAccessForMediaType:mediaType completionHandler:handler];
        }
    } else {
        [self tspk_audio_requestAccessForMediaType:mediaType completionHandler:handler];
    }
}

+ (AVCaptureDevice *)tspk_audio_defaultDeviceWithMediaType:(AVMediaType)mediaType {
    if (mediaType == AVMediaTypeAudio) {
        NSDictionary *params = @{
            TSPKAPISubTypeKey : TSPKDataTypeAudio
        };
        TSPKHandleResult *result = [TSPKAudioOfAVCaptureDevicePipeline handleAPIAccess:NSStringFromSelector(@selector(defaultDeviceWithMediaType:)) className:[TSPKAudioOfAVCaptureDevicePipeline stubbedClass] params:params];
        if (result.action == TSPKResultActionFuse) {
            return [result getObjectWithReturnType:@"AVCaptureDevice" defaultValue:nil];
        } else {
            return [self tspk_audio_defaultDeviceWithMediaType:mediaType];
        }
    } else {
        return [self tspk_audio_defaultDeviceWithMediaType:mediaType];
    }
}

+ (AVCaptureDevice *)tspk_audio_defaultDeviceWithDeviceType:(AVCaptureDeviceType)deviceType mediaType:(AVMediaType)mediaType position:(AVCaptureDevicePosition)position  API_AVAILABLE(ios(10.0)){
    if (mediaType == AVMediaTypeAudio) {
        NSDictionary *params = @{
            TSPKAPISubTypeKey : TSPKDataTypeAudio
        };
        TSPKHandleResult *result = [TSPKAudioOfAVCaptureDevicePipeline handleAPIAccess:NSStringFromSelector(@selector(defaultDeviceWithDeviceType:mediaType:position:)) className:[TSPKAudioOfAVCaptureDevicePipeline stubbedClass] params:params];
        if (result.action == TSPKResultActionFuse) {
            return [result getObjectWithReturnType:@"AVCaptureDevice" defaultValue:nil];
        } else {
            return [self tspk_audio_defaultDeviceWithDeviceType:deviceType mediaType:mediaType position:position];
        }
    } else {
        return [self tspk_audio_defaultDeviceWithDeviceType:deviceType mediaType:mediaType position:position];
    }
}

@end
#endif

@implementation TSPKAudioOfAVCaptureDevicePipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAudioOfAVCaptureDevice;
}

+ (NSString *)dataType {
    return TSPKDataTypeAudio;
}

+ (NSString *)stubbedClass
{
  return @"AVCaptureDevice";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
    NSArray *methods = @[
        NSStringFromSelector(@selector(requestAccessForMediaType:completionHandler:)),
        NSStringFromSelector(@selector(defaultDeviceWithMediaType:))
    ];
    NSMutableArray *methodsWithLevel = [methods mutableCopy];
    if (@available(iOS 10.0, *)) {
        [methodsWithLevel addObject:NSStringFromSelector(@selector(defaultDeviceWithDeviceType:mediaType:position:))];
    }
    return [methodsWithLevel copy];
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
        [AVCaptureDevice tspk_audio_preload];
    });
#endif
}

@end
