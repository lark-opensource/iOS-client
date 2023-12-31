//
//  TSPKScreenRecordOfRPScreenRecorderPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKScreenRecordOfRPScreenRecorderPipeline.h"
#import <ReplayKit/RPScreenRecorder.h>
#import "NSObject+TSAddition.h"
#import "NSObject+TSDeallocAssociate.h"
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"

typedef void(^TSPKRPScreenRecorderStartHandler)(NSError * _Nullable error);
typedef void(^TSPKRPScreenRecorderEndHandler)(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error);

@implementation RPScreenRecorder (TSPrivacyKit)

+ (void)tspk_screen_record_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKScreenRecordOfRPScreenRecorderPipeline class] clazz:self];
}

- (void)tspk_screen_record_startRecordingWithMicrophoneEnabled:(BOOL)microphoneEnabled handler:(nullable void(^)(NSError * _Nullable error))handler {
    NSString *method = NSStringFromSelector(@selector(startRecordingWithMicrophoneEnabled:handler:));
    NSString *hashTag = [self ts_hashTag];
    
    TSPKHandleResult *result = [TSPKScreenRecordOfRPScreenRecorderPipeline handleAPIAccess:method className:[TSPKScreenRecordOfRPScreenRecorderPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (handler) {
            handler([TSPKUtils fuseError]);
        }
        return;
    }

    __weak typeof(self) weakSelf = self;
    TSPKRPScreenRecorderStartHandler swizzleHandler = ^(NSError *error) {
        if (error == nil) {
            [weakSelf tspk_handleStartMethodCalled:method];
        }
        !handler ?: handler(error);
    };
    
    [TSPKScreenRecordOfRPScreenRecorderPipeline forwardCallInfoWithMethod:method className:[TSPKScreenRecordOfRPScreenRecorderPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStart hashTag:hashTag beforeOrAfter:YES];
    [self tspk_screen_record_startRecordingWithMicrophoneEnabled:microphoneEnabled handler:swizzleHandler];
    [TSPKScreenRecordOfRPScreenRecorderPipeline forwardCallInfoWithMethod:method className:[TSPKScreenRecordOfRPScreenRecorderPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStart hashTag:hashTag beforeOrAfter:NO];
}


- (void)tspk_screen_record_startRecordingWithHandler:(nullable void(^)(NSError * _Nullable error))handler {
    NSString *method = NSStringFromSelector(@selector(startRecordingWithHandler:));
    NSString *hashTag = [self ts_hashTag];
    
    TSPKHandleResult *result = [TSPKScreenRecordOfRPScreenRecorderPipeline handleAPIAccess:method className:[TSPKScreenRecordOfRPScreenRecorderPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (handler) {
            handler([TSPKUtils fuseError]);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    TSPKRPScreenRecorderStartHandler swizzleHandler = ^(NSError *error) {
        if (error == nil) {
            [weakSelf tspk_handleStartMethodCalled:method];
        }
        !handler ?: handler(error);
    };
    [TSPKScreenRecordOfRPScreenRecorderPipeline forwardCallInfoWithMethod:method className:[TSPKScreenRecordOfRPScreenRecorderPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStart hashTag:hashTag beforeOrAfter:YES];
    [self tspk_screen_record_startRecordingWithHandler:swizzleHandler];
    [TSPKScreenRecordOfRPScreenRecorderPipeline forwardCallInfoWithMethod:method className:[TSPKScreenRecordOfRPScreenRecorderPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStart hashTag:hashTag beforeOrAfter:NO];

}

- (void)tspk_screen_record_stopRecordingWithHandler:(nullable void(^)(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error))handler {
    NSString *method = NSStringFromSelector(@selector(stopRecordingWithHandler:));
    NSString *hashTag = [self ts_hashTag];
    
    __weak typeof(self) weakSelf = self;
    TSPKRPScreenRecorderEndHandler swizzleHandler = ^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        if (error == nil) {
            [weakSelf tspk_handleStopMethodCalled:method];
        }
        !handler ?: handler(previewViewController, error);
    };
    
    [TSPKScreenRecordOfRPScreenRecorderPipeline forwardCallInfoWithMethod:method className:[TSPKScreenRecordOfRPScreenRecorderPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStop hashTag:hashTag beforeOrAfter:YES];
    [self tspk_screen_record_stopRecordingWithHandler:swizzleHandler];
    [TSPKScreenRecordOfRPScreenRecorderPipeline forwardCallInfoWithMethod:method className:[TSPKScreenRecordOfRPScreenRecorderPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStop hashTag:hashTag beforeOrAfter:NO];
}


//- (void)tspk_startCaptureWithHandler:(nullable void(^)(CMSampleBufferRef sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error))captureHandler completionHandler:(nullable void(^)(NSError * _Nullable error))completionHandler {
//
//    [self tspk_startCaptureWithHandler:captureHandler completionHandler:completionHandler];
//}
//
//- (void)tspk_stopCaptureWithHandler:(nullable void(^)(NSError * _Nullable error))handler {
//
//    [self tspk_stopCaptureWithHandler:handler];
//}

+ (void)forwardMethodEventToChannelWithMethodName:(NSString *)method
                                     apiUsageType:(TSPKAPIUsageType)apiUsageType
                                         instance:(NSObject *)instance
                                          hashTag:(NSString *)hashTag
                                    isNonsenstive:(BOOL)isNonsenstive {
    [TSPKScreenRecordOfRPScreenRecorderPipeline handleAPIAccess:method className:[TSPKScreenRecordOfRPScreenRecorderPipeline stubbedClass] params:nil customHandleBlock:^(TSPKAPIModel * _Nonnull apiModel) {
        apiModel.apiUsageType = apiUsageType;
        apiModel.instance = instance;
        apiModel.hashTag = hashTag;
        apiModel.isNonsenstive = isNonsenstive;
        
        apiModel.customReleaseCheckBlock = ^TSPKCheckResult(NSObject * _Nonnull obj) {
            if (![obj isKindOfClass:[RPScreenRecorder class]]) {
                [TSPKUtils assert:false message:@"object type is unexpect"];
                return TSPKCheckResultError;
            }
            
            RPScreenRecorder *recorder = (RPScreenRecorder *)obj;
            return [recorder isRecording] ? TSPKCheckResultUnrelease : TSPKCheckResultRelease;
        };
    }];
}

- (void)tspk_handleStartMethodCalled:(NSString *)methodName {
    NSString *hashTag = [self ts_hashTag];
//    __weak typeof(self) weakSelf = self;
    [self ts_addDeallocAction:^{
        [RPScreenRecorder forwardMethodEventToChannelWithMethodName:@"dealloc"
                                                       apiUsageType:TSPKAPIUsageTypeDealloc
                                                           instance:nil
                                                            hashTag:hashTag
                                                      isNonsenstive:YES];
    } withKey:@"RPScreenRecorder"];
    
    [RPScreenRecorder forwardMethodEventToChannelWithMethodName:methodName
                                                   apiUsageType:TSPKAPIUsageTypeStart
                                                       instance:self
                                                        hashTag:hashTag
                                                  isNonsenstive:NO];
}

- (void)tspk_handleStopMethodCalled:(NSString *)methodName {
    NSString *hashTag = [self ts_hashTag];
    [RPScreenRecorder forwardMethodEventToChannelWithMethodName:methodName
                                                   apiUsageType:TSPKAPIUsageTypeStop
                                                       instance:self
                                                        hashTag:hashTag
                                                  isNonsenstive:YES];
}

@end


@implementation TSPKScreenRecordOfRPScreenRecorderPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineScreenRecorderOfRPScreenRecorder;
}

+ (TSPKStoreType)storeType
{
    return TSPKStoreTypeRelationObjectCache;
}

+ (NSString *)stubbedClass
{
    return @"RPScreenRecorder";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(startRecordingWithMicrophoneEnabled:handler:)),
        NSStringFromSelector(@selector(startRecordingWithHandler:))
    ];
}

+ (NSString *)dataType {
    return TSPKDataTypeScreenRecord;
}

+ (void)preload
{
    [RPScreenRecorder tspk_screen_record_preload];
}

@end
