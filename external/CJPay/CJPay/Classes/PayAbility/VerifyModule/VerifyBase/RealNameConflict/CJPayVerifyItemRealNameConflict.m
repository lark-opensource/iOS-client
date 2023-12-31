//
//  CJPayVerifyItemRealNameConflict.m
//  CJPay
//
//  Created by liyu on 2020/5/14.
//

#import "CJPayVerifyItemRealNameConflict.h"

#import "CJPayWebViewUtil.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayAlertUtil.h"
#import "CJPayHalfVerifyPasswordNormalViewController.h"
#import "CJPayUIMacro.h"
#import "UIViewController+CJPay.h"

@implementation CJPayVerifyItemRealNameConflict

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    // 需要处理实名冲突
    if ([@[@"CD001801" ,@"CD4001"] containsObject:CJString(response.code)]) {
        return YES;
    }
    return NO;
}

- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    // 需要处理实名冲突
    if ([@[@"CD001801" ,@"CD4001"] containsObject:CJString(response.code)]) {
        if (!Check_ValidString(response.jumpUrl)) {
            CJPayLogInfo(@"real name conflict jumpUrl empty!");
            [self notifyWakeVerifyItemFail];
            return;
        }
        [self p_alertRealNameConflictWithUrl:response.jumpUrl];
    }
}

- (void)p_alertRealNameConflictWithUrl:(NSString *)jumpUrl {
    @CJWeakify(self)
    void(^leftActionBlock)(void) = ^() {
        @CJStrongify(self)
        [self p_showPasswordVerifyKeyboard];
        [self event:@"wallet_realname_conflict_click" params:@{@"button_name": @"0"}];
    };
    
    void(^rightActionBlock)(void) = ^() {
        @CJStrongify(self)
        [self gotoWebViewWithUrl:jumpUrl];
        [self event:@"wallet_realname_conflict_click" params:@{@"button_name": @"1"}];
    };
    
    [self event:@"wallet_realname_conflict_imp" params:@{}];
    
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"你在本App中存在不同实名信息，请确认本人实名，并注销非本人实名")
                                 content:nil
                          leftButtonDesc:CJPayLocalizedStr(@"下次再说")
                         rightButtonDesc:CJPayLocalizedStr(@"确认注销")
                         leftActionBlock:leftActionBlock
                         rightActioBlock:rightActionBlock useVC:[self.manager.homePageVC topVC]];
}

- (void)p_showPasswordVerifyKeyboard {
    UIViewController *topVC = [self.manager.homePageVC topVC];
    if ([topVC isKindOfClass:CJPayHalfVerifyPasswordNormalViewController.class]) {
        CJPayHalfVerifyPasswordNormalViewController *vc = (CJPayHalfVerifyPasswordNormalViewController *)topVC;
        [vc showPasswordVerifyKeyboard];
    }
}

- (void)gotoWebViewWithUrl:(NSString *)urlString {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params cj_setObject:@"122" forKey:@"service"];
    [params cj_setObject:@"sdk" forKey:@"source"];
    
    @CJWeakify(self)
    CJPayBizWebViewController *webvc = [[CJPayWebViewUtil sharedUtil] buildWebViewControllerWithUrl:urlString
                                                                                             fromVC:[self.manager.homePageVC topVC]
                                                                                             params:params
                                                                                  nativeStyleParams:@{}
                                                                                      closeCallBack:^(id  _Nonnull data) {
        @CJStrongify(self)
        NSDictionary *resultParam = (NSDictionary *)data;
        NSString *service = [resultParam cj_stringValueForKey:@"service"];
        if (!service || ![service isEqualToString:@"122"]) {
            [self notifyVerifyCancel];
            return;
        }
        
        [self.manager.homePageVC closeActionAfterTime:0
                                            closeActionSource:CJPayHomeVCCloseActionSourceFromCloseAction];
    }];
    
    [self.manager.homePageVC push:webvc animated:YES];
}

- (NSString *)checkTypeName {
    return @"实名冲突";
}

@end
