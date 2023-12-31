//
//  CJPayDeskConfig.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import "CJPayDeskConfig.h"

@implementation CJPayDeskConfig

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"confirmBtnDesc" : @"confirm_btn_desc",
                @"complianceBtnChangeTag" : @"compliance_btn_change_tag",
                @"showStyle" : @"show_style",
                @"themeString" : @"theme",
                @"agreementUrl" : @"user_agreement.content_url",
                @"agreementChoose" : @"user_agreement.default_choose",
                @"agreementTitle" : @"user_agreement.title",
                @"whetherShowLeftTime" : @"whether_show_left_time",//是否显示倒计时
                @"leftTime" : @"left_time_s",//倒计时器剩余时间
                @"noticeInfo" : @"notice_info",
                @"withdrawArrivalTime": @"withdraw_arrival_time",
                @"headerTitle" : @"half_screen_upper_msg",
                @"queryResultTime" : @"query_result_time_s", //结果页查询结果次数，默认5s
                @"remainTime" : @"remain_time_s",//结果页停留时间
                @"resultPageShowStyle" : @"result_page_show_style",
                @"jhResultPageStyle" : @"jh_result_page_style",
                @"containerViewLynxUrl" : @"lynx_url",
                @"renderTimeoutTime": @"lynx_render_timeout",
                @"callBackTypeStr" : @"callback_type"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (CJPayDeskTheme *)theme {
    NSError *err = nil;
    return [[CJPayDeskTheme alloc] initWithString:self.themeString error:&err];
}

- (CJPayDeskType)currentDeskType {
    switch (self.showStyle) {
        case 6:
            return CJPayDeskTypeBytePay;
        case 7:
            return CJPayDeskTypeBytePayHybrid;
        default:
            return CJPayDeskTypeBytePay;
    }
}

- (CJPayDeskConfigCallBackType)callBackType {
    if ([self.callBackTypeStr isEqualToString:@"after_query"]) {
        return CJPayDeskConfigCallBackTypeAfterQuery;
    } else if ([self.callBackTypeStr isEqualToString:@"after_close"]) {
        return CJPayDeskConfigCallBackTypeAfterClose;
    } else {
        return CJPayDeskConfigCallBackTypeAfterClose;
    }
}

@end
