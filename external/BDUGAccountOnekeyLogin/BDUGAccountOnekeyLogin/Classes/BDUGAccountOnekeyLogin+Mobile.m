//
//  BDUGAccountOnekeyLogin+Mobile.m
//  BDUGAccountOnekeyLogin
//
//  Created by chenzhendong.ok@bytedance.com on 2021/1/27.
//

#import "BDUGAccountOnekeyLogin+Mobile.h"
#import "BDUGOnekeyLoginTracker.h"
#import "BDUGOnekeySettingManager.h"

#import <TYRZSDK/TYRZSDK.h>
#import <ByteDanceKit/ByteDanceKit.h>


@implementation BDUGAccountOnekeyLogin (Mobile)

- (void)mobileGetPhoneNumberCompletion:(void (^)(NSString *phoneNumber, NSString *serviceName, NSError *error))completedBlock {
    NSTimeInterval startTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    [UASDKLogin.shareLogin getPhoneNumberCompletion:^(NSDictionary *_Nonnull sender) {
        btd_dispatch_async_on_main_queue(^{
            NSError *error = nil;
            NSMutableDictionary *trackParams = [self mobileParseTrackParamsWithResultDictionary:sender startTime:startTime error:&error];
            if (self.extraTrackInfoOfGetPhoneNumber) {
                [trackParams addEntriesFromDictionary:self.extraTrackInfoOfGetPhoneNumber];
            }
            [BDUGOnekeyLoginTracker trackerEvent:@"one_click_number_request_response" params:[trackParams copy]];

            NSString *maskPhoneNum = [sender isKindOfClass:NSDictionary.class] ? [sender bdugAccount_stringForKey:@"securityPhone"] : nil;
            !completedBlock ?: completedBlock(maskPhoneNum, BDUGAccountOnekeyMobile, error);
        });
    }];
}

- (void)mobileGetTokenWithCompletion:(void (^)(BDUGOnekeyAuthInfo *_Nullable authInfo, NSString *_Nullable serviceName, NSError *_Nullable error))completedBlock {
    NSTimeInterval startTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    [UASDKLogin.shareLogin getAuthorizationCompletion:^(NSDictionary *_Nonnull sender) {
        btd_dispatch_async_on_main_queue(^{
            NSError *error = nil;
            NSMutableDictionary *trackParams = [self mobileParseTrackParamsWithResultDictionary:sender startTime:startTime error:&error];
            if (self.extraTrackInfoOfGetToken) {
                [trackParams addEntriesFromDictionary:self.extraTrackInfoOfGetToken];
            }
            [BDUGOnekeyLoginTracker trackerEvent:@"one_click_login_token_response" params:[trackParams copy]];

            BDUGOnekeyAuthInfo *authInfo = nil;
            NSString *token = [sender isKindOfClass:NSDictionary.class] ? [sender bdugAccount_stringForKey:@"token"] : nil;
            if (token.length) {
                authInfo = [BDUGOnekeyAuthInfo new];
                authInfo.token = token;
            }
            !completedBlock ?: completedBlock(authInfo, BDUGAccountOnekeyMobile, error);
        });
    }];
}

- (void)mobileGetMobileValidateTokenWithCompletion:(void (^)(NSString *_Nonnull, NSString *_Nonnull, NSError *_Nonnull))completion {
    NSTimeInterval startTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    [UASDKLogin.shareLogin mobileAuthCompletion:^(NSDictionary *_Nonnull result) {
        btd_dispatch_async_on_main_queue(^{
            NSError *error = nil;
            NSDictionary *trackParams = [self mobileParseTrackParamsWithResultDictionary:result startTime:startTime error:&error];
            [BDUGOnekeyLoginTracker trackerEvent:@"passport_mobile_validate_login" params:[trackParams copy]];
            NSString *token = [result isKindOfClass:NSDictionary.class] ? [result bdugAccount_stringForKey:@"token"] : nil;
            !completion ?: completion(token, BDUGAccountOnekeyMobile, error);
        });
    }];
}

- (NSMutableDictionary *)mobileParseTrackParamsWithResultDictionary:(NSDictionary *)result startTime:(NSTimeInterval)startTime error:(NSError **)error {
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionary];
    NSTimeInterval endTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    trackParams[@"duration"] = @(endTime - startTime);
    trackParams[@"carrier"] = @"china_mobile";
    trackParams[@"network_type"] = [BDUGOnekeyLoginTracker trackNetworkTypeOfService:[self currentNetworkType]];
    if (!result || ![result isKindOfClass:[NSDictionary class]]) {
        trackParams[@"result_value"] = @0;
        trackParams[@"error_code"] = @(BDUGOnekeyLoginErrorThirdSDKException);
        trackParams[@"error_msg"] = @"三方运营商SDK返回数据异常";
        *error = [NSError errorWithDomain:BDUGAccountErrorDomain code:BDUGOnekeyLoginErrorThirdSDKException userInfo:trackParams];
    } else {
        NSString *resultCode = [result bdugAccount_stringForKey:@"resultCode"];
        if ([resultCode isEqualToString:@"103000"]) {
            trackParams[@"result_value"] = @1;
        } else {
            trackParams[@"result_value"] = @0;
            trackParams[@"error_code"] = resultCode;
            trackParams[@"error_msg"] = [result bdugAccount_stringForKey:@"desc"];
            *error = [NSError errorWithDomain:BDUGAccountErrorDomain code:[result bdugAccount_integerForKey:@"resultCode" defaultValue:BDUGOnekeyLoginErrorThirdSDKException] userInfo:trackParams];
        }
    }
    return trackParams;
}

@end
