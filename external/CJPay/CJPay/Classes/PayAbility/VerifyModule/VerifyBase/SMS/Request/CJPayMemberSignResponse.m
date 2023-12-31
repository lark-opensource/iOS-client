//
//  CJPayMemberSignResponse.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/17.
//

#import "CJPayMemberSignResponse.h"

@implementation CJPaySendSMSResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
                                    @"smsToken" : @"response.sms_token",
                                    @"mobileMask" : @"response.mobile_mask",
                                    @"buttonInfo" : @"response.button_info",
                                    @"verifyTextMsg": @"response.verify_text_msg",
                                    @"faceVerifyInfo" : @"response.face_verify_info",
                                    @"agreements" : @"response.card_protocol_list",
                                    @"protocolGroupNames" : @"response.protocol_group_names",
                                  }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

@end

@implementation CJPaySignSMSResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
                                    @"signNo" : @"response.sign_no",
                                    @"bankCardId" : @"response.bank_card_id",
                                    @"pwdToken" : @"response.pwd_token",
                                    @"cardInfoModel" : @"response.card_info",
                                    @"buttonInfo" : @"response.button_info"
                                  }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

@end
