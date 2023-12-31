//
//  CJPayVerifyItemAddPhoneNum.m
//  CJPay
//
//  Created by 尚怀军 on 2020/3/30.
//

#import "CJPayVerifyItemAddPhoneNum.h"
#import "CJPayUIMacro.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayWebViewUtil.h"
#import "CJPayAlertUtil.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayDeskUtil.h"
#import "CJPayBizWebViewController.h"

@implementation CJPayVerifyItemAddPhoneNum

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    if ([response.code isEqualToString:@"CD002003"]) {
        return YES;
    }
    return NO;
}

- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    // 需要补充手机号
    if ([response.code isEqualToString:@"CD002003"]) {
        [self p_alertNeedAddPhoneNumWithConfirmResponse:response];
    }
}

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    [self p_alertNeedAddPhoneNumWithConfirmResponse:response.confirmResponse];
}

- (void)p_alertNeedAddPhoneNumWithConfirmResponse:(CJPayOrderConfirmResponse *)response {
    @CJWeakify(self)
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"为了保证交易安全，请你绑定手机号以继续当前操作") content:nil leftButtonDesc:CJPayLocalizedStr(@"取消") rightButtonDesc:CJPayLocalizedStr(@"补充手机号") leftActionBlock:^{
        @CJStrongify(self)
        [self event:@"wallet_bindphone_page_click" params:@{@"button_name": @"取消"}];
        if (self.manager.isStandardDouPayProcess) {
            [self notifyVerifyCancel];
        } else {
            [self.manager sendEventTOVC:CJPayHomeVCEventUserCancelRiskVerify obj:@(CJPayVerifyTypeAddPhoneNum)];
        }
    } rightActioBlock:^{
        @CJStrongify(self)
        [self startAddPhoneNumWithConfirmResponse:response];
        [self event:@"wallet_bindphone_page_click" params:@{@"button_name": @"补充手机号"}];
    } useVC:[self.manager.homePageVC topVC]];
    [self event:@"wallet_bindphone_page_imp" params:nil];
    
}

- (void)startAddPhoneNumWithConfirmResponse:(CJPayOrderConfirmResponse *)response {
    if (!Check_ValidString(response.jumpUrl)) {
        CJPayLogInfo(@"jumpurl empty, code %@", response.code);
        [self notifyWakeVerifyItemFail];
        return;
    }
    
    NSURL *url = [NSURL btd_URLWithString:response.jumpUrl];
    NSString *pageType = [url.btd_queryItems btd_stringValueForKey:@"cj_page_type"];
    if ([pageType isEqualToString:@"lynx"]) {
        [self startLynxAddPhoneNumWithConfirmResponse:response];
    } else {
        [self startH5AddPhoneNumWithConfirmResponse:response];
    }
}

- (void)startLynxAddPhoneNumWithConfirmResponse:(CJPayOrderConfirmResponse *)response {
    [CJPayDeskUtil openLynxPageBySchema:response.jumpUrl completionBlock:^(CJPayAPIBaseResponse * _Nullable response) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self p_callbackWithData:response.data];
        });
    }];
}

- (void)p_callbackWithData:(NSDictionary *)callbackData {
    if (![callbackData isKindOfClass:NSDictionary.class]) {
        [self notifyWakeVerifyItemFail];
        return;
    }
    CJPayLogInfo(@"lynx add phone num callback data: %@", callbackData);
    
    NSDictionary *data = [callbackData cj_dictionaryValueForKey:@"data"];
    if (![data isKindOfClass:NSDictionary.class]) {
        [self notifyWakeVerifyItemFail];
        return;
    }
    
    NSDictionary *msg = [data cj_dictionaryValueForKey:@"msg"];
    if (![msg isKindOfClass:NSDictionary.class]) {
        [self notifyWakeVerifyItemFail];
        return;
    }
    
    NSInteger code = [msg cj_intValueForKey:@"code" defaultValue:-1];
    if (code == 0) {
        NSMutableDictionary *params = [[self.manager loadSpecificTypeCacheData:CJPayVerifyTypeLast] mutableCopy];
        [params cj_setObject:@"13" forKey:@"req_type"];
        [self.manager submitConfimRequest:[params copy] fromVerifyItem:self];
    } else {
        [self notifyWakeVerifyItemFail];
    }
}

- (void)startH5AddPhoneNumWithConfirmResponse:(CJPayOrderConfirmResponse *)response {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params cj_setObject:@"121" forKey:@"service"];
    
    if (self.manager.isOneKeyQuickPay) {
        NSDictionary *feTrackParamsDic = @{@"order_type": @"fast_pay"};
        [params cj_setObject:[feTrackParamsDic cj_toStr] forKey:@"extra_query"];
    }
    
    @CJWeakify(self)
    CJPayBizWebViewController *webvc = [[CJPayWebViewUtil sharedUtil] buildWebViewControllerWithUrl:response.jumpUrl
                                                                                             fromVC:[self.manager.homePageVC topVC]
                                                                                             params:params
                                                                                  nativeStyleParams:@{}
                                                                                      closeCallBack:^(id  _Nonnull data) {
        @CJStrongify(self)
        NSDictionary *dic = (NSDictionary *)data;
        if (dic && [dic isKindOfClass:NSDictionary.class]) {
            NSString *service = [dic cj_stringValueForKey:@"service"];
            NSString *action = [dic cj_stringValueForKey:@"action"];
            if ([service isEqualToString:@"121"] && self) {
                NSMutableDictionary *params = [[self.manager loadSpecificTypeCacheData:CJPayVerifyTypeLast] mutableCopy];
                [params cj_setObject:@"13" forKey:@"req_type"];
                [self.manager submitConfimRequest:[params copy] fromVerifyItem:self];
            } else if ([service isEqualToString:@"web"] && [action isEqualToString:@"back"]) {
                [self notifyVerifyCancel];
            } else {
                [self notifyWakeVerifyItemFail];
            }
        } else {
            [self notifyWakeVerifyItemFail];
        }
    }];
    
    [self.manager.homePageVC push:webvc animated:YES];
}

- (NSString *)checkTypeName {
    return @"补手机号";
}

@end
