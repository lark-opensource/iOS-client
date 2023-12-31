//
//  CJPayBridgePlugin_requestWXH5Payment.m
//  CJPay
//
//  Created by liyu on 2020/2/16.
//

#import "CJPayBridgePlugin_requestWXH5Payment.h"
#import "CJPayUIMacro.h"

#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayChannelManagerModule.h"
#import "CJPayProtocolManager.h"
#import "CJPayPrivacyMethodUtil.h"
#import <WebKit/WKWebView.h>
#import <WebKit/WKNavigationDelegate.h>
#import <WebKit/WKNavigationAction.h>
#import "CJPayBridgeBlockRegister.h"

@interface CJPayBridgePlugin_requestWXH5Payment () <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, copy) TTBridgeCallback bridgeCallback;
@property (nonatomic, weak) TTBridgeCommand *command;
@property (nonatomic, assign) BOOL hasOpenWXSchema;

@end


@implementation CJPayBridgePlugin_requestWXH5Payment

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    NSString *brdigeName = @"ttcjpay.requestWXH5Payment"; //ttcjpay.requestWXH5Payment
    //BPEA跨端改造，使用block方式注册"ttcjpay.requestWXH5Payment"的jsb
    [CJPayBridgeBlockRegister registerBridgeName:brdigeName
                                      engineType:TTBridgeRegisterAll
                                        authType:TTBridgeAuthProtected
                                         domains:nil
                               needBridgeCommand:YES
                                         handler:^(NSDictionary * _Nullable params, TTBridgeCallback callback, id<TTBridgeEngine> engine, UIViewController * _Nullable controller, TTBridgeCommand * _Nullable command) {
        
        TTBridgePlugin *pluginRequestWXH5Payment = [CJPayBridgeBlockRegister associatedPluginsOnEngine:engine pluginClassName:NSStringFromClass(self)];
        if ([pluginRequestWXH5Payment isKindOfClass:CJPayBridgePlugin_requestWXH5Payment.class]) {
            [(CJPayBridgePlugin_requestWXH5Payment *)pluginRequestWXH5Payment requestWXH5PaymentWithParam:params callback:callback engine:engine controller:controller command:command];
        } else {
            CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"data 格式不正确",@"raw_code":@""}, nil);
        }
    }];
}

- (void)requestWXH5PaymentWithParam:(NSDictionary *)param
                           callback:(TTBridgeCallback)callback
                             engine:(id<TTBridgeEngine>)engine
                         controller:(UIViewController *)controller
                            command:(TTBridgeCommand *)command
{
    NSDictionary *dic = (NSDictionary *)param;
    self.command = command;
    if (dic && [dic isKindOfClass:NSDictionary.class]) {
        NSString *weBayUrl = [dic cj_stringValueForKey:@"url"];
        CJ_DECLARE_ID_PROTOCOL(CJPayChannelManagerModule);
        NSString *nativeReferSchema = [objectWithCJPayChannelManagerModule i_wxH5PayReferUrlStr];
        if (!Check_ValidString(nativeReferSchema)) {
            CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"未配置微信的referurl",@"raw_code":@""}, nil);
            CJPayLogAssert(NO, @"未配置微信的referurl, [CJPayChannelManager sharedInstance].h5PayReferUrl");
            return;
        }
        // 预备好回调
        [objectWithCJPayChannelManagerModule i_payActionWithChannel:CJPayChannelTypeCustom dataDict:@{} completionBlock:^(CJPayChannelType channelType, CJPayResultType resultType, NSString *errCode) {
            switch (resultType) {
                case CJPayResultTypeSuccess:
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"0", @"msg": @"支付成功", @"raw_code":CJString(errCode)}, nil);
                    break;
                case CJPayResultTypeCancel:
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"2", @"msg": @"支付取消",@"raw_code":CJString(errCode)}, nil);
                    break;
                case CJPayResultTypeUnInstall:
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"3", @"msg": @"未安装微信",@"raw_code":CJString(errCode)}, nil);
                    break;
                case CJPayResultTypeProcessing:
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"5", @"msg": @"支付处理中",@"raw_code":CJString(errCode)}, nil);
                    break;
                case CJPayResultTypeBackToForeground:
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"6", @"msg": @"支付结果未知：用户手动切换App",@"raw_code":CJString(errCode)}, nil);
                    break;
                default:
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"支付失败",@"raw_code":CJString(errCode)}, nil);
                    break;
            }
        }];
        NSMutableURLRequest *weBayRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:weBayUrl]];
        NSMutableDictionary *httpField = [NSMutableDictionary new];
        httpField[@"Referer"] = nativeReferSchema;
        weBayRequest.allHTTPHeaderFields = httpField;
        self.webView = [WKWebView new];
        self.webView.navigationDelegate = self;
        [self.webView loadRequest:weBayRequest];
        [self p_delayDetectWXOpenStatus];
    } else {
        CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": @"data 格式不正确",@"raw_code":@""}, nil);
    }

}

- (void)p_delayDetectWXOpenStatus {
    self.hasOpenWXSchema = NO;
    @CJWeakify(self)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self)
        if (!self.hasOpenWXSchema) {
            [CJMonitor trackService:@"wallet_rd_wxh5_pay_fail"
                           category:@{}
                              extra:@{}];
        }
    });
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *absoluteString = [navigationAction.request.URL.absoluteString stringByRemovingPercentEncoding];
    //拦截重定向的跳转微信的 URL Scheme, 打开微信
    if ([absoluteString hasPrefix:@"weixin://"]) {
        CJ_CALL_BLOCK(decisionHandler, WKNavigationActionPolicyCancel);
        NSURL *wxURL = [navigationAction.request.URL copy];
        @CJWeakify(self)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([[UIApplication sharedApplication] canOpenURL:wxURL]) {
                // 调用AppJump敏感方法，需走BPEA鉴权
                @CJStrongify(self)
                self.hasOpenWXSchema = YES;
                [CJPayPrivacyMethodUtil applicationOpenUrl:wxURL
                                                withPolicy:@"bpea-caijing_jsb_open_weixin_h5"
                                             bridgeCommand:self.command
                                                   options:@{}
                                         completionHandler:^(BOOL success, NSError * _Nullable error) {
                    
                    if (error) {
                        CJPayLogError(@"error in bpea-caijing_jsb_open_weixin_h5");
                    }
                }];
            }
        });
        return;
    }
    CJ_CALL_BLOCK(decisionHandler, WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    CJ_CALL_BLOCK(self.bridgeCallback, TTBridgeMsgSuccess, @{@"code": @"1", @"msg": error.description ?: @""}, nil);
}

- (void)dealloc
{
    self.webView = nil;
}

@end
