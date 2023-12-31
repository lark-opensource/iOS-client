//
//  CJPaySignCardMap.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/25.
//

#import "CJPaySignCardMap.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPaySDKMacro.h"

@interface CJPaySignCardMap ()

@property (nonatomic, copy) NSString *oneKeyBankInfoStr;
@end

@implementation CJPaySignCardMap

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                   @"allowTransCardType" : @"allow_trans_card_type",
                   @"idNameMask" : @"id_name_mask",
                   @"idType" : @"id_type",
                   @"isAuthed": @"is_authed",
                   @"isSetPwd": @"is_set_pwd",
                   @"mobileMask": @"mobile_mask",
                   @"skipPwd": @"skip_pwd",
                   @"smchId": @"smch_id",
                   @"uidMobileMask": @"uid_mobile_mask",
                   @"payUID": @"pay_uid",
                   @"protocolDescription" : @"protocol_description",
                   @"buttonDescription" : @"button_description",
                   @"jumpQuickBindCard" : @"jump_one_key_sign",
                   @"oneKeyBankInfoStr": @"one_key_bank_info",
                   @"memberBizOrderNo": @"member_biz_order_no",
                   @"appId": @"app_id",
                   @"merchantId": @"merchant_id"
               }];
}

- (void)setOneKeyBankInfoStr:(NSString *)oneKeyBankInfoStr {
    _oneKeyBankInfoStr = oneKeyBankInfoStr;
    NSDictionary *dic = [CJPayCommonUtil jsonStringToDictionary:_oneKeyBankInfoStr];
    NSError *err = nil;
    self.quickCardModel = [[CJPayQuickBindCardModel alloc] initWithDictionary:dic error:&err];
    self.displayIcon = [dic cj_stringValueForKey:@"display_icon"];
    self.displayDesc = [dic cj_stringValueForKey:@"display_desc"];
}


+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
