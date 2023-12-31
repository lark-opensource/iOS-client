//
//  CJPayButtonInfoHandler.m
//  CJPay-Example
//
//  Created by wangxinhua on 2020/9/20.
//

#import "CJPayButtonInfoHandler.h"
#import "CJPayIntergratedBaseResponse.h"
#import "CJPayCommonUtil.h"
#import "CJPayUIMacro.h"
#import "CJPayAlertUtil.h"
#import "UIViewController+CJPay.h"
#import "CJPayToast.h"

@implementation CJPayButtonInfoHandlerActionModel

@end

@implementation CJPayButtonInfoHandler

//"{
//    ""body_text"": """",
//    ""btn_text"": """",
//    ""btn_action"": """"
//}
//
//body_text：订单已超时，请重新下单
//btn_text: 我知道了
//btn_action: 参见后面action的描述"

+ (BOOL)handleResponse:(CJPayIntergratedBaseResponse *)response fromVC:(UIViewController *)fromVC withActionsModel:(nonnull CJPayButtonInfoHandlerActionModel *)actionModel {
    if ([response isSuccess]) {
        return NO;
    }
    NSDictionary *buttonInfo = [CJPayCommonUtil jsonStringToDictionary:response.typecnt];

    if ([response.errorType isEqualToString:@"single_btn_box"]) {
        // 双按钮
        [CJPayAlertUtil customSingleAlertWithTitle:[buttonInfo cj_stringValueForKey:@"body_text"] content:nil buttonDesc:[buttonInfo cj_stringValueForKey:@"btn_text"] actionBlock:^{
            !actionModel.singleBtnAction ?: actionModel.singleBtnAction([buttonInfo cj_integerValueForKey:@"btn_action"]);
        } useVC:[UIViewController cj_foundTopViewControllerFrom:fromVC]];
        return YES;
    } else if ([response.errorType isEqualToString:@"toast"]) {
        if (Check_ValidString(response.msg)) {
            [CJToast toastText:response.msg inWindow:fromVC.cj_window];
            return YES;
        }
    }
    return NO;
}

@end
