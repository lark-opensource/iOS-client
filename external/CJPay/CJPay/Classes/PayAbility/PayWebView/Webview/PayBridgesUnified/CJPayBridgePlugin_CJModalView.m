//
//  CJPayBridgePlugin_CJModalView.m
//  CJPay
//
//  Created by liyu on 2020/1/14.
//

#import "CJPayBridgePlugin_CJModalView.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayBizWebViewController+Biz.h"
#import "CJPayWebViewUtil.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayWebviewStyle.h"

@implementation CJPayBridgePlugin_CJModalView

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_CJModalView, CJModalView), @"ttcjpay.CJModalView");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)CJModalViewWithParam:(NSDictionary *)data
                    callback:(TTBridgeCallback)callback
                      engine:(id<TTBridgeEngine>)engine
                  controller:(UIViewController *)controller
{
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }
    
    NSDictionary *dic = (NSDictionary *)data;
    
    if (dic == nil || [dic count] == 0) {
        TTBRIDGE_CALLBACK_FAILED
        return;
    }
    NSString *url = [dic cj_stringValueForKey:@"url"];
    NSInteger fullpage = [dic cj_integerValueForKey:@"fullpage"];
    BOOL animated = [dic cj_integerValueForKey:@"enable_animation"] == 1;
    NSString *colorString = [dic cj_stringValueForKey:@"background_color"];
    CJH5CashDeskStyle style = CJH5CashDeskStyleVertivalHalfScreen;
    if (fullpage == 1) {
        style = CJH5CashDeskStyleVertivalFullScreen;
    } else if (fullpage == 2) {
        style = CJH5CashDeskStyleLandscapeHalfScreen;
    }
    
    // 透明web vc 的转场需要被接管，走有动画的push
    if (style == CJH5CashDeskStyleVertivalHalfScreen || style == CJH5CashDeskStyleLandscapeHalfScreen) {
        animated = YES;
    }
    
    UIColor *color = [CJPayWebviewStyle new].webBcgColor;
    if (Check_ValidString(colorString)) {
        color = [UIColor cj_colorWithHexString:colorString];
    }
    BOOL showLoading = YES;
    if (dic[@"show_loading"]) {
        showLoading = [dic cj_boolValueForKey:@"show_loading"];
    }
    
    [[CJPayWebViewUtil sharedUtil] openH5ModalViewFrom:webViewController
                                                 toUrl:url
                                                 style:style
                                           showLoading:showLoading
                                       backgroundColor:color
                                              animated:animated
                                         closeCallBack:webViewController.closeCallBack];
    TTBRIDGE_CALLBACK_SUCCESS
}

@end
