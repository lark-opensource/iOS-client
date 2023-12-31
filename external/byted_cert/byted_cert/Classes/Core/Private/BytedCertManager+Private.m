//
//  BytedCertManager+Private.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/10.
//

#import "BytedCertManager+Private.h"
#import "BytedCertError.h"
#import "BDCTFaceVerificationFlow.h"
#import "BDCTEventTracker.h"
#import "BDCTFlowContext.h"
#import "BDCTIndicatorView.h"
#import "BDCTAPIService.h"
#import "BDCTAdditions.h"

#import <TTNetworkManager/TTNetworkManager.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <objc/runtime.h>
#import <CoreNFC/CoreNFC.h>


@implementation BytedCertManager (Private)

@dynamic hasInited;
@dynamic useAPIV3;
@dynamic uiConfigBlock;

+ (NSDictionary *)ttnetCommonParams {
    NSDictionary *commonParams;
    TTNetworkManagerCommonParamsBlock commonParamsBlock = [[TTNetworkManager shareInstance] commonParamsblock];
    if (commonParamsBlock) {
        commonParams = commonParamsBlock();
    }
    if (![commonParams isKindOfClass:[NSDictionary class]] || [commonParams count] == 0) {
        commonParams = [[TTNetworkManager shareInstance] commonParams];
    }
    return commonParams;
}

+ (NSString *)aid {
    NSDictionary *commonParams = [self ttnetCommonParams];
    NSString *aid = [commonParams btd_stringValueForKey:@"aid"];
    if (!aid.length) {
        aid = [commonParams btd_stringValueForKey:@"app_id" default:[UIApplication btd_appID]];
    }
    return aid;
}

+ (NSString *)appName {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[self ttnetCommonParams] btd_stringValueForKey:@"app_name" default:[UIApplication btd_appName]];
#pragma clang diagnostic pop
}

+ (BytedCertDeviceNFCStatus)deviceSupportNFC {
    if (@available(iOS 14.5, *)) {
        if (NFCNDEFReaderSession.readingAvailable == YES) {
            return BytedCertDeviceNFCStatusSupport;
        }
    }
    return BytedCertDeviceNFCStatusUnSupport;
}

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static BytedCertManager *bytedCertManager;
    dispatch_once(&onceToken, ^{
        bytedCertManager = [BytedCertManager new];
    });
    return bytedCertManager;
}

- (NSString *)latestTicket {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setLatestTicket:(NSString *)latestTicket {
    objc_setAssociatedObject(self, @selector(latestTicket), latestTicket, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setStatusBarHeight:(CGFloat)statusBarHeight {
    objc_setAssociatedObject(self, @selector(statusBarHeight), [NSNumber numberWithDouble:statusBarHeight], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)statusBarHeight {
    NSNumber *statusBarHeight = objc_getAssociatedObject(self, _cmd);
    return [statusBarHeight doubleValue];
}

- (void)p_beginFaceVerificationWithParameter:(BytedCertParameter *)parameter
                          fromViewController:(UIViewController *)fromViewController
                                forcePresent:(BOOL)forcePresent
                                   suprtFlow:(BDCTFlow *)superFlow
                 shouldBeginFaceVerification:(nullable BOOL (^)(void))shouldBeginFaceVerification
                                  completion:(nullable void (^)(BytedCertError *_Nullable, NSDictionary *_Nullable))completion {
    BDCTFaceVerificationFlow *flow = [[BDCTFaceVerificationFlow alloc] initWithContext:[BDCTFlowContext contextWithParameter:parameter]];
    flow.fromViewController = fromViewController;
    flow.forcePresent = forcePresent;
    flow.superFlow = superFlow;
    flow.shouldPresentHandler = shouldBeginFaceVerification;
    if (superFlow) {
        flow.context.parameter.showAuthError = superFlow.context.parameter.showAuthError;
    }
    [flow setCompletionBlock:^(NSDictionary *_Nullable result, BytedCertError *_Nullable error) {
        !completion ?: completion(error, result);
    }];
    [flow.performance faceDetectOpen];
    [flow begin];
}

- (void)saveStatusBarHeight {
    if (@available(iOS 13.0, *)) {
        UIStatusBarManager *statusBarManager = [[UIApplication.sharedApplication.keyWindow windowScene] statusBarManager];
        self.statusBarHeight = statusBarManager.statusBarFrame.size.height * UIScreen.mainScreen.scale;
    } else {
        self.statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height * UIScreen.mainScreen.scale;
    }
}

@end


@implementation BytedCertManager (PrivateUI)

+ (void)showToastWithText:(NSString *)text type:(BytedCertToastType)type {
    btd_dispatch_async_on_main_queue(^{
        if ([BytedCertManager.delegate respondsToSelector:@selector(bytedCertManager:showToastOnView:text:type:)]) {
            UIWindow.bdct_keyWindow.userInteractionEnabled = (type != BytedCertToastTypeLoading);
            [BytedCertManager.delegate bytedCertManager:BytedCertManager.shareInstance showToastOnView:UIWindow.bdct_keyWindow text:text type:type];
            return;
        }
        if (type == BytedCertToastTypeLoading) {
            [BDCTIndicatorView showWithIndicatorStyle:BytedCertIndicatorViewStyleWaitingView indicatorText:text indicatorImage:nil autoDismiss:NO dismissHandler:nil];
        } else if (type == BytedCertToastTypeNone) {
            [BDCTIndicatorView dismissIndicators];
        } else if (!BTD_isEmptyString(text)) {
            [BDCTIndicatorView showWithIndicatorStyle:BytedCertIndicatorViewStyleImage indicatorText:text indicatorImage:nil autoDismiss:YES dismissHandler:nil];
        }
    });
}

+ (void)showAlertOnViewController:(UIViewController *)viewController title:(NSString *)title message:(NSString *)message actions:(NSArray<BytedCertAlertAction *> *)actions {
    btd_dispatch_async_on_main_queue(^{
        if ([BytedCertManager.delegate respondsToSelector:@selector(bytedCertManager:showAlertOnViewController:title:message:actions:)]) {
            [BytedCertManager.delegate bytedCertManager:BytedCertManager.shareInstance showAlertOnViewController:viewController title:title message:message actions:actions];
            return;
        }
        UIAlertController *alertControlelr = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [actions enumerateObjectsUsingBlock:^(BytedCertAlertAction *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            [alertControlelr addAction:[UIAlertAction actionWithTitle:obj.title style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                                 !obj.handler ?: obj.handler();
                             }]];
        }];
        [viewController presentViewController:alertControlelr animated:YES completion:nil];
    });
}

@end
