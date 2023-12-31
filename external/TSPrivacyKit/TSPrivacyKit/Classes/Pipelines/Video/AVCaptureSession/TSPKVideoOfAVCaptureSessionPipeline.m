//
//  TSPKVideoOfAVCaptureSessionPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKVideoOfAVCaptureSessionPipeline.h"

#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION

#import <AVFoundation/AVCaptureSession.h>
#import "NSObject+TSAddition.h"
#import "NSObject+TSDeallocAssociate.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"
#import <TSPrivacyKit/TSPKSignalManager+public.h>

@implementation AVCaptureSession (TSPrivacyKitVideo)

+ (void)tspk_video_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKVideoOfAVCaptureSessionPipeline class] clazz:self];
}

- (void)tspk_video_startRunning {
    NSString *method = NSStringFromSelector(@selector(startRunning));
    NSString *hashTag = [self ts_hashTag];
    
    [TSPKVideoOfAVCaptureSessionPipeline forwardCallInfoWithMethod:method className:[TSPKVideoOfAVCaptureSessionPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStart hashTag:hashTag beforeOrAfter:YES];
    
    TSPKHandleResult *result = [AVCaptureSession forwardMethodEventToChannelWithMethodName:method
                                                                              apiUsageType:TSPKAPIUsageTypeStart
                                                                                  instance:self
                                                                                   hashTag:hashTag
                                                                             isNonsenstive:NO];
    if (result.action == TSPKResultActionFuse) {
        [TSPKVideoOfAVCaptureSessionPipeline forwardCallInfoWithMethod:method className:[TSPKVideoOfAVCaptureSessionPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStart hashTag:hashTag beforeOrAfter:NO];
        return;
    }
    
    [self tspk_addDeallocAction];
    [self tspk_video_startRunning];
    
    NSString *content = [NSString stringWithFormat:@"After open, AVCaptureSession isRunning status %@", @(self.isRunning)];
    [TSPKSignalManager addInstanceSignalWithType:TSPKSignalTypeCustom
                                  permissionType:[TSPKVideoOfAVCaptureSessionPipeline dataType]
                                         content:content
                                 instanceAddress:hashTag];
    [TSPKVideoOfAVCaptureSessionPipeline forwardCallInfoWithMethod:method className:[TSPKVideoOfAVCaptureSessionPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStart hashTag:hashTag beforeOrAfter:NO];
}

- (void)tspk_video_stopRunning {
    [self tspk_video_stopRunningImp:NO];
}

- (void)tspk_video_stopRunningImp:(BOOL)isDowngrade {
    NSString *method = NSStringFromSelector(@selector(stopRunning));
    NSString *hashTag = [self ts_hashTag];
    
    [TSPKVideoOfAVCaptureSessionPipeline forwardCallInfoWithMethod:method className:[TSPKVideoOfAVCaptureSessionPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStop hashTag:hashTag beforeOrAfter:YES];
    [AVCaptureSession forwardMethodEventToChannelWithMethodName:method
                                                   apiUsageType:TSPKAPIUsageTypeStop
                                                       instance:self
                                                        hashTag:hashTag
                                                  isNonsenstive:YES
                                                    isDowngrade:isDowngrade];
    
    [self tspk_video_stopRunning];
    [TSPKVideoOfAVCaptureSessionPipeline forwardCallInfoWithMethod:method className:[TSPKVideoOfAVCaptureSessionPipeline stubbedClass] apiUsageType:TSPKAPIUsageTypeStop hashTag:hashTag beforeOrAfter:NO];
}

- (void)tspk_addDeallocAction {
    NSString *hashTag = [self ts_hashTag];
    [self ts_addDeallocAction:^{
        [AVCaptureSession forwardMethodEventToChannelWithMethodName:@"dealloc"
                                                       apiUsageType:TSPKAPIUsageTypeDealloc
                                                           instance:nil
                                                            hashTag:hashTag
                                                      isNonsenstive:YES];
    } withKey:@"CameraSession"];
}

+ (TSPKHandleResult *)forwardMethodEventToChannelWithMethodName:(NSString *)method
                                                   apiUsageType:(TSPKAPIUsageType)apiUsageType
                                                       instance:(NSObject *)instance
                                                        hashTag:(NSString *)hashTag
                                                  isNonsenstive:(BOOL)isNonsenstive {
    return [self forwardMethodEventToChannelWithMethodName:method
                                              apiUsageType:apiUsageType
                                                  instance:instance
                                                   hashTag:hashTag
                                             isNonsenstive:isNonsenstive
                                               isDowngrade:NO];
}

+ (TSPKHandleResult *)forwardMethodEventToChannelWithMethodName:(NSString *)method
                                                   apiUsageType:(TSPKAPIUsageType)apiUsageType
                                                       instance:(NSObject *)instance
                                                        hashTag:(NSString *)hashTag
                                                  isNonsenstive:(BOOL)isNonsenstive
                                                    isDowngrade:(BOOL)isDowngrade {

    return [TSPKVideoOfAVCaptureSessionPipeline handleAPIAccess:method className:[TSPKVideoOfAVCaptureSessionPipeline stubbedClass] params:nil customHandleBlock:^(TSPKAPIModel * _Nonnull apiModel) {
        apiModel.apiUsageType = apiUsageType;
        apiModel.instance = instance;
        apiModel.hashTag = hashTag;
        apiModel.isDowngradeBehavior = isDowngrade;
        apiModel.isNonsenstive = isNonsenstive;
        apiModel.customReleaseCheckBlock = ^TSPKCheckResult(NSObject * _Nonnull obj) {
            if (![obj isKindOfClass:[AVCaptureSession class]]) {
                [TSPKUtils assert:false message:@"object type is unexpect"];
                return TSPKCheckResultError;
            }
            
            AVCaptureSession *capture = (AVCaptureSession *)obj;
            return [capture isRunning] ? TSPKCheckResultUnrelease : TSPKCheckResultRelease;
        };
        
        if (apiUsageType == TSPKAPIUsageTypeStart) {
            __weak NSObject *weakInstance = instance;
            apiModel.downgradeAction = ^{
                if (![weakInstance isKindOfClass:[AVCaptureSession class]]) {
                    return;
                }
                AVCaptureSession *strongInstance = (AVCaptureSession *)weakInstance;
                [strongInstance tspk_video_stopRunningImp:YES];
            };
        }
    }];
}

@end

#endif

@implementation TSPKVideoOfAVCaptureSessionPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineVideoOfAVCaptureSession;
}

+ (NSString *)dataType {
    return TSPKDataTypeVideo;
}

+ (NSString *)stubbedClass
{
    return @"AVCaptureSession";
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
    return @[
        NSStringFromSelector(@selector(startRunning)),
        NSStringFromSelector(@selector(stopRunning))
    ];
#else
    return [NSArray array];
#endif
}

+ (TSPKStoreType)storeType
{
    return TSPKStoreTypeRelationObjectCache;
}

+ (void)preload
{
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AVCaptureSession tspk_video_preload];
    });
#endif
}

@end
