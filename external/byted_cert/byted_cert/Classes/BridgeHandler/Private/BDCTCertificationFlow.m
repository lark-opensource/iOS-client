//
//  BDCTCertificationFlow.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/22.
//

#import "BDCTCertificationFlow.h"
#import "BytedCertManager+Private.h"
#import "BDCTCorePiperHandler.h"
#import "BDCTAPIService.h"
#import "BDCTEventTracker.h"
#import "BDCTFlowContext.h"
#import "BDCTLocalization.h"
#import "BytedCertWebView+Private.h"
#import "BDCTDisablePanGestureViewController.h"
#import "BytedCertManager.h"
#import "UIViewController+BDCTAdditions.h"
#import <objc/runtime.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <ByteDanceKit/BTDMacros.h>

static NSString *const kBDCTCertificationFlowAssociatedKey;


@interface BDCTCertificationFlow ()

@property (nonatomic, weak) UIViewController *webViewController;
@property (nonatomic, assign) BOOL isFinished;

@end


@implementation BDCTCertificationFlow

- (instancetype)initWithContext:(BDCTFlowContext *)context {
    self = [super initWithContext:context];
    if (self) {
        self.disableInteractivePopGesture = YES;
    }
    return self;
}

- (void)begin {
    [self.performance flowStart];
    BDCTShowLoading;
    [self.apiService bytedInitWithCallback:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        BDCTDismissLoading;
        [self.eventTracker trackAuthVerifyStart];
        if (!jsonObj || error) {
            NSMutableDictionary *mutableParams = [[NSMutableDictionary alloc] init];
            if (jsonObj.count) {
                [mutableParams setValue:jsonObj[@"status_code"] forKey:@"error_code"];
                [mutableParams setValue:jsonObj[@"message"] forKey:@"error_msg"];
            }
            if (!mutableParams.count && error) {
                [mutableParams setValue:@(error.errorCode) forKey:@"error_code"];
                [mutableParams setValue:error.errorMessage forKey:@"error_msg"];
            }
            [self finishWithResult:mutableParams.copy progressType:self.context.parameter.mode showAlert:YES];
        } else {
            NSString *url = [[jsonObj btd_dictionaryValueForKey:@"data"] btd_stringValueForKey:@"entry_page_address"];
            [self.performance webviewStartLoad];
            [self openCertificationUrl:url];
        }
    }];
}

- (void)openCertificationUrl:(NSString *)urlString {
    BDCTWebView *webview = [BDCTWebView webView];
    webview.corePiperHandler.flow = self;

    BDCTDisablePanGestureViewController *webViewController = [[BDCTDisablePanGestureViewController alloc] init];
    webViewController.disablePodGesture = YES;
    [webViewController.view setBackgroundColor:[UIColor whiteColor]];
    webViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [webViewController.view addSubview:webview];
    webViewController.bdct_flow = self;
    self.webViewController = webViewController;

    [self showViewController:webViewController];

    NSURL *URL = [[NSURL btd_URLWithString:urlString] btd_URLByMergingQueries:(self.context.parameter.h5QueryParams ?: @{})];
    [webview loadURL:URL];
}
- (void)finishFlowWithParams:(NSDictionary *)params progressType:(NSUInteger)progressType {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.webViewController bdct_dismissWithComplation:^{
            [self finishWithResult:params progressType:progressType];
        }];
    });
}

- (void)finishWithResult:(NSDictionary *)result progressType:(BytedCertProgressType)progressType {
    self.isFinished = YES;
    [self.performance flowEnd];
    void (^completion)(NSError *, NSDictionary *) = self.completionBlock;
    NSError *error;
    NSMutableDictionary *mutableResult = [NSMutableDictionary dictionaryWithDictionary:result];
    NSString *errorMsg = [mutableResult btd_stringValueForKey:@"error_msg"];
    if (![errorMsg isEqualToString:@"certificate_success"]) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : (errorMsg ?: @"")};
        NSInteger errorCode = [result btd_integerValueForKey:@"error_code"];
        error = [NSError errorWithDomain:BytedCertManagerErrorDomain code:errorCode userInfo:userInfo];
    }
    [mutableResult btd_setObject:self.context.certResult forKey:@"cert_result"];
    [mutableResult btd_setObject:self.context.parameter.ticket forKey:@"ticket"];
    [self.eventTracker trackAuthVerifyEndWithErrorCode:(int)error.code errorMsg:(error == nil ? nil : errorMsg) result:result.copy];
    btd_dispatch_async_on_main_queue(^{
        if (completion != nil) {
            completion(error, mutableResult.copy);
        }

        NSArray *progressDelegates = [[BytedCertInterface sharedInstance] progressDelegateArray];
        if ([[BytedCertInterface sharedInstance].bytedCertProgressDelegate respondsToSelector:@selector(progressFinishWithType:params:)] || progressDelegates) {
            if (!BTD_isEmptyDictionary(result)) {
                if ([[BytedCertInterface sharedInstance].bytedCertProgressDelegate respondsToSelector:@selector(progressFinishWithType:params:)]) {
                    [[BytedCertInterface sharedInstance].bytedCertProgressDelegate progressFinishWithType:progressType params:result];
                }
                [progressDelegates enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                    id<BytedCertProgressDelegate> progressDelegateObj = obj;
                    if (progressDelegateObj && [progressDelegateObj respondsToSelector:@selector(progressFinishWithType:params:)]) {
                        [progressDelegateObj progressFinishWithType:progressType params:result];
                    }
                }];
            }
        } else if ([[BytedCertInterface sharedInstance].bytedCertOnH5CloseDelegate respondsToSelector:@selector(closeResult:)]) {
            if (!BTD_isEmptyDictionary(result)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [[BytedCertInterface sharedInstance].bytedCertOnH5CloseDelegate closeResult:result];
#pragma clang diagnostic pop
            }
        }
    });
}
- (void)finishWithResult:(NSDictionary *)result progressType:(BytedCertProgressType)progressType showAlert:(BOOL)showAlert {
    if (showAlert && self.context.parameter.showAuthError) {
        [BytedCertManager showAlertOnViewController:BTDResponder.topViewController title:nil message:result[@"error_msg"] ?: @"网络错误" actions:@[
            [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeDefault title:@"确认" handler:^{
                [self finishWithResult:result progressType:progressType];
            }]
        ]];
    } else {
        [self finishWithResult:result progressType:progressType];
    }
}
- (void)dealloc {
    if (!self.isFinished) {
        [self finishWithResult:@{@"error_code" : @"0",
                                 @"error_msg" : @"close_webview",
                                 @"ext_data" : @{
                                     @"mode" : @(self.context.parameter.mode),
                                     @"ticket" : (self.context.parameter.ticket ?: @"")
                                 }}
                  progressType:self.context.parameter.mode];
    }
}

@end
