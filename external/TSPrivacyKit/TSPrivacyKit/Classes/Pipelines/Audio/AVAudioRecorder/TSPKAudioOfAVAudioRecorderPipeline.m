//
//  TSPKAudioOfAVAudioRecorderPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/12.
//

#import "TSPKAudioOfAVAudioRecorderPipeline.h"
#import <AVFAudio/AVAudioRecorder.h>
#import "NSObject+TSAddition.h"
#import "NSObject+TSDeallocAssociate.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation AVAudioRecorder (TSPrivacyKit)

+ (void)tspk_audio_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKAudioOfAVAudioRecorderPipeline class] clazz:self];
}

- (BOOL)tspk_audio_record {
    NSString *hashTag = [self ts_hashTag];
    NSString *method = @"record";
    
    [TSPKAudioOfAVAudioRecorderPipeline forwardCallInfoWithMethod:method className:[TSPKAudioOfAVAudioRecorderPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStart hashTag:hashTag beforeOrAfter:YES];
    TSPKHandleResult *result = [AVAudioRecorder forwardMethodEventToChannelWithMethodName:method
                                                                             apiUsageType:TSPKAPIUsageTypeStart
                                                                                 instance:self
                                                                                  hashTag:hashTag
                                                                            isNonsenstive:NO];
    if (result.action == TSPKResultActionFuse) {
        [TSPKAudioOfAVAudioRecorderPipeline forwardCallInfoWithMethod:method className:[TSPKAudioOfAVAudioRecorderPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStart hashTag:hashTag beforeOrAfter:NO];
        return NO;
    }
    
    BOOL success = [self tspk_audio_record];
    
    [TSPKAudioOfAVAudioRecorderPipeline forwardCallInfoWithMethod:method className:[TSPKAudioOfAVAudioRecorderPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStart hashTag:hashTag beforeOrAfter:NO];
    
    if (success) {
        [self tspk_addDeallocAction];
    }
    return success;
}

- (void)tspk_audio_pause {
    NSString *hashTag = [self ts_hashTag];
    NSString *method = @"pause";
    
    [AVAudioRecorder forwardMethodEventToChannelWithMethodName:method
                                                  apiUsageType:TSPKAPIUsageTypeStop
                                                      instance:self
                                                       hashTag:[self ts_hashTag]
                                                 isNonsenstive:YES];
    [TSPKAudioOfAVAudioRecorderPipeline forwardCallInfoWithMethod:method className:[TSPKAudioOfAVAudioRecorderPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStop hashTag:hashTag beforeOrAfter:YES];
    [self tspk_audio_pause];
    [TSPKAudioOfAVAudioRecorderPipeline forwardCallInfoWithMethod:method className:[TSPKAudioOfAVAudioRecorderPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStop hashTag:hashTag beforeOrAfter:NO];
}

- (void)tspk_audio_stop {
    NSString *hashTag = [self ts_hashTag];
    NSString *method = @"stop";
    [AVAudioRecorder forwardMethodEventToChannelWithMethodName:method
                                                  apiUsageType:TSPKAPIUsageTypeStop
                                                      instance:self
                                                       hashTag:[self ts_hashTag]
                                                 isNonsenstive:YES];
    [TSPKAudioOfAVAudioRecorderPipeline forwardCallInfoWithMethod:method className:[TSPKAudioOfAVAudioRecorderPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStop hashTag:hashTag beforeOrAfter:YES];
    [self tspk_audio_stop];
    [TSPKAudioOfAVAudioRecorderPipeline forwardCallInfoWithMethod:method className:[TSPKAudioOfAVAudioRecorderPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStop hashTag:hashTag beforeOrAfter:NO];
}

- (void)tspk_addDeallocAction {
    NSString *hashTag = [self ts_hashTag];
    [self ts_addDeallocAction:^{
        [AVAudioRecorder forwardMethodEventToChannelWithMethodName:@"AVAudioRecorder_dealloc"
                                                      apiUsageType:TSPKAPIUsageTypeDealloc
                                                          instance:nil
                                                           hashTag:hashTag
                                                     isNonsenstive:YES];
    } withKey:@"AudioRecorder"];
}

+ (TSPKHandleResult *)forwardMethodEventToChannelWithMethodName:(NSString *)method
                                                   apiUsageType:(TSPKAPIUsageType)apiUsageType
                                                       instance:(NSObject *)instance
                                                        hashTag:(NSString *)hashTag
                                                  isNonsenstive:(BOOL)isNonsenstive {
    return [TSPKAudioOfAVAudioRecorderPipeline handleAPIAccess:method className:[TSPKAudioOfAVAudioRecorderPipeline stubbedClass] params:nil customHandleBlock:^(TSPKAPIModel * _Nonnull apiModel) {
        apiModel.apiUsageType = apiUsageType;
        apiModel.instance = instance;
        apiModel.hashTag = hashTag;
        apiModel.isNonsenstive = isNonsenstive;
        
        apiModel.customReleaseCheckBlock = ^TSPKCheckResult(NSObject * _Nonnull obj) {
            if (![obj isKindOfClass:[AVAudioRecorder class]]) {
                [TSPKUtils assert:false message:@"object type is unexpect"];
                return TSPKCheckResultError;
            }
            
            AVAudioRecorder *recorder = (AVAudioRecorder *)obj;
            return [recorder isRecording] ? TSPKCheckResultUnrelease : TSPKCheckResultRelease;
        };
        
        if (apiUsageType == TSPKAPIUsageTypeStart) {
            __weak NSObject *weakInstance = instance;
            apiModel.downgradeAction = ^{
                if (![weakInstance isKindOfClass:[AVAudioRecorder class]]) {
                    return;
                }
                AVAudioRecorder *strongInstance = (AVAudioRecorder *)weakInstance;
                [strongInstance tspk_audio_stop];
            };
        }
    }];
}

@end

@implementation TSPKAudioOfAVAudioRecorderPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAudioOfAVAudioRecorder;
}

+ (TSPKStoreType)storeType
{
    return TSPKStoreTypeRelationObjectCache;
}

+ (NSString *)dataType {
    return TSPKDataTypeAudio;
}

+ (NSString *)stubbedClass
{
  return @"AVAudioRecorder";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(record)),
        NSStringFromSelector(@selector(pause)),
        NSStringFromSelector(@selector(stop)),
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AVAudioRecorder tspk_audio_preload];
    });
}

@end
