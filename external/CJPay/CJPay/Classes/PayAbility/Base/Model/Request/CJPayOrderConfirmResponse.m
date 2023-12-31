//
//  CJPayOrderConfirmResponse.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/24.
//

#import "CJPayOrderConfirmResponse.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayErrorButtonInfo.h"
#import "CJPayUIMacro.h"

@implementation CJPayOrderConfirmResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
       [dict addEntriesFromDictionary:@{
               @"jumpUrl": @"response.jump_url",
               @"mobile" : @"response.mobile",
               @"pwdLeftRetryTime": @"response.pwd_left_retry_time",
               @"pwdLeftLockTime": @"response.pwd_left_lock_time",
               @"payFlowNo": @"response.pay_flow_no",
               @"changePayTypeDesc": @"response.change_pay_type_desc",
               @"channelTradeNo": @"response.channel_trade_no",
               @"payDict": @"response.channel_info",
               @"pwdLeftLockTimeDesc": @"response.pwd_left_lock_time_desc",
               @"processInfo": @"response.process_info",
               @"processInfoDic": @"response.process_info",
               @"channelInfo": @"response.channel_info",
               @"buttonInfo": @"response.button_info",
               @"tradeNo" : @"response.trade_no",
               @"faceVerifyInfo" : @"response.face_verify_info",
               @"cardSignSuccess" : @"response.card_sign_success",
               @"combineLimitButton" : @"response.combine_limit_button",
               @"combineType" : @"response.combine_type",
               @"payTypeInfo": @"response.paytype_info",
               @"bankCardId" : @"response.bank_card_id",
               @"outTradeNo" : @"response.out_trade_no",
               @"tradeQueryResponseDic" : @"response.trade_query_info",
               @"frontBankName" : @"response.front_bank_name",
               @"cardTailNum" : @"response.card_no_mask_last_4",
               @"oneKeyPayPwdCheckMsg" : @"response.one_key_pay_pwd_check_msg",
               @"hintInfo"   : @"response.hint_info",
               @"signCardInfo" : @"response.card_sign_info",
               @"iconTips": @"response.icon_tips",
               @"forgetPwdInfo": @"response.forget_pwd_info",
               @"exts" : @"response.exts",
               @"orderResultResponseDict" : @"response.trade_query_response",
               @"cashierTag" : @"response.cashier_tag",
               @"payType": @"response.pay_type"
       }];
       
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

- (CJPayBDOrderResultResponse *)orderResultResponse {
    if (self.orderResultResponseDict.count) {
        NSDictionary *dict = @{@"response" : self.orderResultResponseDict};
        NSError *error;
        _orderResultResponse = [[CJPayBDOrderResultResponse alloc] initWithDictionary:dict error:&error];
        self.orderResultResponseDict = nil;// 只使用一次，用完立即清理
    }
    
    return _orderResultResponse;
}

@end
