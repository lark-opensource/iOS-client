//
//  CJPayBankCardHeaderSafeBannerViewModel.m
//  Pods
//
//  Created by 孔伊宁 on 2021/8/11.
//

#import "CJPayBankCardHeaderSafeBannerViewModel.h"
#import "CJPayBankCardHeaderSafeBannerCellView.h"
#import "CJPayWebViewUtil.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBankCardHeaderSafeBannerViewModel

- (Class)getViewClass {
    return [CJPayBankCardHeaderSafeBannerCellView class];
}

- (CGFloat)getViewHeight {
    return 32;
}

- (void)gotoH5WebView {
    static NSString *const url = @"sslocal://cjpay/webview?url=https%3a%2f%2fcashier.ulpay.com%2fusercenter%2finsurance&canvas_mode=1&status_bar_text_style=dark";

    if (!Check_ValidString(url)) {
        return;
    }

    NSMutableDictionary *schemeDic = [[CJPayCommonUtil parseScheme:url] mutableCopy];
    NSDictionary *urlParamsDic = @{
        @"app_id" : CJString([self.passParams cj_stringValueForKey:@"app_id"]),
        @"merchant_id" : CJString([self.passParams cj_stringValueForKey:@"merchant_id"]),
        @"extra_query" : CJString([self.passParams cj_stringValueForKey:@"extra_query"])
    };

    NSString *urlWithParams = [CJPayCommonUtil appendParamsToUrl:[schemeDic cj_stringValueForKey:@"url"] params:urlParamsDic];
    [schemeDic cj_setObject:[urlWithParams cj_URLEncode] forKey:@"url"];

    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_topViewController] toUrl:[CJPayCommonUtil generateScheme:schemeDic] params:@{} closeCallBack:nil];
}

@end
