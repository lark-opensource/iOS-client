//
//  BDCTFlowContext.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/5.
//

#import "BDCTFlowContext.h"
#import "BytedCertDefine.h"
#import "BytedCertParameter.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <BDModel/BDModel.h>


@interface BDCTFlowContext ()

@property (nonatomic, strong, readwrite) BytedCertParameter *parameter;

@end


@implementation BDCTFlowContext

+ (instancetype)contextWithParameter:(BytedCertParameter *)parameter {
    BDCTFlowContext *context = [BDCTFlowContext new];
    context.parameter = parameter;
    return context;
}

- (BOOL)needAuthFaceCompare {
    if (BTD_isEmptyDictionary(self.actions)) {
        return NO;
    }
    BOOL verifyFaceCompare = [self.actions btd_boolValueForKey:@"veri_face_compare"];
    BOOL authFaceCompare = [self.actions btd_boolValueForKey:@"auth_face_compare"];
    if (self.parameter.useSystemV2) {
        return verifyFaceCompare && authFaceCompare;
    } else {
        // veri_face_compare与auth_face_compare对应错，是已知的服务端返回问题
        if (self.parameter.mode == BytedCertProgressTypeIdentityAuth) {
            return verifyFaceCompare;
        }
        if (self.parameter.mode == BytedCertProgressTypeIdentityVerify) {
            return authFaceCompare;
        }
    }
    return NO;
}

- (NSDictionary *)baseParams {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    mutableParams[BytedCertParamAppId] = self.parameter.appId;
    mutableParams[@"cert_app_id"] = self.parameter.certAppId;
    mutableParams[BytedCertParamScene] = self.parameter.scene;
    mutableParams[BytedCertParamTicket] = self.parameter.ticket;
    mutableParams[BytedCertParamMode] = @(self.parameter.mode);
    mutableParams[@"flow"] = self.parameter.flow;
    [mutableParams addEntriesFromDictionary:self.parameter.extraParams];
    if (self.parameter.youthCertScene != -1) {
        mutableParams[@"youth_cert_scene"] = @(self.parameter.youthCertScene);
    }
    return mutableParams.copy;
}

- (NSDictionary *)identityParams {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    mutableParams[BytedCertParamIdentityName] = self.parameter.identityName;
    mutableParams[BytedCertParamIdentityCode] = self.parameter.identityCode;
    return mutableParams.copy;
}

- (void)setBackendDecision:(NSDictionary *)backendDecision {
    _backendDecision = backendDecision.copy;
    NSString *liveDetectionOptimize = [_backendDecision btd_stringValueForKey:@"live_detect_optimize"];
    _liveDetectionOpt = ([liveDetectionOptimize isEqualToString:@"only_client"] || [liveDetectionOptimize isEqualToString:@"all"]);
}

- (NSArray *)sensitiveInfoKey {
    return @[ @"identity_code", @"identity_name", @"phone_number", @"bank_card_number" ];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [self bd_modelCopy];
}

@end
