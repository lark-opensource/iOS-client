//
//  BDAccountSealView.m
//  BDTuring
//
//  Created by bob on 2020/2/27.
//

#import "BDAccountSealView.h"
#import "BDTuringMacro.h"
#import "BDTuringPiper.h"
#import "WKWebView+Piper.h"
#import "BDAccountSealConstant.h"
#import "BDTuringConfig+AccountSeal.h"
#import "BDAccountSealModel.h"
#import "BDAccountSealResult+Creator.h"
#import "BDAccountSealDefine.h"

#import "BDTuringUtility.h"
#import "NSDictionary+BDTuring.h"
#import "NSString+BDTuring.h"
#import "BDAccountSealEvent.h"
#import "BDAccountSealer.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringServiceCenter.h"
#import "BDTuringService.h"
#import "BDTuringPresentView.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringSettings.h"
#import "BDTNetworkManager.h"
#import "BDTuringServiceCenter.h"
#import "NSData+BDTuring.h"
#import "BDTuringIdentityResult.h"
#import "BDTuringIdentityModel.h"
#import "BDTuringUIHelper.h"
#import "BDTuringUIHandler.h"
#import "BDTuringAlertOption+Creator.h"
#import "BDTuringParameterVerifyModel.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringVerifyResult.h"
#import "BDTuringVerifyState.h"

@interface BDAccountSealView ()

@end

@implementation BDAccountSealView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self loadWebView];
        BDTuringPiper *piper = self.webView.turing_piper;
        BDTuringWeakSelf;
        [piper on:BDAccountSealPiperNameOnResult callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
            BDTuringStrongSelf;
            [self handlePiperOnResult:params callback:callback];
        }];
        
        [piper on:BDAccountSealPiperNameGetData callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
            BDTuringStrongSelf;
            [self handlePiperGetData:params callback:callback];
        }];
        
        [piper on:BDAccountSealPiperNamePageEnd callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
            BDTuringStrongSelf;
            [self handlePiperPageEnd:params callback:callback];
        }];
        
        [piper on:BDAccountSealPiperNameShowAlert callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
            BDTuringStrongSelf;
            [self handlePiperShowAlert:params callback:callback];
        }];
        
        [piper on:BDAccountSealPiperNameVerify callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
            BDTuringStrongSelf;
            [self handlePiperVerify:params callback:callback];
        }];
        
        [piper on:BDAccountSealPiperNameToPage callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
            BDTuringStrongSelf;
            [self handlePiperToPage:params callback:callback];
        }];
        
        [piper on:BDAccountSealPiperNameShow callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
            BDTuringStrongSelf;
            [self handlePiperShow:params callback:callback];
        }];
        
        [piper on:BDAccountSealPiperNameThemeSettings callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
            BDTuringStrongSelf;
            [self handlePiperTheme:params callback:callback];
        }];
        
        [piper on:BDAccountSealPiperNameEventToNative callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
            BDTuringStrongSelf;
            [self handleNativeEventUpload:params callback:callback];
        }];
        
        [self.webView onNetworkPiperName:BDAccountSealPiperNameNetwork];
    }
    
    return self;
}

#pragma mark - Piper

- (void)handleNativeEventUpload:(NSDictionary *)event
                       callback:(BDTuringPiperOnCallback)callback {
    NSString *eventName = [event turing_stringValueForKey:kBDTuringEvent];
    if (callback) callback(BDTuringPiperMsgSuccess, nil);
    [[BDAccountSealEvent sharedInstance] collectEvent:eventName data:event];
}

- (void)handlePiperTheme:(NSDictionary *)params
                   callback:(BDTuringPiperOnCallback)callback {
    if (callback == nil) {
        return;
    }
    
    NSMutableDictionary *response = [NSMutableDictionary new];
    NSDictionary *theme = [[BDTuringUIHelper sharedInstance].sealThemeDictionary copy];
    if (BDTuring_isValidDictionary(theme)) {
        [response setValue:theme forKey:kBDTuringCustomTheme];
    }
    NSDictionary *text = [[BDTuringUIHelper sharedInstance].sealTextDictionary copy];
    if (BDTuring_isValidDictionary(text)) {
        [response setValue:text forKey:kBDTuringCustomText];
    }
    
    callback(BDTuringPiperMsgSuccess, response);
}

- (void)handlePiperShow:(NSDictionary *)params
                  callback:(BDTuringPiperOnCallback)callback {
    [BDTuringUIHelper sharedInstance].isShowAlert = NO;
    self.webView.hidden = NO;
    self.webView.alpha = 0;
    [self stopLoadingView];
    CGRect frame = self.webView.frame;
    [UIView animateWithDuration:0.28
                     animations:^{
        self.webView.alpha = 1;
        self.webView.frame =  CGRectOffset(frame, -frame.size.width, 0);
    } completion:^(BOOL finished) {
        self.webView.alpha = 1;
        self.webView.frame =  CGRectOffset(frame, -frame.size.width, 0);
    }];
}

- (void)handlePiperToPage:(NSDictionary *)params
                    callback:(BDTuringPiperOnCallback)callback {
    BDAccountSealNavigateBlock navigate = self.model.navigate;
    BDTuringPiperMsg msg = BDTuringPiperMsgSuccess;
    if (navigate == nil) {
        msg = BDTuringPiperMsgFailed;
    }
    if (callback) {
        callback(msg, nil);
    }
    if (navigate == nil) {
        return;
    }
    NSString *type = [params turing_stringValueForKey:@"page_type"];
    UINavigationController *navigationController = [self controller].navigationController;
    if ([type.lowercaseString isEqualToString:@"policy"]) {
        navigate(BDAccountSealNavigatePagePolicy, type, navigationController);
    } else if ([type.lowercaseString isEqualToString:@"community"]) {
        navigate(BDAccountSealNavigatePageCommunity, type, navigationController);
    } else {
        navigate(BDAccountSealNavigatePageUnknown, type, navigationController);
    }
}

- (void)handlePiperGetData:(NSDictionary *)params
                     callback:(BDTuringPiperOnCallback)callback {
    NSDictionary *response = @{kBDTuringVerifyParamData    :@[]};
    if (callback) callback(BDTuringPiperMsgSuccess, response);
}

- (void)handlePiperOnResult:(NSDictionary *)params
                      callback:(BDTuringPiperOnCallback)callback {
    [self hideVerifyView];
    
    
    BDAccountSealResultCode resultCode = [params turing_integerValueForKey:kBDTuringErrorCode];
    NSDictionary *data = [params turing_dictionaryValueForKey:kBDTuringVerifyParamData];
    NSString *message = [data turing_stringValueForKey:@"message"];
    NSInteger statusCode = [data turing_integerValueForKey:kBDTuringStatusCode];
    
    BDAccountSealResult *result = [BDAccountSealResult new];
    result.resultCode = resultCode;
    result.statusCode = statusCode;
    result.message = message;
    result.extraData = data;
    
    [self.model handleResult:result];
    
    NSMutableDictionary *param = [NSMutableDictionary new];
    long long duration = CFAbsoluteTimeGetCurrent() * 1000 - self.startLoadTime;
    [param setValue:@(duration) forKey:kBDTuringDuration];
    [param setValue:@(resultCode) forKey:kBDTuringVerifyParamResult];
    [param setValue:@(statusCode) forKey:kBDTuringStatusCode];
    [[BDAccountSealEvent sharedInstance] collectEvent:BDAccountSealEventResult
                                                data:param];
    
    if (callback) callback(BDTuringPiperMsgSuccess, nil);
}

- (void)handlePiperPageEnd:(NSDictionary *)params
                     callback:(BDTuringPiperOnCallback)callback {
    [self dismissVerifyView];
    if (callback) callback(BDTuringPiperMsgSuccess, nil);
}

- (void)handlePiperShowAlert:(NSDictionary *)params
                       callback:(BDTuringPiperOnCallback)callback {
    [self stopLoadingView];
    if (!callback) {
        return;
    }
    NSString *title = [params turing_stringValueForKey:kBDAccountSealAlertTitle];
    NSString *message = [params turing_stringValueForKey:kBDAccountSealAlertMessage];
    NSArray *parameter = [params turing_arrayValueForKey:kBDAccountSealAlertOptions];
    if (parameter.count < 1) {
        callback(BDTuringPiperMsgFailed, @{});
        return;
    }
    [BDTuringUIHelper sharedInstance].isShowAlert = YES;
    UIViewController *viewController = [self controller];
    NSArray<BDTuringAlertOption *> *options = [BDTuringAlertOption optionsWithArray:parameter
                                                                           callback:callback];
    [[BDTuringUIHandler sharedInstance] showAlertWithTitle:title
                                                   message:message
                                                   options:options
                                          onViewController:viewController];
}

- (void)handlePiperVerify:(NSDictionary *)params
                    callback:(BDTuringPiperOnCallback)callback {
    NSString *verifyType = [params turing_stringValueForKey:@"verify_type"];
    NSString *uid = [params turing_stringValueForKey:kBDTuringUserID];
    NSInteger showToast = [params turing_integerValueForKey:kBDTuringShowToast];
    NSString *scene = [params turing_stringValueForKey:kBDTuringScene];
    NSString *appID = self.model.appID;
    BDTuringRegionType regionType = self.model.regionType;
    
    BDTuringWeakSelf;
    if ([verifyType isEqualToString:@"identity"]) {
        BDTuringVerifyResultCallback identityCallback = ^(BDTuringVerifyResult *verify) {
            BDTuringStrongSelf;
            BDTuringIdentityResult *response = (BDTuringIdentityResult *)verify;
            NSMutableDictionary *result = [NSMutableDictionary new];
            [result setValue:response.ticket forKey:kBDAccountSealTicket];
            callback(BDTuringPiperMsgSuccess, result);
            
            NSMutableDictionary *param = [NSMutableDictionary new];
            long long duration = CFAbsoluteTimeGetCurrent() * 1000 - self.startLoadTime;
            [param setValue:@(duration) forKey:kBDTuringDuration];
            NSString *extra = [NSString stringWithFormat:@"%zd|%zd|%zd",response.identityAuthCode,response.livingDetectCode,response.serverCode];
            [param setValue:verifyType forKey:@"verify_type"];
            [param setValue:extra forKey:@"extras"];
            [[BDAccountSealEvent sharedInstance] collectEvent:BDAccountSealEventVerifyResult
                                                        data:param];
            
        };
        
        [BDTuringUIHelper sharedInstance].showNavigationBarWhenDisappear = NO;
        BDTuringIdentityModel *model = [BDTuringIdentityModel new];
        model.appID = appID;
        model.scene = scene;
        model.regionType = regionType;
        model.callback = identityCallback;
        model.ticket = [params turing_stringValueForKey:kBDAccountSealTicket];
        
        UIViewController *currentViewController = [self controller];
        UINavigationController *currentNavigator = currentViewController.navigationController;
        model.currentViewController = currentViewController;
        model.currentNavigator = currentNavigator;
        [[BDTuringServiceCenter defaultCenter] popVerifyViewWithModel:model];
        return;
    }
    
    BDTuringVerifyResultCallback verifyCallback = ^(BDTuringVerifyResult *rensponse) {
        BDTuringStrongSelf;
        NSMutableDictionary *result = [NSMutableDictionary new];
        [result setValue:@(rensponse.status) forKey:kBDTuringStatusCode];
        [result setValue:rensponse.token forKey:kBDTuringToken];
        [result setValue:rensponse.mobile forKey:kBDTuringMobile];
        callback(BDTuringPiperMsgSuccess, result);
        
        NSMutableDictionary *param = [NSMutableDictionary new];
        long long duration = CFAbsoluteTimeGetCurrent() * 1000 - self.startLoadTime;
        [param setValue:@(duration) forKey:kBDTuringDuration];
        [param setValue:@(rensponse.status) forKey:kBDTuringStatusCode];
        [param setValue:verifyType forKey:@"verify_type"];
        [[BDAccountSealEvent sharedInstance] collectEvent:BDAccountSealEventVerifyResult
                                                    data:param];
    };
    NSString *verifyParam = [params turing_stringValueForKey:@"params"];
    NSDictionary *respone = [verifyParam turing_dictionaryFromJSONString];
    BDTuringVerifyModel *model = [BDTuringParameterVerifyModel modelWithParameter:respone];
    model.callback = verifyCallback;
    model.showToast = showToast;
    model.userID = uid;
    model.appID = appID;
    model.regionType = regionType;
    [[BDTuringServiceCenter defaultCenter] popVerifyViewWithModel:model];
}

#pragma mark - WKNavigationDelegate


- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self stopLoadingView];
    [super webView:webView didFailNavigation:navigation withError:error];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self stopLoadingView];
    [super webView:webView didFailProvisionalNavigation:navigation withError:error];
}

#pragma mark - public

- (void)loadSealView {
    [self startLoadingView];
    BDTuringConfig *config = self.config;
    NSString *appID = self.model.appID;
    NSString *region = self.model.region;
    BDTuringSettings *settings = [BDTuringSettings settingsForAppID:appID];
    NSMutableDictionary *query = [config sealWebURLQueryParameters];
    NSString *requestURL = [settings requestURLForPlugin:kBDTuringSettingsPluginSeal
                                                 URLType:kBDTuringSettingsURL
                                                  region:region];
    NSCAssert(requestURL, @"requestURL should not be nil");
    NSString *host = [settings requestURLForPlugin:kBDTuringSettingsPluginSeal
                                           URLType:kBDTuringSettingsHost
                                            region:region];
    [query setValue:host forKey:@"host"];
    [query setValue:@(1) forKey:kBDTuringUseNativeReport];
    [query setValue:@(1) forKey:kBDTuringUseJSBRequest];
    [query setValue:convertNativeThemeModeToString(self.model.nativeThemeMode) forKey:kBDTuringNativeThemeMode];
    requestURL = turing_requestURLWithQuery(requestURL, query);

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURL]];
    [self.webView loadRequest:request];
    self.webView.hidden = YES;
    CGRect frame = self.webView.frame;
    self.webView.frame =  CGRectOffset(frame, frame.size.width, 0);
}

- (void)hideVerifyView {
    [BDTuringUIHelper sharedInstance].isShowAlert = NO;
    CGRect frame = self.webView.frame;
    [UIView animateWithDuration:0.28
                     animations:^{
        self.webView.frame =  CGRectOffset(frame, frame.size.width, 0);
        self.webView.alpha = 0;
    } completion:^(BOOL finished) {
        [super hideVerifyView];
        [self scheduleDismissVerifyView];
        self.webView.frame =  CGRectOffset(frame, frame.size.width, 0);
    }];
}

- (void)dismissVerifyView {
    [super dismissVerifyView];
}

NSString *convertNativeThemeModeToString(BDAccountSealThemeMode themeMode) {
    switch (themeMode) {
        case BDAccountSealThemeModeDark:
            return BDAccountSealThemeStringDark;
            break;
        case BDAccountSealThemeModeLight:
            return BDAccountSealThemeStringLight;
            break;
        default:
            return BDAccountSealThemeStringLight;
            break;
    }
}

@end
