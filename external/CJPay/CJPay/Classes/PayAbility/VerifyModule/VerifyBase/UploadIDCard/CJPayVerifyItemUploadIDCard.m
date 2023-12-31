//
//  CJPayVerifyItemUploadIDCard.m
//  CJPay
//
//  Created by 尚怀军 on 2020/3/30.
//

#import "CJPayVerifyItemUploadIDCard.h"
#import "CJPayUIMacro.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayWebViewUtil.h"
#import "CJPayAlertUtil.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayRetainUtil.h"
#import "CJPayBizWebViewController.h"

@interface CJPayVerifyItemUploadIDCard()

@property (nonatomic, weak) CJPayHalfPageBaseViewController *currentLoadingVC;

@end

@implementation CJPayVerifyItemUploadIDCard

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    // 需要上传身份证件
    if ([response.code isEqualToString:@"CD005010"]) {
        return YES;
    }
    return NO;
}

- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    // 需要上传身份证件
    if ([response.code isEqualToString:@"CD005010"]) {
        [self p_alertNeedUploadIDCardWithConfirmResponse:response];
    }
}

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    [self p_alertNeedUploadIDCardWithConfirmResponse:response.confirmResponse];
}

- (void)p_alertNeedUploadIDCardWithConfirmResponse:(CJPayOrderConfirmResponse *)response {
    @CJWeakify(self)
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"为了更好地提供支付服务，根据监管要求，需上传身份证影印件以验证你的身份") content:nil leftButtonDesc:CJPayLocalizedStr(@"取消") rightButtonDesc:CJPayLocalizedStr(@"去上传") leftActionBlock:^{
        @CJStrongify(self)
        [self event:@"wallet_identified_verification_inform_pate_click" params:@{@"button_name": @"取消"}];
        if (self.manager.isStandardDouPayProcess) {
            [self notifyVerifyCancel];
        } else {
            [self.manager sendEventTOVC:CJPayHomeVCEventUserCancelRiskVerify obj:@(CJPayVerifyTypeUploadIDCard)];
        }
    } rightActioBlock:^{
        @CJStrongify(self)
        [self startUploadIDCardWithConfirmResponse:response];
        [self event:@"wallet_identified_verification_inform_pate_click" params:@{@"button_name": @"去上传"}];
    } useVC:[self.manager.homePageVC topVC]];
    [self event:@"wallet_identified_verification_inform_page" params:nil];
}

- (void)startUploadIDCardWithConfirmResponse:(CJPayOrderConfirmResponse *)response {
    if (!Check_ValidString(response.jumpUrl)) {
        CJPayLogInfo(@"jumpurl empty, code %@", response.code);
        return;
    }
    // 拉起h5上传身份证的页面
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params cj_setObject:@"120" forKey:@"service"];
    [params cj_setObject:@"sdk" forKey:@"source"];
    if (self.manager.isOneKeyQuickPay) {
        NSDictionary *feTrackParamsDic = @{@"order_type": @"fast_pay"};
        [params cj_setObject:[feTrackParamsDic cj_toStr] forKey:@"extra_query"];
    }
    
    // 告知前端是否需要展示挽留
    CJPayRetainUtilModel *retainUtilModel = [self buildRetainUtilModel];
    NSString *needRetain = ([CJPayRetainUtil needShowRetainPage:retainUtilModel] && retainUtilModel.retainInfo.needVerifyRetain) ? @"1" : @"0";
    [params cj_setObject:needRetain forKey:@"cj_need_retain"];

    @CJWeakify(self)
    CJPayBizWebViewController *webvc = [[CJPayWebViewUtil sharedUtil] buildWebViewControllerWithUrl:response.jumpUrl fromVC:[self.manager.homePageVC topVC]
                                                                                             params:params
                                                                                  nativeStyleParams:@{}
                                                                                      closeCallBack:^(id  _Nonnull data) {
        @CJStrongify(self)
        [self handleWebCloseCallBackWithData:data];
    }];
    
    [self.manager.homePageVC push:webvc animated:YES];
}

- (void)handleWebCloseCallBackWithData:(id _Nonnull)data {
    NSDictionary *dic = (NSDictionary *)data;
    if (dic && [dic isKindOfClass:NSDictionary.class]) {
        NSString *service = [dic cj_stringValueForKey:@"service"];
        NSString *code = [dic cj_stringValueForKey:@"code"];
        NSString *action = [dic cj_stringValueForKey:@"action"];
        if ([service isEqualToString:@"120"]) {
            if ([code isEqualToString:@"1"]) {
                // 关闭收银台,回到业务方页面
                [self.manager.homePageVC closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromUploadIDCard];
            } else {
                // 继续确认支付
                NSMutableDictionary *param =  [NSMutableDictionary dictionaryWithDictionary:[self.manager loadSpecificTypeCacheData:CJPayVerifyTypeLast] ?: @{}];
                [param cj_setObject:@"12" forKey:@"req_type"];
                [self.manager submitConfimRequest:param fromVerifyItem:self];
            }
        } else if ([service isEqualToString:@"web"] && [action isEqualToString:@"back"]) {
            [self notifyVerifyCancel];
        } else {
            [self notifyWakeVerifyItemFail];
        }
    }
}

- (NSString *)checkTypeName {
    return @"上传身份证";
}

@end
