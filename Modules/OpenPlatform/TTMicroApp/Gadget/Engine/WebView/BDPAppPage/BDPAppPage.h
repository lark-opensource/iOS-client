//
//  Created by 王浩宇 on 2018/11/18.
//

#import <Foundation/Foundation.h>
#import "BDPWebView.h"
#import "BDPAppConfig.h"


@class BDPAppPage;

/// 用于处理AppPage中出发的数据加载错误的代理
@protocol BDPAppPageDataLoadErrorHandleDelegate <NSObject>

- (void)appPage:(BDPAppPage *)appPage didTriggerDataLoadError:(NSError *)error;

@end

NS_ASSUME_NONNULL_BEGIN

@class BDPWindowConfig;
@class BDPAppPageController;

@protocol BDPAppPageProtocol <NSObject>

@optional
- (void)handleReportTimelineDomReady;
- (void)appPagePublishMessage:(BDPAppPage *)appPage event:(NSString *)event param:(NSDictionary *)param;
- (BOOL)appPageShouldTrackPageFrameJSLoadTime;
@end

/// 小程序WebView 灰度阶段和上面保持一致
@interface BDPAppPage : BDPWebView
@property (nonatomic, weak) id<BDPAppPageProtocol> appPageDelegate;
@property (nonatomic, assign) BOOL isNeedRoute;
@property (nonatomic, assign) BOOL isHasWebView;
/** html Document Ready标志 */
@property (nonatomic, assign) BOOL isAppPageReady;
@property (nonatomic, assign) NSInteger appPageID;

@property (nonatomic, copy) NSString *bap_path;
@property (nonatomic, copy) NSString *bap_queryString;
@property (nonatomic, copy) NSString *bap_absolutePathString;
@property (nonatomic, copy) NSString *bdp_openType;
@property (nonatomic, strong) BDPAppConfig *bap_config;
@property (nonatomic, strong) BDPPageConfig *bap_pageConfig;
@property (nonatomic, copy) NSDictionary *bap_vdom;
/// 开始加载 html 时间
@property (nonatomic, strong) NSDate *bap_loadHtmlBegin;

@property (nonatomic, assign, readonly) int totalTerminatedCount; //与terminatedCount的区别在于：不清零，仅用于统计

/// 待处理的数据加载异常
@property (nonatomic, strong) NSError *pendingDataLoadError;
/// 处理数据加载异常的代理
@property(nonatomic, weak) id<BDPAppPageDataLoadErrorHandleDelegate> dataLoadErrorHandleDelegate;

///当前分包case下，app-service.js和page-frame.js是否已经执行完成
@property (nonatomic, assign) BOOL isSubPageFrameReady;
@property (nonatomic, assign, readonly) BOOL didLoadFrameScript;
@property (nonatomic, assign) BOOL  disableSetDarkColorInInit;

@property (nonatomic, assign) NSTimeInterval finishedInitTime;
@property (nonatomic, copy) NSString * preloadFrom;

@property (nonatomic, assign, readonly) BOOL enableSchemeHandler;

- (instancetype _Nonnull)init NS_UNAVAILABLE;
+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration NS_UNAVAILABLE;
/// 2019-5-15 拆分通用page-frame之后的版本,使用下面两个方法去初始化(拆分后的加载步骤: https://bytedance.feishu.cn/space/doc/doccnz5HdSr5cmbZo4wZhg#)
- (instancetype)initWithFrame:(CGRect)frame
                     delegate:(id<BDPAppPageProtocol>)delegate enableSchemeHandler:(BOOL)enableHandler;
- (void)setupAppPageWithUniqueID:(BDPUniqueID *)uniqueID;
- (BDPAppPageController * _Nullable)parentController;
- (void)publishEvent:(NSString *)event param:(NSDictionary *)param;
/** 当容器将AppPage加载到视图上后，调用该方法 */
- (void)appPageViewDidLoad;
/// 尝试加载vdom
- (void)tryLoadVdom;
/// 重新加载当前webview，并将之前已经自动重置过的次数进行清零
- (void)reloadAndRefreshTerminateState;

//分包资源准备好之后单独出发一次，别的场景请勿使用
-(void)loadPathScriptOldWayIfNeedWhenUsingSubpackage;

-(void)pageDidAppear;

@end

extern BOOL IsGadgetWebView(id object);

typedef void (^EvaluateDynamicCompentJSCallback)(void);

@interface BDPAppPage (DynamicCompnent)
/// 需要执行JS代码的callback数组
/// 场景: 一个appPage可能需要延迟执行多个插件代码
@property (nonatomic, strong) NSMutableArray *evaluateDynamicCompentCallbackArray;

/// 添加执行插件JS代码的block
- (void)appendEvaluateDynamicComponentJSCallback:(EvaluateDynamicCompentJSCallback)callback;

/// 加载执行插件JS代码的block(在webviewOnDocumentReady)
- (void)loadDynamicComponentIfNeed;
@end

NS_ASSUME_NONNULL_END
