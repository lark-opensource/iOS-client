//
//  CJPayUserInfo.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/20.
//

#import "CJPayUserInfo.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPaySDKMacro.h"

@implementation CJPayUserInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"authStatus" : @"auth_status",
                @"certificateNum" : @"certificate_num",
                @"certificateType" : @"certificate_type",
                @"authUrl" : @"auth_url",
                @"lynxAuthUrl": @"lynx_auth_url",
                @"mid" : @"mid",
                @"uid" : @"uid",
                @"uidType" : @"uid_type",
                @"mobile"  : @"mobile" ,
                @"accountMobile" : @"account_mobile_mask",
                @"findPwdURL" : @"find_pwd_url",
                @"payIdState" : @"pay_id_state",
                @"isNewUser" : @"is_new_user",
                @"mName" : @"m_name",
                @"pwdStatus" : @"pwd_status",
                @"addPwdUrl" : @"add_pwd_url",
                @"bindUrl" : @"bind_url",
                @"decLiveUrl" : @"declive_url",
                @"pwdCheckWay" : @"pwd_check_way",
                @"passModel": @"pass_params",
                @"redirectBind": @"redirect_bind",
                @"balanceAmount":@"balance_amount",
                @"needAuthGuide":@"need_auth_guide",
                @"payAfterUseActive":@"pay_after_use_active",
                @"hasSignedCards":@"has_signed_cards",
                @"needCompleteUserInfo":@"need_complete_user_info",
                @"completeUrl":@"complete_url",
                @"completeLynxUrl": @"complete_lynx_url",
                @"completeHintTitle":@"complete_hint_title",
                @"completeType": @"complete_type",
                @"completeRightText": @"complete_right_text",
                @"completeOrderTimes": @"complete_order_times",
                @"chargeWithdrawStyle": @"charge_withdraw_style"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (NSString *)bindUrl{
    if (_bindUrl && _bindUrl.length > 0) {
        return _bindUrl;
    }
    return _authUrl;
}

- (BOOL)isNeedAddPwd {
    return ([self.authStatus isEqualToString:@"1"]) && ([self.pwdStatus isEqualToString:@"0"]) && (Check_ValidString(self.addPwdUrl));
}

- (BOOL)hasValidAuthStatus {
    return [self.authStatus isEqualToString:@"1"];
}

@end
