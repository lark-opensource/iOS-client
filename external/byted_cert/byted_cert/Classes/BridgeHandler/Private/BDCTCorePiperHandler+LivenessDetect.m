//
//  BytedCertCorePiperHandler+LivenessDetect.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/10.
//

#import "BDCTCorePiperHandler+LivenessDetect.h"
#import "BytedCertWrapper.h"
#import "BDCTEventTracker.h"
#import "BDCTAPIService.h"
#import "BDCTImageManager.h"
#import "BDCTFlowContext.h"
#import "BDCTFaceVerificationFlow.h"
#import "BDCTLog.h"
#import "BytedCertManager+Private.h"

#import <objc/runtime.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <BDModel/BDModel.h>
#import <BDModel/BDMappingStrategy.h>


@implementation BDCTCorePiperHandler (LivenessDetect)

- (BOOL)isRuningLiveCert {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setIsRuningLiveCert:(BOOL)isRuningLiveCert {
    objc_setAssociatedObject(self, @selector(isRuningLiveCert), [NSNumber numberWithBool:isRuningLiveCert], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)registerOpenLiveCert {
    [self registeJSBWithName:@"bytedcert.openLiveCert" handler:^(NSDictionary *_Nullable jsbParams, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        [self doFaceLivenessWithLivenessType:nil piperParams:jsbParams jsbCallback:callback];
    }];
}

- (void)registerOpenVideoCert {
    [self registeJSBWithName:@"bytedcert.openVideoCert" handler:^(NSDictionary *_Nullable jsbParams, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        [self doFaceLivenessWithLivenessType:BytedCertLiveTypeVideo piperParams:jsbParams jsbCallback:callback];
    }];
}

- (void)doFaceLivenessWithLivenessType:(NSString *)livenessType piperParams:(NSDictionary *)piperParams jsbCallback:(TTBridgeCallback)jsbCallback {
    if (self.isRuningLiveCert == YES) {
        BDCTLogInfo(@"FaceLiveCert is running.");
        return;
    }
    self.isRuningLiveCert = YES;
    [self.flow.eventTracker trackFaceDetectionStartCheck];

    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    mutableParams[BytedCertLivenessType] = livenessType;
    [piperParams enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        if ([obj isKindOfClass:NSDictionary.class]) {
            [mutableParams addEntriesFromDictionary:(NSDictionary *)obj];
        } else {
            [mutableParams btd_setObject:obj forKey:key];
        }
    }];

    BytedCertParameter *parameter = [[BytedCertParameter alloc] initWithBaseParams:[BDMappingStrategy mapJSONKeyWithDictionary:[self.flow.context.parameter bd_modelToJSONObject] options:BDModelMappingOptionsCamelCaseToSnakeCase] identityParams:mutableParams.copy];
    parameter.frontImageData = [self.imageManager getImageByType:@"front"];
    parameter.backImageData = [self.imageManager getImageByType:@"back"];

    [[BytedCertManager shareInstance] p_beginFaceVerificationWithParameter:parameter fromViewController:nil forcePresent:NO suprtFlow:self.flow shouldBeginFaceVerification:nil completion:^(BytedCertError *_Nullable bytedCertError, NSDictionary *_Nullable result) {
        self.isRuningLiveCert = NO;
        self.flow.context.faceEnvImageBase64 = [[result btd_dictionaryValueForKey:@"data"] btd_stringValueForKey:@"image_env"];
        jsbCallback(TTBridgeMsgSuccess, [BDCTCorePiperHandler jsbCallbackResultWithParams:bytedCertError ? result : nil error:bytedCertError], nil);
    }];
}

@end
