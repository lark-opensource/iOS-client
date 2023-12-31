//
//  CJPayRetainInfoV2Config.m
//  Aweme
//
//  Created by ByteDance on 2023/4/8.
//

#import "CJPayRetainInfoV2Config.h"
#import "CJPaySDKMacro.h"

@implementation CJPayRetainInfoV2Config

- (NSDictionary *)buildFEParams {// lynx挽留弹窗向前端传的所有参数都在此
    return @{
        @"retain_info_v2": self.retainInfoV2 ?: @{},
        @"selected_pay_type": CJString(self.selectedPayType),
        @"from_scene": CJString(self.fromScene),
        @"has_input_history": @(self.hasInputHistory),
        @"has_tried_input_password": @(self.hasTridInputPassword),
        @"is_only_show_normal_retain_style": @(self.isOnlyShowNormalRetainStyle),
        @"default_dialog_has_voucher": @(self.defaultDialogHasVoucher),
        @"is_combine_pay": self.isCombinePay ? @"1" : @"0",
        @"extra_data":@{
            @"app_id": CJString(self.appId),
            @"zg_app_id": CJString(self.zgAppId),
            @"merchant_id": CJString(self.merchantId),
            @"jh_merchant_id": CJString(self.jhMerchantId),
            @"trace_id": CJString(self.traceId),
            @"method": CJString(self.method),
            @"host_domain": CJString(self.hostDomain),
            @"process_info": self.processInfo ?: @{},
        },
        @"index": CJString(self.index),
        @"from": CJString(self.from),
        @"template_id" : CJString(self.templateId),
    };
}

- (BOOL)isOpenLynxRetain {
    return self.retainInfoV2 && Check_ValidString(self.retainSchema);
}

@end
