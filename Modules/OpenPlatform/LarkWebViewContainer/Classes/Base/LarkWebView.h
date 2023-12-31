//
//  LarkWebView.h
//  LarkWebViewContainer
//
//  Created by 新竹路车神 on 2020/10/12.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LarkWebViewDelegate;
@protocol LarkWebViewMenuDelegate;

@class LarkWebViewConfig;
@class OPTrace;
@class LarkWebViewPerformance;

//标识使用网页期间发生的一些自定义事件
typedef NS_ENUM(NSUInteger, LarkWebViewCustomEvent) {
    LarkWebViewCustomEventNone = 0,
    LarkWebViewCustomEventDidEnterBackground   = 1 << 0,//webview切换App进入过后台
    LarkWebViewCustomEventDidDownLoad          = 1 << 1,//webview存在下载资源的行为
    LarkWebViewCustomEventDidOpenMediaResource = 1 << 2 //webview加载过URL包括mp3/mp4/wav媒体文件
};

/// 备注：oc代码只允许包含init和dealloc，不允许包含其他方法
/// 套件统一WebView「使用OC代码的目的是为了兼容飞书小程序引擎，小程序引擎需要使用OC的代码继承该类，而苹果不允许OC类继承Swift类」
@interface LarkWebView : WKWebView

/// WebView初始化配置 由于混编问题，无法设置readonly，请勿写该属性
@property (nonatomic, strong) LarkWebViewConfig *config;
/// LarkWebView回调Delegate
@property (nonatomic, weak, nullable) id <LarkWebViewDelegate> webviewDelegate;
/// Tracing信息 由于混编问题，无法设置readonly，请勿写该属性
@property (nonatomic, strong, nullable) OPTrace *trace;
/// 是否已经上报了实时数据---首页加载耗时
@property (nonatomic, assign)BOOL hasUploadURLDuration;

@property (nonatomic, strong) LarkWebViewPerformance *performancer;

/// LarkWebViewMenu回调Delegate
@property (nonatomic, weak, nullable) id <LarkWebViewMenuDelegate> webviewMenuDelegate;


+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame config:(LarkWebViewConfig *)config;
- (instancetype)initWithFrame:(CGRect)frame config:(LarkWebViewConfig *)config parentTrace:(OPTrace * _Nullable)parentTrace;

/// 套件WebView初始化方法
/// @param frame 尺寸
/// @param config WebView初始化配置
/// @param parentTrace trace
/// @param webviewDelegate LarkWebView回调Delegate
- (instancetype)initWithFrame:(CGRect)frame config:(LarkWebViewConfig *)config parentTrace:(OPTrace * _Nullable)parentTrace webviewDelegate:(id <LarkWebViewDelegate> _Nullable)webviewDelegate;

- (void)recordWebviewCustomEvent:(LarkWebViewCustomEvent)event;
- (BOOL)webviewCustomEventDidHappen:(LarkWebViewCustomEvent)event;
- (UInt64)customEventInfo;
@end

NS_ASSUME_NONNULL_END
