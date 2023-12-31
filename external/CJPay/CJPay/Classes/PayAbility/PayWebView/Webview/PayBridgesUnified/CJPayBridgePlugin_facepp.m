//
//  CJPayBridgePlugin_facepp.m
//  Pods
//
//  Created by 尚怀军 on 2021/4/26.
//

#import "CJPayBridgePlugin_facepp.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPaySDKMacro.h"
#import "CJPayBizWebViewController.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_facepp

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_facepp, facepp), @"ttcjpay.facepp");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)faceppWithParam:(NSDictionary *)param
               callback:(TTBridgeCallback)callback
                 engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    
    NSString *url = [param cj_stringValueForKey:@"url"];
    NSString *returnUrl = [param cj_stringValueForKey:@"return_url"] ?: @"https://cjpaysdk/facelive/callback";
    CJPayBizWebViewController *webVC = [[CJPayBizWebViewController alloc] initWithUrlString:url];
    webVC.returnUrl = returnUrl;
    @CJWeakify(webVC);
    webVC.cjBackBlock = ^{  // disbale访问历史，点击back直接关闭
        @CJStrongify(webVC);
        [webVC closeWebVC];
    };
    
    webVC.closeCallBack = ^(id data) {
        NSDictionary *dic = (NSDictionary *)data;
        NSInteger resCode = -1;
        if ([[dic cj_stringValueForKey:@"action"] isEqualToString:@"return_by_url"]) {
            resCode = 0;
        }
        if (callback) {
            callback(TTBridgeMsgSuccess, @{@"code": @(resCode)}, nil);
        }
    };
    UIViewController *topVC = controller ?: [UIViewController cj_topViewController];
    if (topVC.navigationController) {
        [topVC.navigationController pushViewController:webVC animated:YES];
    } else {
        [webVC presentWithNavigationControllerFrom:topVC useMask:NO completion:nil];
    }
}

@end
