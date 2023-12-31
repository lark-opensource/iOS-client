//
//  TSPKAudioOfAVAudioSessionPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/12.
//

#import "TSPKAudioOfAVAudioSessionPipeline.h"
#import <AVFAudio/AVAudioSession.h>
#import "NSObject+TSAddition.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation AVAudioSession (TSPrivacyKitAudio)

+ (void)tspk_audio_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKAudioOfAVAudioSessionPipeline class] clazz:self];
}

- (void)tspk_audio_requestRecordPermission:(void (^)(BOOL))response
{
    TSPKHandleResult *result = [TSPKAudioOfAVAudioSessionPipeline handleAPIAccess:NSStringFromSelector(@selector(requestRecordPermission:)) className:[TSPKAudioOfAVAudioSessionPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (response) {
            response(NO);
        }
    } else {
        [self tspk_audio_requestRecordPermission:response];
    }
}

@end

@implementation TSPKAudioOfAVAudioSessionPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAudioOfAVAudioSession;
}

+ (NSString *)dataType {
    return TSPKDataTypeAudio;
}

+ (NSString *)stubbedClass
{
  return @"AVAudioSession";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(requestRecordPermission:))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AVAudioSession tspk_audio_preload];
    });
}

@end
