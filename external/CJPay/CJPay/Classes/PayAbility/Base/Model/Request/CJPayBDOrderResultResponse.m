//
//  CJPayBDOrderResultResponse.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/27.
//

#import "CJPayBDOrderResultResponse.h"
#import "CJPaySDKDefine.h"
#import "CJPayUIMacro.h"

NSString * const BDPayReduceTypeMarkStr = @"reduce";
NSString * const BDPayPayTypeMarkStr = @"paytype";

@implementation CJPayBDOrderResultResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
       [dict addEntriesFromDictionary:@{
               @"merchant": @"response.merchant_info",
               @"payInfos": @"response.pay_info",
               @"tradeInfo": @"response.trade_info",
               @"userInfo": @"response.user_info",
               @"resultConfig": @"response.result_page_show_conf",
               @"processInfo": @"response.process_info",
               @"bioPaymentInfo": @"response.bio_open_guide",
               @"buttonInfo": @"response.button_info",
               @"processingGuidePopupInfo": @"response.processing_guide_popup",
               @"skipPwdOpenStatus": @"response.nopwd_open_status",
               @"skipPwdOpenMsg": @"response.nopwd_open_msg",
               @"skipPwdGuideInfoModel": @"response.nopwd_guide_info",
               @"voucherDetails": @"response.voucher_details",
               @"payAfterUseGuideUrl": @"response.pay_after_use_guide_url",
               @"resultPageGuideInfoModel": @"response.result_guide_info",
               @"feGuideInfoModel": @"response.fe_guide_info",
               @"contentList": @"response.content_list",
               @"paymentInfo": @"response.payment_desc_infos",
               @"resultPageInfo": @"response.result_page_info",
       }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (int)closeAfterTime {
    return self.resultConfig.remainTime.intValue;
}

- (NSString *)payTypeDescText {
    for (CJPayResultPayInfo *payInfo in self.payInfos) {
        if ([payInfo.typeMark isEqualToString:BDPayPayTypeMarkStr]) {
            return payInfo.payTypeShowName;
        }
    }
    return @"";
}

//获取优惠信息
- (NSString *)halfScreenText {
    for (CJPayResultPayInfo *payInfo in self.payInfos) {
        if ([payInfo.typeMark isEqualToString:BDPayReduceTypeMarkStr]) {
            return payInfo.halfScreenDesc;
        }
    }
    return @"";
}

//获取分期信息
- (NSString *)creditPayInstallmentDesc {
    return CJString(self.tradeInfo.creditPayInstallmentDesc);
}


@end
