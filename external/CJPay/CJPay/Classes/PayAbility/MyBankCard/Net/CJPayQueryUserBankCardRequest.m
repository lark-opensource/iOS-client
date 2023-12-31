//
//  CJPayQueryUserBankCardRequest.m
//  BDPay
//
//  Created by 易培淮 on 2019/5/25.
//

#import "CJPayQueryUserBankCardRequest.h"
#import "CJPayUIMacro.h"
#import "CJPayRequestParam.h"
#import "CJPaySDKDefine.h"
#import "CJPayBaseRequest+BDPay.h"

@implementation CJPayQueryUserBankCardRequestModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"smchID": @"smch_id",
        @"isNeedQueryBankCardList": @"is_need_query_bankcard_list",
        @"isNeedQueryAuthInfo": @"is_need_query_auth_info",
        @"isNeedBindTopPageUrl": @"is_need_bind_top_page_url",
        @"source": @"source"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (NSDictionary *)encryptDict {
    return @{
        @"smch_id": @"SmchId",
        @"is_need_query_bankcard_list": @(_isNeedQueryBankCardList),
        @"is_need_query_auth_info": @(_isNeedQueryAuthInfo),
        @"is_need_bind_top_page_url": @(_isNeedBindCardTopPageUrl),
        @"source":(CJString(_source))
    };
}

@end


@implementation BDPayQueryUserBankCardResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self.basicDict mutableCopy];
    [dict addEntriesFromDictionary:@{@"authActionUrl" : @"response.auth_action_url",
                                     @"cardList" : @"response.member.card_list",
                                     @"userInfo" : @"response.member.auth_info",
                                     @"isAuthed" : @"response.member.is_authed",
                                     @"isOpenAccount" : @"response.member.is_open_account",
                                     @"isSetPWD" : @"response.member.is_set_pwd",
                                     @"memberLevel" : @"response.member.member_level",
                                     @"memberType" : @"response.member.member_type",
                                     @"mobileMask" : @"response.member.mobile_mask",
                                     @"payUID" : @"response.member.pay_uid",
                                     @"needAuthGuide" : @"response.need_auth_guide",
                                     @"needShowUnbind" : @"response.need_show_unbind",
                                     @"unbindUrl": @"response.unbind_url",
                                     @"bindTopPageUrl": @"response.bind_top_page_url"
                                     }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dict];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (CJPayUserInfo *)generateUserInfo
{
    CJPayUserInfo *userInfo = [CJPayUserInfo new];
    userInfo.authStatus = self.isAuthed ? @"1" : @"0";
    userInfo.pwdStatus = self.isSetPWD ? @"1" : @"0";
    userInfo.mName = self.userInfo.idNameMask;
    userInfo.mobile = self.userInfo.mobileMask;
    userInfo.needAuthGuide = self.needAuthGuide;
    return userInfo;
}

@end


@implementation CJPayQueryUserBankCardRequest

+ (void)startWithModel:(CJPayQueryUserBankCardRequestModel *)requestModel
       bizRequestModel:(CJPayPassKitBizRequestModel *)bizRequestModel
            completion:(void (^)(NSError *error, BDPayQueryUserBankCardResponse *response))completion {
    NSDictionary *requestParam = [self p_buildRequestParamsWithRequestModel:requestModel
                                                            bizRequestModel:bizRequestModel];
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParam callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        BDPayQueryUserBankCardResponse *response = [[BDPayQueryUserBankCardResponse alloc] initWithDictionary:jsonObj error:&err];
        if (completion) {
            response.userInfo.isAuthed = response.isAuthed;
            response.userInfo.isOpenAccount = response.isOpenAccount;
            response.userInfo.isSetPWD = response.isSetPWD;
            response.userInfo.memberLevel = response.memberLevel;
            response.userInfo.memberType = response.memberType;
            response.userInfo.mobileMask = response.mobileMask;
            response.userInfo.payUID = response.payUID;
            completion(error, response);
        }
    }];
}

+ (NSDictionary *)p_buildRequestParamsWithRequestModel:(CJPayQueryUserBankCardRequestModel *)requestModel
                                     bizRequestModel:(CJPayPassKitBizRequestModel *)bizRequestModel
{
    NSMutableDictionary *bizContent = requestModel.encryptDict.mutableCopy;
    [bizContent cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    NSString *bizContentString = [bizContent cj_toStr];
    
    NSMutableDictionary *requestParams = [self buildBaseParams];
    [requestParams cj_setObject:bizContentString forKey:@"biz_content"];
    [requestParams cj_setObject:CJString(bizRequestModel.appID) forKey:@"app_id"];
    [requestParams cj_setObject:CJString(bizRequestModel.merchantID) forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return requestParams;
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/query_pay_member";
}

@end
