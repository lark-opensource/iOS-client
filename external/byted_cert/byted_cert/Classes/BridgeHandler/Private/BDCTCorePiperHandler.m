//
//  BytedCertCorePiperHandler.m
//  BytedCertDemo
//
//  Created by LiuChundian on 2019/6/2.
//  Copyright © 2019年 Bytedance Inc. All rights reserved.
//
#import "BDCTCorePiperHandler.h"
#import "BDCTCorePiperHandler+LivenessDetect.h"
#import "BDCTCorePiperHandler+Network.h"
#import "BDCTCorePiperHandler+OCR.h"
#import "BDCTCorePiperHandler+EventLog.h"
#import "BDCTCorePiperHandler+ViewUtils.h"
#import "BytedCertWrapper.h"
#import "BDCTImageManager.h"
#import "BDCTAPIService.h"
#import "BDCTWebViewController.h"
#import "BytedCertInterface.h"
#import "BytedCertManager+Private.h"
#import "BytedCertManager+Piper.h"
#import "BDCTIndicatorView.h"
#import "BDCTEventTracker.h"
#import "BDCTLocalization.h"
#import "BDCTWebView.h"
#import "BDCTLog.h"
#import "UIViewController+BDCTAdditions.h"
#import <objc/runtime.h>
#import <TTBridgeUnify/TTBridgeAuthManager.h>
#import <TTBridgeUnify/TTWebViewBridgeEngine.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <TTBridgeUnify/BDUnifiedWebViewBridgeEngine.h>
#import <BDAssert/BDAssert.h>


@interface BDCTCorePiperHandler () <WKNavigationDelegate, UIScrollViewDelegate>

@property (nonatomic, strong, readwrite) BDCTImageManager *imageManager;

@property (nonatomic, weak) WKWebView *webView;

@end


@implementation BDCTCorePiperHandler

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    scrollView.contentOffset = CGPointZero;
}

- (BDCTImageManager *)imageManager {
    if (!_imageManager) {
        _imageManager = [BDCTImageManager new];
        _imageManager.flow = self.flow;
    }
    return _imageManager;
}

- (void)registerHandlerWithWebView:(WKWebView *)webView {
    self.webView = webView;
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList([BDCTCorePiperHandler class], &methodCount);
    for (int i = 0; i < methodCount; i++) {
        Method temp = methodList[i];
        SEL selector = method_getName(temp);
        int argumentsCount = method_getNumberOfArguments(temp);
        if ([NSStringFromSelector(selector) hasPrefix:@"register"] && argumentsCount == 2) {
            IMP imp = [self methodForSelector:selector];
            void (*func)(id, SEL) = (void *)imp;
            func(self, selector);
        }
    }
    free(methodList);
}

- (void)registeJSBWithName:(NSString *)name handler:(TTBridgeHandler)handler {
    [self.webView.tt_engine.bridgeRegister registerBridge:^(TTBridgeRegisterMaker *_Nonnull maker) {
        maker.bridgeName(name).handler(handler);
    }];
}

- (void)registerOpenPage {
    [self registeJSBWithName:@"bytedcert.openPage" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        UIViewController *topViewController = [UIViewController bdct_topViewController];
        if (topViewController.navigationController) {
            BDCTWebViewController *popView = [[BDCTWebViewController alloc] initWithUrl:params[@"url"] title:params[@"title"]];
            [topViewController.navigationController pushViewController:popView animated:YES];
        } else {
            CGSize size = [UIScreen.mainScreen bounds].size;

            WKWebView *webview = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
            [webview loadRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:params[@"url"]]]];
            webview.opaque = NO;
            webview.backgroundColor = [UIColor whiteColor];
            webview.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 30, 0);

            UIViewController *webViewController = [[UIViewController alloc] init];
            webViewController.edgesForExtendedLayout = UIRectEdgeNone;
            [webViewController.view addSubview:webview];

            BDCTPortraitNavigationController *popNav = [[BDCTPortraitNavigationController alloc] initWithRootViewController:webViewController];
            [popNav setTitle:params[@"title"]];
            [topViewController showViewController:popNav sender:nil];
        }
    }];
}

- (void)registerClosePage {
    [self registeJSBWithName:@"bytedcert.closePage" handler:^(NSDictionary *_Nullable piperParams, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        NSDictionary *data = [piperParams btd_dictionaryValueForKey:@"data"];
        BytedCertProgressType progressType = BytedCertProgressTypeIdentityAuth;
        if ([[data btd_dictionaryValueForKey:BytedCertJSBParamsExtData] btd_intValueForKey:BytedCertParamMode] == BytedCertProgressTypeIdentityVerify) {
            progressType = BytedCertProgressTypeIdentityVerify;
        }
        NSNumber *step = [data btd_numberValueForKey:@"step" default:nil];
        NSMutableDictionary *result = data.mutableCopy;
        BDCTFlow *currentFlow = self.flow;
        if (step) {
            int closingFlows = step.intValue;
            [result removeObjectForKey:@"step"];
            if (closingFlows == 0) { //closingFlows ==0 关闭所有前端页面以及flow
                while (currentFlow.superFlow) {
                    currentFlow = currentFlow.superFlow;
                }
            } else if (closingFlows > 1) { //需要关闭的页面以及flow
                for (int i = 1; i < closingFlows; i++) {
                    currentFlow = currentFlow.superFlow;
                }
            }
            currentFlow.context.certResult = self.flow.context.certResult;
        }
        if ([currentFlow isKindOfClass:[BDCTCertificationFlow class]]) {
            [(BDCTCertificationFlow *)currentFlow finishFlowWithParams:result.copy progressType:progressType];
        } else {
            BDAssert(NO, @"flow should be kind of BDCTCertificationFlow");
        }
    }];
}

- (void)registerOpenLoginPage {
    [self registeJSBWithName:@"bytedcert.openLoginPage" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        BDCTLogInfo(@"New event comes from H5: %@", params);
        BytedCertInterface *bytedIf = [BytedCertInterface sharedInstance];
        if (bytedIf.bytedCertProgressDelegate && [bytedIf.bytedCertProgressDelegate respondsToSelector:@selector(openLoginPage)]) {
            [bytedIf.bytedCertProgressDelegate openLoginPage];
        }
        callback(TTBridgeMsgSuccess, nil, nil);
    }];
}

- (void)registerlaunchFlow {
    [self registeJSBWithName:@"bytedcert.launchFlow" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        BytedCertParameter *parameter = [[BytedCertParameter alloc] initWithBaseParams:params identityParams:nil];
        [[BytedCertManager shareInstance] beginAuthorizationWithParameter:parameter fromViewController:nil forcePresent:NO superFlow:self.flow completion:^(NSError *_Nullable error, NSDictionary *_Nullable result) {
            callback(TTBridgeMsgSuccess, result, nil);
        }];
    }];
}

+ (NSDictionary *)jsbCallbackResultWithParams:(NSDictionary *)params error:(BytedCertError *)error {
    NSMutableDictionary *statusResult = [NSMutableDictionary dictionary];
    statusResult[@"status_code"] = @(0);
    if (error) {
        [statusResult setValue:@(error.errorCode) forKey:@"status_code"];
        [statusResult setValue:error.errorMessage forKey:@"description"];
        [statusResult setValue:@(error.detailErrorCode) forKey:@"detail_error_code"];
        [statusResult setValue:error.detailErrorMessage forKey:@"detail_error_message"];
    }

    NSMutableDictionary *realJsbResult = [NSMutableDictionary dictionary];
    [realJsbResult addEntriesFromDictionary:statusResult.copy];
    if (!BTD_isEmptyDictionary(params)) {
        [realJsbResult addEntriesFromDictionary:params];
    }

    NSMutableDictionary *finalResult = [NSMutableDictionary dictionary];
    [finalResult addEntriesFromDictionary:[realJsbResult copy]];
    finalResult[@"byted_cert_data"] = [realJsbResult copy];
    finalResult[@"data"] = ({
        NSMutableDictionary *mutableData = [[realJsbResult btd_dictionaryValueForKey:@"data"] mutableCopy] ?: [NSMutableDictionary dictionary];
        [mutableData addEntriesFromDictionary:realJsbResult.copy];
        [mutableData copy];
    });
    finalResult[@"raw_data"] = params;
    return [finalResult copy];
}

- (void)fireEvent:(TTBridgeName)eventName params:(NSDictionary *)params {
    [self.webView.tt_engine fireEvent:eventName params:params];
}

@end
