//
//  Created by 王浩宇 on 2018/11/18.
//

#import "BDPDefineBase.h"
#import <OPPluginManagerAdapter/BDPJSBridge.h>
#import "BDPPerformanceMonitor.h"
#import <OPFoundation/BDPUniqueID.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <LarkWebViewContainer/LarkWebView.h>
#import <OPFoundation/BDPSDKConfig.h>
#import <OPFoundation/BDPSTLQueue.h>

NS_ASSUME_NONNULL_BEGIN

@class LarkWebViewBizType;

@protocol BDPWebViewInjectProtocol <NSObject>
@optional
- (void)webViewInvokeMethod:(NSString *)event param:(NSDictionary *)param;
- (void)handleReportTimelineDomReady; // 替代 webViewInvokeMethod 方法
- (void)webViewPublishMessage:(NSString *)event param:(NSDictionary *)param;
- (void)webViewOnDocumentReady;
- (UIViewController *)webViewController;
@end

@interface BDPWebView : LarkWebView<BDPJSBridgeEngineProtocol, BDPEngineProtocol, WKNavigationDelegate, WKScriptMessageHandler>
@property (nonatomic, assign) BOOL isFireEventReady;
/// 性能打点管理类 原封不动迁移 未修改逻辑
@property (nonatomic, strong) BDPPerformanceMonitor<BDPWebViewTiming> *bwv_performanceMonitor;
@property (nonatomic, strong, readonly) BDPSTLQueue *bwv_fireEventQueue;
@property (nonatomic, weak, readonly, nullable) id<BDPWebViewInjectProtocol> bdpWebViewInjectdelegate;
#pragma mark BDPEngineProtocol
- (instancetype _Nonnull)init NS_UNAVAILABLE;
+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame
                       config:(WKWebViewConfiguration *)config
                     delegate:(id<BDPWebViewInjectProtocol>)delegate
                      bizType:(LarkWebViewBizType *)bizType
    advancedMonitorInfoEnable:(BOOL)advancedMonitorInfoEnable;
- (void)setupWebViewWithUniqueID:(BDPUniqueID *)uniqueID;
- (void)fireEventWithArguments:(NSArray *)arguments;
- (void)invokeApiName:(NSString *)apiName data:(NSDictionary *)data callbackID:(nullable NSString *)callbackID extra:(nullable NSDictionary *)extra useNewBridge:(BOOL)useNewBridge complete:(void(^)(NSDictionary *, BDPJSBridgeCallBackType))complete;
- (void)publishMsgWithApiName:(NSString * _Nonnull)apiName paramsStr:(NSString * _Nonnull)paramsStr webViewId:(NSInteger)webViewId;
@end

NS_ASSUME_NONNULL_END
