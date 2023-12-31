//
//  CJPayBizWebViewController+Biz.m
//  CJPay
//
//  Created by 王新华 on 10/15/19.
//

#import "CJPayBizWebViewController+Biz.h"
#import "CJPayWebviewStyle.h"
#import <objc/runtime.h>

@implementation CJPayBizWebViewController(Biz)

+ (CJPayBizWebViewController *)buildWebBizVC:(CJH5CashDeskStyle)cashDeskStyle
                                    finalUrl:(NSString *)finalUrl
                                  completion:(void(^)(id))closeCallBack {
    CJPayBizWebViewController *vc = [[CJPayBizWebViewController alloc] initWithUrlString:finalUrl];
    // 设置webview样式,全屏采用有导航条的默认样式，半屏设置成全透明webview
    if (cashDeskStyle == CJH5CashDeskStyleVertivalFullScreen) {
        vc.webviewStyle.hidesNavbar = YES;
        vc.webviewStyle.hidesBackButton = YES;
        vc.webviewStyle.needFullScreen = YES;
        vc.webviewStyle.bounceEnable = NO;
    } else {
        vc.webviewStyle.containerBcgColor = [UIColor clearColor];
        vc.webviewStyle.webBcgColor = [UIColor clearColor];
        vc.webviewStyle.hidesNavbar = YES;
        vc.webviewStyle.hidesBackButton = YES;
        vc.webviewStyle.bounceEnable = NO;
        vc.webviewStyle.needFullScreen = YES;
        if (cashDeskStyle == CJH5CashDeskStyleLandscapeHalfScreen) {
            vc.webviewStyle.isLandScape = YES;
        }
    }
    
    // 设置回调block，h5关闭收银台时，将支付结果回调给业务方
    vc.closeCallBack = closeCallBack;
    return vc;
}

@end
