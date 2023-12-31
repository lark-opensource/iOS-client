//
//  BDUGAccountOnekeyLogin+Unicom.m
//  BDUGAccountOnekeyLogin
//
//  Created by chenzhendong.ok@bytedance.com on 2021/1/27.
//

#import "BDUGAccountOnekeyLogin+Unicom.h"
#import "BDUGOnekeyLoginTracker.h"
#import "BDUGOnekeySettingManager.h"
#import <objc/runtime.h>
#import <EAccountApiSDK/EAccountSDK.h>
#import <account_login_sdk_noui_core/account_login_sdk_noui_core.h>
#import <ByteDanceKit/ByteDanceKit.h>


@implementation BDUGAccountOnekeyLogin (Unicom)

- (void)p_unionGetTokenInfoWithCompletion:(void (^)(NSString *maskPhoneNum, NSString *accessCode, NSError *error, NSMutableDictionary *trackParams))completion {
    NSTimeInterval startTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    [[UniAuthHelper getInstance] getAccessCode:self.unionTimeoutInterval listener:^(NSDictionary *_Nonnull data) {
        btd_dispatch_async_on_main_queue(^{
            NSString *maskPhoneNum = nil;
            NSString *accessCode = nil;
            NSError *error = nil;
            NSMutableDictionary *trackParams = [self unionTrackParamsWithResult:data startTime:startTime outputError:&error];

            NSString *resultCode = [data bdugAccount_stringForKey:@"resultCode"];
            NSDictionary *resultData = [data bdugAccount_dictionaryForKey:@"resultData"];
            if (!error && [resultCode isEqualToString:@"0"] && [resultData isKindOfClass:[NSDictionary class]]) {
                maskPhoneNum = [resultData bdugAccount_stringForKey:@"mobile"];
                accessCode = [resultData bdugAccount_stringForKey:@"accessCode"];
            }
            !completion ?: completion(maskPhoneNum, accessCode, error, trackParams);
        });
    }];
}

- (void)unionGetPhoneNumberCompleted:(void (^)(NSString *phoneNumber, NSString *serviceName, NSError *error))completedBlock {
    [self p_unionGetTokenInfoWithCompletion:^(NSString *maskPhoneNum, NSString *accessCode, NSError *error, NSMutableDictionary *trackParams) {
        !self.extraTrackInfoOfGetPhoneNumber ?: [trackParams addEntriesFromDictionary:self.extraTrackInfoOfGetPhoneNumber];
        [BDUGOnekeyLoginTracker trackerEvent:@"one_click_number_request_response" params:[trackParams copy]];
        !completedBlock ?: completedBlock(maskPhoneNum, BDUGAccountOnekeyUnion, error);
    }];
}

- (void)unionGetTokenWithCompleted:(void (^)(BDUGOnekeyAuthInfo *_Nullable authInfo, NSString *_Nullable serviceName, NSError *_Nullable error))completedBlock {
    [self p_unionGetTokenInfoWithCompletion:^(NSString *maskPhoneNum, NSString *accessCode, NSError *error, NSMutableDictionary *trackParams) {
        [BDUGOnekeyLoginTracker trackerEvent:@"one_click_login_token_response" params:[trackParams copy]];
        BDUGOnekeyAuthInfo *authInfo = [BDUGOnekeyAuthInfo new];
        authInfo.token = accessCode;
        !completedBlock ?: completedBlock(authInfo, BDUGAccountOnekeyUnion, error);
    }];
}

- (NSMutableDictionary *)unionTrackParamsWithResult:(NSDictionary *)resultDic startTime:(NSTimeInterval)startTime outputError:(NSError **)outputError {
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionary];
    NSTimeInterval endTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    [trackParams setValue:@(endTime - startTime) forKey:@"duration"];
    [trackParams setValue:@"china_unicom" forKey:@"carrier"];
    [trackParams setValue:[BDUGOnekeyLoginTracker trackNetworkTypeOfService:[self currentNetworkType]] forKey:@"network_type"];

    [trackParams setValue:@(0) forKey:@"result_value"];
    if (!resultDic || ![resultDic isKindOfClass:[NSDictionary class]]) {
        [trackParams setValue:@(BDUGOnekeyLoginErrorThirdSDKException) forKey:@"error_code"];
        [trackParams setValue:@"三方运营商SDK返回数据异常" forKey:@"error_msg"];
        *outputError = [NSError errorWithDomain:BDUGAccountErrorDomain code:BDUGOnekeyLoginErrorThirdSDKException userInfo:trackParams];
    } else {
        NSInteger resultCode = [resultDic bdugAccount_integerForKey:@"resultCode" defaultValue:-1];
        if (resultCode == 0) {
            [trackParams setValue:@(1) forKey:@"result_value"];
        } else {
            [trackParams setValue:[resultDic bdugAccount_stringForKey:@"resultCode"] forKey:@"error_code"];
            [trackParams setValue:[resultDic bdugAccount_stringForKey:@"resultMsg"] forKey:@"error_msg"];
            *outputError = [NSError errorWithDomain:BDUGAccountErrorDomain code:resultCode userInfo:trackParams];
        }
    }
    return trackParams;
}

@end
