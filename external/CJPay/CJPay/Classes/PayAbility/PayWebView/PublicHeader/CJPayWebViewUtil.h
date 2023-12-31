//
//  CJPayWebViewUtil.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/24.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CJBizWebDelegate.h"
//#import "CJPayBizWebViewController+Biz.h"
//#import "CJPayUIMacro.h"
//#import "CJPayRouterService.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "CJPayH5DeskModule.h"
#import "CJPayBizParam.h"
#import "CJPayWebViewUADelegate.h"

@class CJPayBizWebViewController;
@class CJPayWebviewStyle;

NS_ASSUME_NONNULL_BEGIN

#define CJPayBizNeedCloseAllWebVC @"CJPayBizNeedCloseAllWebVC"
#define CJPayBizCloseCallbackNoti @"CJPayBizCloseCallbackNoti"
#define CJPayBizPreCloseCallbackNoti @"CJPayBizPreCloseCallbackNoti"
#define CJPayBizRefreshCookieNoti @"CJPayBizRefreshCookieNoti"
/**
 打开WebView的方法，推荐使用该方法，会做一些UA设置的操作。
 */
@interface CJPayWebViewUtil : NSObject<CJBizWebDelegate>

@property (nonatomic, strong) id<CJBizWebDelegate> delegate;
@property (nonatomic, weak) id<CJPayWebViewUADelegate> uaDelegate;

+ (instancetype)sharedUtil;

- (BOOL)handlesURL:(NSURL *)url;

/// 从当前页面进入透明WebView，加载财经的H5页面
/// @param sourceVC  源头的VC
/// @param urlString  目标URL的string表示
- (void)openH5ModalViewFrom:(UIViewController *)sourceVC
                      toUrl:(NSString *)urlString;

- (void)openH5ModalViewFrom:(UIViewController *)sourceVC
                      toUrl:(NSString *)urlString
                      style:(CJH5CashDeskStyle)style
                showLoading:(BOOL)showLoading
            backgroundColor:(UIColor *)backgroundColor
                   animated:(BOOL)animated
              closeCallBack:(void(^ _Nullable)(id))closeCallBack;

- (void)openH5ModalViewFrom:(UIViewController *)sourceVC
                      toUrl:(NSString *)urlString
                      style:(CJH5CashDeskStyle)style
                showLoading:(BOOL)showLoading
            backgroundColor:(UIColor *)backgroundColor
                   animated:(BOOL)animated
              closeCallBack:(void(^ _Nullable)(id))closeCallBack
                  backBlock:(void(^ _Nullable)(void))backBlock
             justCloseBlock:(void(^ _Nullable)(void))justCloseBlock;

// toScheme 支持SDK自动解析scheme中的参数，toScheme格式要求: sslocal://cjpay/webview?url=xxx&other=xxxx
- (void)gotoWebViewControllerFrom:(nullable UIViewController *)sourceVC toScheme:(NSString *)toScheme;

- (void)setPiperClass:(Class)klass;

// service字段说明 https://wiki.bytedance.net/pages/viewpage.action?pageId=252012722

/**
 跳转到WebView
 
 @param sourceVC 源VC
 @param toUrl 要跳转到的url
 */
- (void)gotoWebViewControllerFrom:(nullable UIViewController *)sourceVC
                            toUrl:(NSString *)toUrl;

/**
 跳转到WebView

 @param sourceVC 源VC
 @param toUrl 要跳转到的url
 @param params 参数
 */
- (void)gotoWebViewControllerFrom:(UIViewController *)sourceVC
                            toUrl:(NSString *)toUrl
                           params:(NSDictionary *)params;

/**
 跳转到WebView
 
 @param sourceVC 源VC
 @param toUrl 要跳转到的url
 @param params 参数
 @param nativeStyleParams 控制webview native部分样式的参数
 */
- (void)gotoWebViewControllerFrom:(UIViewController *)sourceVC
                            toUrl:(NSString *)toUrl
                           params:(NSDictionary *)params
                nativeStyleParams:(NSDictionary *)nativeStyleParams;

/**
 跳转到WebView
 
 @param sourceVC 源VC
 @param toUrl 要跳转到的url
 @param params 参数
 @param closeCallBack H5调用JSBridge关闭webview时，回传的参数
 */
- (void)gotoWebViewControllerFrom:(UIViewController *)sourceVC
                            toUrl:(NSString *)toUrl
                           params:(NSDictionary *)params
                    closeCallBack:(nullable void(^)(id data)) closeCallBack;

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
                    closeCallBack:(void(^)(id data))closeCallBack;

/**
 跳转到WebView
 
 @param sourceVC 源VC
 @param useNewNavi 使用新的NavigationController
 @param toUrl 要跳转到的url
 @param params 参数
 @param nativeStyleParams 控制webview native部分样式的参数
 @param closeCallBack H5调用JSBridge关闭webview时，回传的参数
 */
- (void)gotoWebViewControllerFrom:(UIViewController *)sourceVC
                       useNewNavi:(BOOL)useNewNavi
                            toUrl:(NSString *)toUrl
                           params:(NSDictionary *)params
                nativeStyleParams:(NSDictionary *)nativeStyleParams
                    closeCallBack:(void(^)(id data)) closeCallBack;

- (nullable CJPayBizWebViewController *)buildWebViewControllerWithUrl:(NSString *)toUrl fromVC:(UIViewController *)fromVC params:(NSDictionary *)params
                                                    nativeStyleParams:(NSDictionary *)nativeStyleParams
                                                        closeCallBack:(void(^)(id data))closeCallBack;

- (void)gotoWebViewController:(NSString *)url webviewStyle:(CJPayWebviewStyle *)style closeCallback:(void(^)(id data)) closeCallBack;

- (void)setupUAWithCompletion:(nullable void (^)(NSString * _Nullable))completionBlock;

- (NSString *)getWebViewUA;

@end

NS_ASSUME_NONNULL_END
