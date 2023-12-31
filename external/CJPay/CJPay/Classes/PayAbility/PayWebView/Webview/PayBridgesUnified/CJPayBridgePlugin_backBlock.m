//
//  CJPayBridgePlugin_backBlock.m
//  CJPay
//
//  Created by liyu on 2020/1/15.
//

#import "CJPayBridgePlugin_backBlock.h"

#import <TTBridgeUnify/TTBridgeRegister.h>
#import <WebKit/WKWebView.h>
#import "CJPayBizWebViewController.h"
#import "CJPayBackBlockModel.h"
#import "CJPayAlertController.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayWKWebView.h"

typedef NS_ENUM(NSUInteger, CJBackBlockPolicy) {
    kCJBackBlockPolicyAlways = 0,
    kCJBackBlockPolicyOnce,
    kCJBackBlockPolicyDisabled,
};

typedef NS_ENUM(NSUInteger, CJBackBlockActionType) {
    kCJBackBlockActionDismissAlert = 0,
    kCJBackBlockActionClosePage,
};

@implementation CJPayBridgePlugin_backBlock

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_backBlock, backBlock), @"ttcjpay.backBlock");
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_backBlock, blockNativeBack), @"ttcjpay.blockNativeBack");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)backBlockWithParam:(NSDictionary *)data
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
    if (dic == nil) {
        webViewController.cjBackBlock = nil;
        TTBRIDGE_CALLBACK_SUCCESS
        return;
    }
    
    NSError *error = nil;
    CJPayBackBlockModel *model = [[CJPayBackBlockModel alloc] initWithDictionary:dic error:&error];
    if (error) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"参数解析异常")
        return;
    }
    
    if (model.policy == kCJBackBlockPolicyDisabled) {
        webViewController.cjBackBlock = nil;
        TTBRIDGE_CALLBACK_SUCCESS
        return;
    }
    
    if (!Check_ValidString(model.title)
        || !Check_ValidString(model.cancelModel.title)
        || !Check_ValidString(model.confirmModel.title)) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"参数异常")
        return;
    }

    @CJWeakify(webViewController)
    @CJWeakify(self)
    webViewController.cjBackBlock = ^{
        @CJStrongify(webViewController)
        [weak_self callJSEvent:@"click.backbutton"];
        
        CJPayAlertController *alertController
        = [CJPayAlertController alertControllerWithTitle:CJString(model.title)
                                                 message:CJString(model.context)
                                          preferredStyle:UIAlertControllerStyleAlert];
        
        void (^closePageActionBlock)(NSString *) = ^(NSString *eventName) {
            @CJStrongify(webViewController)
            [weak_self callJSEvent:eventName];
            
            if ([webViewController canGoBack]) {
                [webViewController goBack];
                return;
            }
            [webViewController closeWebVC];
        };
        
        void (^dismissAlertActionBlock)(NSString *) = ^(NSString *eventName) {
            @CJStrongify(webViewController)
            [weak_self callJSEvent:eventName];

            if (model.policy == kCJBackBlockPolicyOnce) {
                webViewController.cjBackBlock = nil;
            }
        };

        
        UIAlertAction *leftAction = [UIAlertAction actionWithTitle:CJString(model.cancelModel.title)
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * _Nonnull action) {
            if (model.cancelModel.action == kCJBackBlockActionClosePage) {
                CJ_CALL_BLOCK(closePageActionBlock,@"click.blockcancel");
            } else {
                CJ_CALL_BLOCK(dismissAlertActionBlock, @"click.blockcancel");
            }
        }];

        UIAlertAction *rightAction = [UIAlertAction actionWithTitle:CJString(model.confirmModel.title)
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
            if (model.confirmModel.action == kCJBackBlockActionClosePage) {
                CJ_CALL_BLOCK(closePageActionBlock, @"click.blockconfirm");
            } else {
                CJ_CALL_BLOCK(dismissAlertActionBlock, @"click.blockconfirm");
            }
        }];
        [alertController addAction:leftAction];
        [alertController addAction:rightAction];
        
        if ([model.confirmModel.fontWeight isEqualToString:@"1"]) {
            if (@available(iOS 9.0, *)) {
                alertController.preferredAction = rightAction;
            }
        }
            
        if ([model.cancelModel.fontWeight isEqualToString:@"1"]) {
            if (@available(iOS 9.0, *)) {
                alertController.preferredAction = leftAction;
            }
        }
        
        [webViewController presentViewController:alertController animated:YES completion:nil];

    };
    TTBRIDGE_CALLBACK_SUCCESS;
}

- (void)blockNativeBackWithParam:(NSDictionary *)data
                        callback:(TTBridgeCallback)callback
                          engine:(id<TTBridgeEngine>)engine
                      controller:(UIViewController *)controller {
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }
    
    webViewController.cjBackBlock = ^{
        // just a non-null block without any procedure.
        // particularly, the method -[webViewController closeWebVC] is forbidden to be called.
    };
}

- (void)callJSEvent:(NSString *)event
{
    NSDictionary *params = @{@"type": CJString(event), @"data": @""};
    [self.engine fireEvent:@"ttcjpay.receiveSDKNotification" params:params];
}

@end
