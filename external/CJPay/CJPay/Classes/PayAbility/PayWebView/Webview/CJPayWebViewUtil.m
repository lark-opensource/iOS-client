//
//  CJPayWebViewUtil.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/24.
//

#import "CJPayWebViewUtil.h"

#import "CJPayCookieUtil.h"
#import "CJPayBinaryAdapter.h"
#import "CJPayBizParam.h"
#import "CJSDKParamConfig.h"
#import "CJPayUIMacro.h"
#import "CJPayRequestParam.h"
#import "NSURL+CJPayScheme.h"
#import "CJPayPrivateServiceHeader.h"
#import <WebKit/WKWebView.h>
#import "CJPayFetchIMServiceRequest.h"
#import "CJPayFetchIMServiceResponse.h"
#import "UIViewController+CJTransition.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayToast.h"
#import "CJPayLoadingManager.h"
#import "CJPayRouterService.h"
#import "CJPayBizWebViewController+Biz.h"
#import "CJPayNavigationController.h"
#import "CJPayWebviewStyle.h"
#import "CJPayHybridPlugin.h"
#import "CJPayNestingLynxCardManager.h"

NSString static *const CJPayUserAgent = @"CJPayUserAgent";

typedef NS_ENUM(NSInteger, CJPayContainerType) {
    CJPayHybridContainer = 0,//新hybrid容器，web/lynx
    CJPayHostContainer//走宿主路由，宿主lynx或者财经web容器
};

@interface CJPayWebViewUtil ()<CJPayWebViewService>

@property (nonatomic, copy) NSString *host;
@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) Class klass;

@end

@implementation CJPayWebViewUtil

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedUtil), CJPayWebViewService)
})

#pragma - mark wake by scheme
- (BOOL)openPath:(NSString *)path withParams:(NSDictionary *)params {
    if ([path isEqualToString:@"webview"]) {
        NSString *url = [params cj_stringValueForKey:CJPayRouterParameterURL];
        url.cjpay_referViewController = params.cjpay_referViewController;
        [self i_openScheme:url callBack:^(CJPayAPIBaseResponse *data) {
            if (params[CJPayRouterParameterCompletion]) {
                void (^completion)(id result) = (void(^)(id result))(params[CJPayRouterParameterCompletion]);
                CJ_CALL_BLOCK(completion, data);
            }
        }];
        CJPayLogInfo(@"打开财经WebView，scheme = %@, params = %@", CJString(url), params? : @"");
        return YES;
    } else if ([path isEqualToString:@"lynxview"]) {
        // 目前SDK没有定制lynx的容器，所以所有场景都走宿主来打开
        NSString *url = [params cj_stringValueForKey:CJPayRouterParameterURL];
        NSString *schemePrefix = @"sslocal://cjpay/lynxview";
        if ([url hasPrefix:schemePrefix]) {
            url = [NSString stringWithFormat:@"%@%@", @"sslocal://lynxview", [url substringFromIndex:schemePrefix.length]];
        }
        url.cjpay_referViewController = params.cjpay_referViewController;
        
        [self i_openCjSchemaByHost:url fromVC:params.cjpay_referViewController useModal:YES];
        CJPayLogInfo(@"打开宿主lynxview，scheme = %@, params = %@", CJString(url), params? : @"");
        return YES;
    }
    return NO;
}

+ (instancetype)sharedUtil{ // 兼容对外API
    static CJPayWebViewUtil *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CJPayWebViewUtil alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            [instance setupUAWithCompletion:nil];
        });
    });
    return instance;
}

- (void)setPiperClass:(Class)klass {
    self.klass = klass;
}

#pragma mark - private method
- (BOOL)handlesURL:(NSURL *)url
{
    if (!url.isCJPayWebviewScheme) {
        return NO;
    }
        
    UIViewController *topMostVC = [UIViewController cj_foundTopViewControllerFrom:url.cjpay_referViewController];
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:topMostVC toScheme:[url absoluteString]];
    return YES;
}

- (void)needLogin:(void (^)(CJBizWebCode))callback{
    [[CJPayCookieUtil sharedUtil] cleanCookies];
    if (self.delegate) {
        [self.delegate needLogin:^(CJBizWebCode code) {
            id<CJPayManagerAdapterDelegate> managerDelegate = [CJPayBinaryAdapter shared].managerDelegate;
            if (managerDelegate && [managerDelegate respondsToSelector:@selector(closePayDeskWithCompletion:)]) {
                [managerDelegate closePayDeskWithCompletion:^(BOOL isSuccess) {
                    CJ_CALL_BLOCK(callback, code);
                    if (code == CJBizWebCodeCloseDesk) {
                        [NSNotificationCenter.defaultCenter postNotificationName:CJPayBizNeedCloseAllWebVC
                                                                          object:nil
                                                                        userInfo:@{@"source": @"loginCloseDesk"}];
                    } else if (code == CJBizWebCodeLoginSuccess) {
                        [NSNotificationCenter.defaultCenter postNotificationName:CJPayBizRefreshCookieNoti
                                                                          object:nil
                                                                        userInfo:@{@"source": @"login"}];
                    }
                }];
            } else {
                CJ_CALL_BLOCK(callback, code);
                if (code == CJBizWebCodeCloseDesk) {
                    [NSNotificationCenter.defaultCenter postNotificationName:CJPayBizNeedCloseAllWebVC
                                                                      object:nil
                                                                    userInfo:@{@"source": @"loginCloseDesk"}];
                } else if (code == CJBizWebCodeLoginSuccess) {
                    [NSNotificationCenter.defaultCenter postNotificationName:CJPayBizRefreshCookieNoti
                                                                      object:nil
                                                                    userInfo:@{@"source": @"login"}];
                }
            }
        }];
    }
}

- (void)openH5ModalViewFrom:(UIViewController *)sourceVC
                      toUrl:(NSString *)urlString
{
    [self openH5ModalViewFrom:sourceVC
                        toUrl:urlString
                        style:CJH5CashDeskStyleVertivalHalfScreen
                  showLoading:YES
              backgroundColor:[UIColor clearColor]
                     animated:YES
                closeCallBack:nil];
}

- (void)openH5ModalViewFrom:(UIViewController *)sourceVC
                      toUrl:(NSString *)urlString
                      style:(CJH5CashDeskStyle)style
                showLoading:(BOOL)showLoading
            backgroundColor:(UIColor *)backgroundColor
                   animated:(BOOL)animated
              closeCallBack:(void(^)(id))closeCallBack
{
    [self openH5ModalViewFrom:sourceVC
                        toUrl:urlString
                        style:style
                  showLoading:showLoading
              backgroundColor:backgroundColor
                     animated:animated
                closeCallBack:closeCallBack
                    backBlock:nil
               justCloseBlock:nil];
}

- (void)openH5ModalViewFrom:(UIViewController *)sourceVC
                      toUrl:(NSString *)urlString
                      style:(CJH5CashDeskStyle)style
                showLoading:(BOOL)showLoading
            backgroundColor:(UIColor *)backgroundColor
                   animated:(BOOL)animated
              closeCallBack:(void(^)(id))closeCallBack
                  backBlock:(void(^)(void))backBlock
             justCloseBlock:(void(^)(void))justCloseBlock
{
    CJPayLogInfo(@"打开透明H5页面, sourceVC = %@, urlString = %@, style = %@, showLoading = %@, backgroundColor = %@, animated = %@", sourceVC, urlString, @(style), @(showLoading), backgroundColor, @(animated));

    NSString *fullPage = @""; // 默认为空
    switch (style) {
        case CJH5CashDeskStyleVertivalFullScreen:
            fullPage = @"0";
            break;
        case CJH5CashDeskStyleVertivalHalfScreen:
            fullPage = @"1";
            break;
        case CJH5CashDeskStyleLandscapeHalfScreen:
            fullPage = @"2";
            break;
        default:
            fullPage = @"";
            break;
    }
    NSMutableDictionary *mutableParams = [[self p_extraInfoParam] mutableCopy];
    if (![mutableParams objectForKey:@"fullpage"]) { // 通过透明webview打开的页面，拼接fullpage参数
        [mutableParams cj_setObject:fullPage forKey:@"fullpage"];
    }
    NSString *finalUrl = [CJPayCommonUtil appendParamsToUrl:urlString params:[mutableParams copy]];

    CJPayBizWebViewController *cashDeskVC = [CJPayBizWebViewController buildWebBizVC:style finalUrl:finalUrl completion:nil];
    cashDeskVC.showsLoading = showLoading;
    cashDeskVC.closeCallBack = [closeCallBack copy];
    cashDeskVC.cjBackBlock = [backBlock copy];
    cashDeskVC.justCloseBlock = [justCloseBlock copy];
    if (style == CJH5CashDeskStyleVertivalHalfScreen || style == CJH5CashDeskStyleLandscapeHalfScreen) {
        cashDeskVC.allowsPopGesture = NO;
    }
    if (sourceVC.navigationController) {
        if (sourceVC && sourceVC.navigationController && [sourceVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
            [sourceVC.navigationController pushViewController:cashDeskVC animated:YES];
        } else {
            [cashDeskVC presentWithNavigationControllerFrom:sourceVC useMask:NO completion:nil];
        }
    } else {
        UIViewController *topVC = sourceVC ?: [UIViewController cj_topViewController];
        [cashDeskVC presentWithNavigationControllerFrom:topVC useMask:NO completion:nil];
    }
}

- (NSDictionary *)p_extraInfoParam {
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc]init];
      NSMutableDictionary *deviceInfoDic = [[NSMutableDictionary alloc]init];
      deviceInfoDic[@"statusbar_height"] = [NSString stringWithFormat:@"%d", CJ_STATUSBAR_HEIGHT];
      NSData *deviceInfoData = [[CJPayCommonUtil dictionaryToJson:deviceInfoDic] dataUsingEncoding:NSUTF8StringEncoding];
    
      NSString *deviceInfoBase64Str = [deviceInfoData base64EncodedStringWithOptions:0];
      if (Check_ValidString(deviceInfoBase64Str)) {
          paramsDic[@"device_info"] = deviceInfoBase64Str;
      }
    return [paramsDic copy];
}

- (void)openCJScheme:(NSString *)scheme {
    [self openCJScheme:scheme fromVC:nil useModal:YES];
}

- (void)openCJScheme:(NSString *)scheme fromVC:(UIViewController *)vc useModal:(BOOL)useModal {
    if ([self.delegate respondsToSelector:@selector(openCJScheme:fromVC:useModal:)]) {
        [self.delegate openCJScheme:scheme fromVC:vc useModal:useModal];
        [CJTracker event:@"wallet_rd_open_scheme" params:@{@"is_register": @"1", @"scheme": CJString(scheme)}];
    } else if ([self.delegate respondsToSelector:@selector(openCJScheme:)]) {
        [self.delegate openCJScheme:scheme];
        [CJTracker event:@"wallet_rd_open_scheme" params:@{@"is_register": @"1", @"scheme": CJString(scheme)}];
    } else {
        CJPayLogAssert(NO, @"app 需要实现CJBizWebDelegate的openCJScheme方法");
        [CJTracker event:@"wallet_rd_open_scheme" params:@{@"is_register": @"0", @"scheme": CJString(scheme)}];
    }
}

- (void)gotoWebViewControllerFrom:(UIViewController *)sourceVC toScheme:(NSString *)toScheme {
    [self p_openScheme:toScheme callBack:^(CJPayAPIBaseResponse * response) {
        
    }];
}

- (void)logoutAccount {
    if (self.delegate && [self.delegate respondsToSelector:@selector(logoutAccount)]) {
        [self.delegate logoutAccount];
    }
}

- (void)gotoWebViewControllerFrom:(UIViewController *)sourceVC
                            toUrl:(NSString *)toUrl {
    [self gotoWebViewControllerFrom:sourceVC toUrl:toUrl params:@{}];
}

- (void)gotoWebViewControllerFrom:(UIViewController *)sourceVC
                            toUrl:(NSString *)toUrl
                           params:(NSDictionary *)params {
    [self gotoWebViewControllerFrom:sourceVC toUrl:toUrl params:params closeCallBack:^(id  _Nonnull data) {
        // do nothing
    }];
}

- (void)gotoWebViewControllerFrom:(UIViewController *)sourceVC
                            toUrl:(NSString *)toUrl
                           params:(NSDictionary *)params
                nativeStyleParams:(NSDictionary *)nativeStyleParams {
    [self gotoWebViewControllerFrom:sourceVC
                                toUrl:toUrl
                               params:params
                    nativeStyleParams:nativeStyleParams
                        closeCallBack:^(id  _Nonnull data) {
        // do nothing
    }];
}

- (void)gotoWebViewControllerFrom:(UIViewController *)sourceVC
                            toUrl:(NSString *)toUrl
                           params:(NSDictionary *)params
                    closeCallBack:(nullable void(^)(id data))closeCallBack {
    [self gotoWebViewControllerFrom:sourceVC
                                toUrl:toUrl
                               params:params
                    nativeStyleParams:@{}
                        closeCallBack:closeCallBack];
}

/**
 跳转到WebView
 
 @param sourceVC 源VC
 @param toUrl 要跳转到的url
 @param params 参数
 @param nativeStyleParams 控制webview native部分样式的参数
 @param closeCallBack H5调用JSBridge关闭webview时，回传的参数
 */
- (void)gotoWebViewControllerFrom:(UIViewController *)sourceVC
                            toUrl:(NSString *)toUrl
                           params:(NSDictionary *)params
                nativeStyleParams:(NSDictionary *)nativeStyleParams
                    closeCallBack:(void(^)(id data)) closeCallBack {
    [self gotoWebViewControllerFrom:sourceVC useNewNavi:NO toUrl:toUrl params:params nativeStyleParams:nativeStyleParams closeCallBack:closeCallBack];
}

- (void)gotoWebViewControllerFrom:(UIViewController *)sourceVC
                       useNewNavi:(BOOL)useNewNavi
                            toUrl:(NSString *)toUrl
                           params:(NSDictionary *)params
                nativeStyleParams:(NSDictionary *)nativeStyleParams
                    closeCallBack:(void(^)(id data)) closeCallBack {
    CJPayLogInfo(@"打开竖全屏H5页面，sourceVC = %@, useNewNavi = %@, toUrl = %@, params = %@, nativeStyleParams = %@", sourceVC, @(useNewNavi), toUrl, params, nativeStyleParams);
    
    if (toUrl.length <= 0) {
        [CJToast toastText:CJPayLocalizedStr(@"参数不合法") inWindow:sourceVC.cj_window];
        return;
    }
    CJPayBizWebViewController *vc = [self buildWebViewControllerWithUrl:toUrl fromVC:sourceVC params:params nativeStyleParams:nativeStyleParams  closeCallBack:closeCallBack];
    
    if (!vc) {
        return;
    }
    
    if ([sourceVC.navigationController isKindOfClass:[CJPayNavigationController class]] && !useNewNavi) {
        [sourceVC.navigationController pushViewController:vc animated:YES];
    } else {
        [vc presentWithNavigationControllerFrom:sourceVC useMask:NO completion:nil];
    }
}

- (nullable CJPayBizWebViewController *)buildWebViewControllerWithUrl:(NSString *)toUrl
                                                               fromVC:(UIViewController *)fromVC
                                                               params:(NSDictionary *)params
                                                    nativeStyleParams:(NSDictionary *)nativeStyleParams
                                                        closeCallBack:(void(^)(id data))closeCallBack {
    CJPayLogInfo(@"构建CJPayBizWebViewController，scheme = %@, fromVC = %@, params = %@, nativeStyleParams = %@", toUrl, fromVC, params, nativeStyleParams);

    if (toUrl.length <= 0) {
        [CJToast toastText:CJPayLocalizedStr(@"参数不合法") inWindow:fromVC.cj_window];
        return nil;
    }
    
    NSMutableDictionary *fullParams = [NSMutableDictionary dictionaryWithDictionary:params];
    NSString *url = [CJPayCommonUtil appendParamsToUrl:toUrl params:fullParams];
    
    url = [self prepareBeforeGotoWebVCWithURL:url];
    
    CJPayBizWebViewController *vc = [[CJPayBizWebViewController alloc] initWithUrlString:url piperClass:self.klass];
    if ([nativeStyleParams count] > 0) {
        [vc.webviewStyle amendByDic:nativeStyleParams];
    }
    vc.closeCallBack = closeCallBack;
    return vc;
}

- (NSString *)prepareBeforeGotoWebVCWithURL:(NSString *)url {
    return url;
}

- (void)gotoWebViewController:(NSString *)url webviewStyle:(CJPayWebviewStyle *)style closeCallback:(void(^)(id data)) closeCallBack {
    CJPayBizWebViewController *vc = [[CJPayBizWebViewController alloc] initWithUrlString:url];
    vc.webviewStyle = style;

    vc.closeCallBack = closeCallBack;
    UIViewController *sourceVC = [UIViewController cj_foundTopViewControllerFrom:url.cjpay_referViewController];
    if ([sourceVC.navigationController isKindOfClass:[CJPayNavigationController class]]) {
        [sourceVC.navigationController pushViewController:vc animated:YES];
    } else {
        [vc presentWithNavigationControllerFrom:sourceVC useMask:NO completion:nil];
    }
}

- (NSString *)getWebViewUA {
    NSString *did = @"";
    if ([CJPayRequestParam gAppInfoConfig].deviceIDBlock) {
        did = [CJPayRequestParam gAppInfoConfig].deviceIDBlock();
    }
    NSString *language = ([CJPayLocalizedUtil getCurrentLanguage] == CJPayLocalizationLanguageEn) ? @"en" : @"cn";
    return [NSString stringWithFormat:@" CJPay/%@ AID%@/%@ Lang/%@ DID/%@ Host/ULPay SBarH/%d", [CJSDKParamConfig defaultConfig].version, [CJPayRequestParam gAppInfoConfig].appId, [CJPayRequestParam appVersion], language, did, CJ_STATUSBAR_HEIGHT];
}
 
- (void)setupUAWithCompletion:(nullable void (^)(NSString * _Nullable))completionBlock {
    CFTimeInterval startT = CFAbsoluteTimeGetCurrent();
    NSString *originalUserAgent = [self p_originalCJPayUserAgent];
    NSString *cjpayUA = [self getWebViewUA];
    if ([originalUserAgent containsString:cjpayUA]) {
        CFTimeInterval endT = CFAbsoluteTimeGetCurrent();
        CJPayLogInfo(@"获取一次UA，耗时%lf , 有缓存", endT - startT);
        [CJTracker event:@"wallet_user_agent" params:@{@"user_agent": CJString(originalUserAgent), @"quick":@"1", @"time": @(endT - startT)}];
        CJ_CALL_BLOCK(completionBlock, originalUserAgent);
        return;
    }
    
    if (self.uaDelegate &&
        [self.uaDelegate respondsToSelector:@selector(enableUAFetch)] &&
        [self.uaDelegate enableUAFetch] &&
        [self.uaDelegate respondsToSelector:@selector(fetchLastestSystemUserAgentWithCompletion:)]) {
        [self.uaDelegate fetchLastestSystemUserAgentWithCompletion:^(NSString * _Nullable userAgent, NSString * _Nullable applicationName, NSError * _Nullable error) {
            if (error != nil) {
                CJPayLogInfo(@"获取UA报错：%@", error)
                return;
            }
            
            if ([userAgent containsString:cjpayUA]) {
                CJ_CALL_BLOCK(completionBlock, userAgent);
                return;
            }
            userAgent = [userAgent stringByAppendingString:cjpayUA];
            [[NSUserDefaults standardUserDefaults] setValue:CJString(userAgent) forKey:CJPayUserAgent];
            CFTimeInterval endT = CFAbsoluteTimeGetCurrent();
            CJPayLogInfo(@"获取一次UA，耗时%lf", endT - startT);
            BDALOG_PROTOCOL_DEBUG(@"bdua:: cjpay ua [%@]", userAgent);
            [CJTracker event:@"wallet_user_agent" params:@{@"user_agent": CJString(userAgent), @"quick":@"0", @"time": @(endT - startT)}];
            CJ_CALL_BLOCK(completionBlock, userAgent);
        }];
        return;
    }
    
    self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero];
    [self.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(NSString * _Nullable result, NSError * _Nullable error) {
        
        if (error != nil) {
            CJPayLogInfo(@"获取UA报错：%@", error)
        }
        
        NSString *userAgent = result;
        if ([userAgent containsString:cjpayUA]) {
            CJ_CALL_BLOCK(completionBlock, userAgent);
            return;
        }
        userAgent = [userAgent stringByAppendingString:cjpayUA];
        [[NSUserDefaults standardUserDefaults] setValue:CJString(userAgent) forKey:CJPayUserAgent];
        CFTimeInterval endT = CFAbsoluteTimeGetCurrent();
        CJPayLogInfo(@"获取一次UA，耗时%lf", endT - startT);
        [CJTracker event:@"wallet_user_agent" params:@{@"user_agent": CJString(userAgent), @"quick":@"0", @"time": @(endT - startT)}];
        CJ_CALL_BLOCK(completionBlock, userAgent);
    }];
}

- (NSString *)p_originalCJPayUserAgent
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:CJPayUserAgent];
}

- (CJH5CashDeskStyle)p_getWebviewContainerStyle:(NSString *)schema {
    NSDictionary *shcemaParams = [schema cj_urlQueryParams];
    NSString *fullpage = [shcemaParams cj_stringValueForKey:@"fullpage"];
    if (!Check_ValidString(fullpage)) {
        return CJH5CashDeskStyleVertivalFullScreen;
    }
    
    CJH5CashDeskStyle style = CJH5CashDeskStyleVertivalFullScreen;
    if ([fullpage isEqualToString:@"0"]) {
        style = CJH5CashDeskStyleVertivalHalfScreen;
    } else if ([fullpage isEqualToString:@"2"]) {
        style = CJH5CashDeskStyleLandscapeHalfScreen;
    }
    
    return style;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}


#pragma mark - service
- (void)i_openScheme:(NSString *)scheme withDelegate:(id<CJPayAPIDelegate>)delegate {
    if (delegate && [delegate respondsToSelector:@selector(callState:fromScene:)]) {
        [delegate callState:YES fromScene:CJPaySceneWeb];
    }

    [self p_openScheme:scheme callBack:^(CJPayAPIBaseResponse *data) {
        if (delegate && [delegate respondsToSelector:@selector(onResponse:)]) {
            [delegate onResponse:data];
        }
    }];
}

- (void)p_openScheme:(NSString *)scheme callBack:(void (^)(CJPayAPIBaseResponse *))callback {//这里是路由打开webview的起点
    if ([self p_getWebviewContainerStyle:scheme] == CJH5CashDeskStyleVertivalFullScreen) {
        [self gotoWebViewControllerFrom:[UIViewController cj_foundTopViewControllerFrom:scheme.cjpay_referViewController]
                                    toUrl:scheme
                                    params:@{}
                                    closeCallBack:^(id  _Nonnull data) {
            CJPayAPIBaseResponse *response = [CJPayAPIBaseResponse new];
            response.scene = CJPaySceneWeb;
            response.data = data;
            if (callback) {
                callback(response);
            }
        }];
    } else {
        // 打开透明webview
        [self openH5ModalViewFrom:[UIViewController cj_foundTopViewControllerFrom:scheme.cjpay_referViewController]
                                toUrl:scheme
                                style:[self p_getWebviewContainerStyle:scheme]
                          showLoading:[[scheme cj_urlQueryParams] cj_boolValueForKey:@"show_loading"]
                      backgroundColor:[UIColor clearColor]
                             animated:NO
                        closeCallBack:^(id _Nonnull data) {
            CJPayAPIBaseResponse *response = [CJPayAPIBaseResponse new];
            response.scene = CJPaySceneWeb;
            response.data = data;
            if (callback) {
                callback(response);
            }
        }];
    }
}

- (void)i_openScheme:(NSString *)scheme callBack:(void (^)(CJPayAPIBaseResponse *))callback {
    [self p_openScheme:scheme callBack:callback];
}


- (void)i_registerBizDelegate:(id<CJBizWebDelegate>)delegate {
    self.delegate = delegate;
}

- (void)i_openCjSchemaByHost:(NSString *)schemaStr {
    CJPayLogInfo(@"[CJPayWebViewUtil i_openCjSchemaByHost:%@]", CJString(schemaStr));
    [self openCJScheme:schemaStr];
}

- (void)i_openCjSchemaByHost:(NSString *)schemaStr fromVC:(UIViewController *)referVC useModal:(BOOL)useModal {
    CJPayLogInfo(@"[CJPayWebViewUtil i_openCjSchemaByHost:%@ useModal:%@]", CJString(schemaStr), @(useModal).stringValue);
    [self openCJScheme:schemaStr fromVC:referVC useModal:useModal];
}

- (void)i_openSchemeByNtvVC:(NSString *)scheme fromVC:(nonnull UIViewController *)fromVC withInfo:(nonnull NSDictionary *)sdkInfo withDelegate:(id<CJPayAPIDelegate>)delegate {
    CJPayLogInfo(@"[CJPayWebViewUtil i_openScheme:%@ fromNtvVCWithInfo:%@]", CJString(scheme), CJString([sdkInfo cj_toStr]));
    
    [[CJPayNestingLynxCardManager defaultService] openSchemeByNtvVC:scheme fromVC:fromVC withInfo:sdkInfo completion:^(BOOL isOpenSuccess, NSDictionary * _Nonnull ext) {
        CJPayAPIBaseResponse *response = [[CJPayAPIBaseResponse alloc] init];
        response.scene = CJPaySceneLynxCard;
        response.error = [NSError errorWithDomain:@"打开Ntv嵌套lynxCard页面失败" code:CJPayErrorCodeCallFailed userInfo:nil];
        
        [delegate onResponse:response];
    }];
}

- (void)i_gotoIMServiceWithAppID:(NSString *)appID fromVC:(UIViewController *)vc {
    
    if (!vc) {
        return;
    }

    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:vc];
    
    [CJPayFetchIMServiceRequest startWithAppID:appID completion:^(NSError * _Nonnull error, CJPayFetchIMServiceResponse * _Nonnull response) {

        [[CJPayLoadingManager defaultService] stopLoading];

        if (error || ![response isSuccess] || !Check_ValidString(response.linkChatUrl)) {
            [CJToast toastText:CJPayLocalizedStr(@"目前无网络可用") inWindow:vc.cj_window];
            return;
        }

        [self gotoWebViewControllerFrom:vc toUrl:response.linkChatUrl];
    }];
}

@end
