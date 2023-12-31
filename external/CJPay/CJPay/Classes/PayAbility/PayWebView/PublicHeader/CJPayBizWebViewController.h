//
//  CJPayBizWebViewController.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import "CJPayFullPageBaseViewController.h"
//#import "CJPayWebviewStyle.h"
//#import "CJPayDataPrefetcher.h"
//#import "CJPayHybridPerformanceMonitor.h"
//#import "CJPayWKWebView.h"
#import "CJPayToast.h"
#import "CJPayLoadingManager.h"

@class WKWebView;
@class CJPayWebviewStyle;
@class CJPayDataPrefetcher;
@class CJPayHybridPerformanceMonitor;
@class CJPayWKWebView;
@class CJPayBaseHybridWebview;

@interface CJPiper : NSObject

@property (nonatomic, weak) WKWebView *webView;

- (void)flushMessages;
- (instancetype)initWithWebView:(UIView *)webView;

@end

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBizWebViewController : CJPayFullPageBaseViewController

@property (nonatomic, strong, readonly) CJPayWKWebView *webView;
@property (nonatomic, assign) BOOL showsLoading; // 默认为yes
@property (nonatomic, assign) BOOL isShowNewUIStyle; // 绑卡全流程优化从一键绑卡进入为YES
@property (nonatomic, copy) NSString *titleStr; // 目前传银行名称
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, readonly) NSString *urlStr;
@property (nonatomic, strong) CJPayWebviewStyle *webviewStyle;
@property (nonatomic, strong) CJPiper *bridge;

@property (nonatomic, assign) BOOL shouldNotifyH5LifeCycle;
@property (nonatomic, assign) BOOL allowsPopGesture; // 默认为YES
// 这个是提供给JSBridge回调用。其他地方不要使用，否则可能会被jsbridge冲掉
@property (nonatomic, strong) CJPayHybridPerformanceMonitor *webPerformanceMonitor;

@property (nonatomic, assign) NSTimeInterval visibleDuration;
@property (nonatomic, assign) NSTimeInterval visibleTime;
@property (nonatomic, assign) NSTimeInterval invisibleTime;
@property (nonatomic, assign, readonly) BOOL hasFirstLoad;
@property (nonatomic, copy) NSDictionary *shareParam; // 目前传银行名称
@property (nonatomic, copy, readonly) NSString *rifleMegaObject;

@property (nonatomic, strong) Class klass;
@property (nonatomic, copy) NSString *pageCloseType;
//hybridkit内核参数
//内核标识
@property (nonatomic, copy) NSString *kernel;

// 是否需要广播DomContentLoaded事件
@property (nonatomic, assign) BOOL broadcastDomContentLoaded;

//原始scheme，直接传入的
@property (nonatomic, copy) NSString *originScheme;
//hybrid内核，支持切换
@property (nonatomic, strong) CJPayBaseHybridWebview *hybridView;
//containerID
@property (nonatomic, copy, readonly) NSString *containerID;

@property (nonatomic, copy) void(^closeCallBack)(id); // 在h5关闭webView时，会把JSbridge返回的值回传给业务方,
// 注意: 如果是通过bridge打开一个新的webviewVC，则这个closecallback会在这些WebVC之间共享
@property (nonatomic, copy, nullable) void(^justCloseBlock)(void); //只是在关闭webView时closeCallBack执行不被执行的备选项
@property (nonatomic, strong, readonly, nullable) CJPayDataPrefetcher *dataPrefetcher;
@property (nonatomic, copy) void(^ttcjpayLifeCycleBlock)(CJPayVCLifeType type);
@property (nonatomic, copy) NSString *returnUrl; // 在加载该URL时，会认为需要关闭WebView，默认为空

- (instancetype)initWithUrlString:(NSString *)url;
- (instancetype)initWithUrlString:(NSString *)urlString piperClass:(Class)klass;
- (instancetype)initWithNSUrl:(NSURL *)url;
- (instancetype)initWithRequest:(NSURLRequest *)request; // 一键绑卡会用到传入request

- (BOOL)isCaijingSaasEnv; //财经容器是否处于saas环境
- (BOOL)canGoBack;
- (void)goBack;
- (void)sendEvent:(NSString *)event params:(nullable NSDictionary *)data;
- (void)setBounce:(BOOL)enable;
/**
 关闭WebVC
 */
- (void)closeWebVC;

- (void)closeWebVCWithAnimation:(BOOL)animation
                     completion:(void (^ __nullable)(void))completion;

@end
NS_ASSUME_NONNULL_END
