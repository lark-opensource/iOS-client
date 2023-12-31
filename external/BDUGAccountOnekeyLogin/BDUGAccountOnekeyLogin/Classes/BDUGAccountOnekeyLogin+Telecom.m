//
//  BDUGAccountOnekeyLogin+Telecom.m
//  BDUGAccountOnekeyLogin
//
//  Created by chenzhendong.ok@bytedance.com on 2021/1/27.
//

#import "BDUGAccountOnekeyLogin+Telecom.h"
#import "BDUGOnekeyLoginTracker.h"
#import "BDUGOnekeySettingManager.h"
#import <objc/runtime.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <EAccountApiSDK/EAccountSDK.h>


@implementation BDUGAccountOnekeyLogin (Telecom)

- (void)p_telecomGetTokenInfo:(void (^)(NSString *maskPhoneNum, BDUGOnekeyAuthInfo *authInfo, NSError *error, NSMutableDictionary *trackParams))completion {
    NSTimeInterval startTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;

    EAccountPreLoginConfigModel *model = [[EAccountPreLoginConfigModel alloc] initWithDefaultConfig];
    model.connectTimeoutInterval = self.telecomTimeoutInterval;
    model.timeoutIntervalForResource = self.telecomTimeoutInterval;
    model.totalTimeoutInterval = self.telecomTimeoutInterval;
    [EAccountSDK requestPRELogin:model completion:^(NSDictionary *_Nonnull resultDic) {
        btd_dispatch_async_on_main_queue(^{
            NSString *maskPhoneNum = nil;
            BDUGOnekeyAuthInfo *authInfo = nil;
            NSError *outError = nil;
            NSMutableDictionary *trackParams = [self telecomTrackParamsWithResult:resultDic error:nil startTime:startTime outputError:&outError];
            if (!outError && [resultDic bdugAccount_integerForKey:@"result" defaultValue:-1] == 0) {
                maskPhoneNum = [resultDic bdugAccount_stringForKey:@"number"];
                authInfo = [BDUGOnekeyAuthInfo new];
                authInfo.token = [resultDic bdugAccount_stringForKey:@"accessCode"];
                authInfo.gwAuth = [resultDic bdugAccount_stringForKey:@"gwAuth"];
            }
            !completion ?: completion(maskPhoneNum, authInfo, outError, trackParams);
        });
    } failure:^(NSError *_Nonnull error) {
        btd_dispatch_async_on_main_queue(^{
            !completion ?: completion(nil, nil, error, [self telecomTrackParamsWithResult:nil error:error startTime:startTime outputError:nil]);
        });
    }];
}

- (void)telecomGetPhoneNumberCompletion:(void (^)(NSString *phoneNumber, NSString *serviceName, NSError *error))completedBlock {
    [self p_telecomGetTokenInfo:^(NSString *maskPhoneNum, BDUGOnekeyAuthInfo *authInfo, NSError *error, NSMutableDictionary *trackParams) {
        !self.extraTrackInfoOfGetPhoneNumber ?: [trackParams addEntriesFromDictionary:self.extraTrackInfoOfGetPhoneNumber];
        [BDUGOnekeyLoginTracker trackerEvent:@"one_click_number_request_response" params:[trackParams copy]];
        !completedBlock ?: completedBlock(maskPhoneNum, BDUGAccountOnekeyTelecomV2, error);
    }];
}

- (void)telecomGetTokenWithCompletion:(void (^)(BDUGOnekeyAuthInfo *_Nullable authInfo, NSString *_Nullable serviceName, NSError *_Nullable error))completedBlock {
    [self p_telecomGetTokenInfo:^(NSString *maskPhoneNum, BDUGOnekeyAuthInfo *authInfo, NSError *error, NSMutableDictionary *trackParams) {
        !self.extraTrackInfoOfGetToken ?: [trackParams addEntriesFromDictionary:self.extraTrackInfoOfGetToken];
        [BDUGOnekeyLoginTracker trackerEvent:@"one_click_login_token_response" params:[trackParams copy]];
        !completedBlock ?: completedBlock(authInfo, BDUGAccountOnekeyTelecomV2, error);
    }];
}

- (void)telecomGetMobileValidateTokenWithCompletion:(void (^)(NSString *_Nullable, NSString *_Nullable, NSError *_Nullable))completion {
    [self p_telecomGetTokenInfo:^(NSString *maskPhoneNum, BDUGOnekeyAuthInfo *authInfo, NSError *error, NSMutableDictionary *trackParams) {
        !self.extraTrackInfoOfGetToken ?: [trackParams addEntriesFromDictionary:self.extraTrackInfoOfGetToken];
        [BDUGOnekeyLoginTracker trackerEvent:@"passport_mobile_validate_login" params:[trackParams copy]];
        !completion ?: completion(authInfo.token, BDUGAccountOnekeyTelecomV2, error);
    }];
}

- (NSMutableDictionary *)telecomTrackParamsWithResult:(NSDictionary *)resultDic error:(NSError *)error startTime:(NSTimeInterval)startTime outputError:(NSError **)outputError {
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionary];
    NSTimeInterval endTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    [trackParams setValue:@(endTime - startTime) forKey:@"duration"];
    [trackParams setValue:@"china_telecom" forKey:@"carrier"];
    [trackParams setValue:[BDUGOnekeyLoginTracker trackNetworkTypeOfService:[self currentNetworkType]] forKey:@"network_type"];

    [trackParams setValue:@(0) forKey:@"result_value"];
    if (error) {
        [trackParams setValue:@(error.code) forKey:@"error_code"];
        [trackParams setValue:error.description forKey:@"error_msg"];
    } else {
        if (!resultDic || ![resultDic isKindOfClass:[NSDictionary class]]) {
            [trackParams setValue:@(BDUGOnekeyLoginErrorThirdSDKException) forKey:@"error_code"];
            [trackParams setValue:@"三方运营商SDK返回数据异常" forKey:@"error_msg"];
            *outputError = [NSError errorWithDomain:BDUGAccountErrorDomain code:BDUGOnekeyLoginErrorThirdSDKException userInfo:trackParams];
        } else {
            NSInteger resultCode = [resultDic bdugAccount_integerForKey:@"result" defaultValue:-1];
            if (resultCode == 0) {
                [trackParams setValue:@(1) forKey:@"result_value"];
            } else {
                [trackParams setValue:@(resultCode) forKey:@"error_code"];
                [trackParams setValue:[resultDic bdugAccount_stringForKey:@"msg"] forKey:@"error_msg"];
                *outputError = [NSError errorWithDomain:BDUGAccountErrorDomain code:resultCode userInfo:trackParams];
            }
        }
    }
    return trackParams;
}

@end
