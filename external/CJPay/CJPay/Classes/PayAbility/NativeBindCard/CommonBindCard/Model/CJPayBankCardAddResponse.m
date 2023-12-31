//
//  CJPayBankCardAddResponse.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/12.
//

#import "CJPayBankCardAddResponse.h"
#import "CJPayAgreementModel.h"
#import "CJPayBizAuthInfoModel.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayCommonUtil.h"
#import "CJPayUserInfoPassModel.h"
#import "CJPayUnionPaySignInfo.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayBindPageInfoResponse.h"

@interface CJPayBankCardAddResponse()

@property (nonatomic, copy) NSString *busiAuthInfoStr;
@end

@implementation CJPayBankCardAddResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{@"ulRequestParams" : @"response.url_params",
                                     @"bankAgreementModels" : @"response.bank_user_agreements",
                                     @"userInfo" : @"response.user_info",
                                     @"allowTransCardType" : @"response.allow_trans_card_type",
                                     @"busiAuthInfoStr" : @"response.busi_authorize_info_str",
                                     @"verifyPwdCopywritingInfo": @"response.verify_pwd_copywriting_info",
                                     @"passModel": @"response.pass_params",
                                     @"unionPaySignInfoString": @"response.union_pay_sign_info",
                                     @"bindPageInfoResponseStr" : @"response.bind_card_page_info_str",
                                     @"retainInfoModel" : @"response.retention_msg",
                                     @"backgroundInfo" : @"response.background_info"

    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

- (void)setBusiAuthInfoStr:(NSString *)busiAuthInfoStr {
    _busiAuthInfoStr = busiAuthInfoStr;
    NSDictionary *dic = [CJPayCommonUtil jsonStringToDictionary:_busiAuthInfoStr];
    NSError *err = nil;
    self.bizAuthInfoModel = [[CJPayBizAuthInfoModel alloc] initWithDictionary:dic error:&err];
}

- (void)setUlRequestParams:(NSDictionary *)ulRequestParams {
    _ulRequestParams = ulRequestParams;
    if (Check_ValidString([_ulRequestParams cj_stringValueForKey:@"one_key_bank_info"])) {
        NSString *oneKeyBankInfoStr = [_ulRequestParams cj_stringValueForKey:@"one_key_bank_info"];
        [self setupOneKeyBankInfoStr:oneKeyBankInfoStr];
    }
}

- (void)setupOneKeyBankInfoStr:(NSString *)oneKeyBankInfoStr {
    NSDictionary *dic = [CJPayCommonUtil jsonStringToDictionary:oneKeyBankInfoStr];
    NSError *err = nil;
    self.quickCardModel = [[CJPayQuickBindCardModel alloc] initWithDictionary:dic error:&err];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (CJPayUnionPaySignInfo *)unionPaySignInfo {
    NSError *error = nil;
    CJPayUnionPaySignInfo *signInfo = [[CJPayUnionPaySignInfo alloc] initWithDictionary:[self.unionPaySignInfoString cj_toDic] error:&error];
    return signInfo;
}

- (CJPayBindPageInfoResponse *)bindPageInfoResponse {
    NSError *error = nil;
    CJPayBindPageInfoResponse *bindPageInfoResponse = [[CJPayBindPageInfoResponse alloc] initWithDictionary:[self.bindPageInfoResponseStr cj_toDic] error:&error];
    return bindPageInfoResponse;
}

@end
