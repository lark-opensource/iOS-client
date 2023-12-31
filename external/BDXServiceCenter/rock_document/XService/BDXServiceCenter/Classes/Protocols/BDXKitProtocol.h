//
//  BDXKitProtocol.h
//  Pods
//
//  Created by tianbaideng on 2021/3/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const kBDXKitEventViewDidAppear;
FOUNDATION_EXPORT NSString *const kBDXKitEventViewDidDisappear;
FOUNDATION_EXPORT NSString *const kBDXKitEventAppDidBecomeActive;
FOUNDATION_EXPORT NSString *const kBDXKitEventAppResignActive;

@class BDXContext;
@class BDXBridgeMethod;
@protocol BDXResourceProtocol;
@protocol BDXKitViewProtocol;

@protocol BDXKitViewLifecycleProtocol <NSObject>

@optional

/// 页面大小发生改变
/// @param size 变化后的大小
- (void)view:(id<BDXKitViewProtocol>)view didChangeIntrinsicContentSize:(CGSize)size;

/// 开始加载URL
- (void)viewDidStartLoading:(id<BDXKitViewProtocol>)view;

/// 开始加载某个资源
/// @param url 资源URL
- (void)view:(id<BDXKitViewProtocol>)view didStartFetchResourceWithURL:(NSString *_Nullable)url;

/// 主资源获取到的时机
/// @param resource 资源详细信息
/// @param error 错误信息
- (void)view:(id<BDXKitViewProtocol>)view didFetchedResource:(nullable id<BDXResourceProtocol>)resource error:(nullable NSError *)error;

/// 首屏
- (void)viewDidFirstScreen:(id<BDXKitViewProtocol>)view;

/// 整个view加载生命周期结束，加载成功，跟viewDidLoadFailedWithUrl不会同时调用
/// @param url 页面主资源URL
- (void)view:(id<BDXKitViewProtocol>)view didFinishLoadWithURL:(NSString *_Nullable)url;

/// 整个view加载生命周期结束，加载失败
/// @param url 页面主资源URL
/// @param error 错误信息
- (void)view:(id<BDXKitViewProtocol>)view didLoadFailedWithUrl:(NSString *_Nullable)url error:(nullable NSError *)error;

/// 页面更新
- (void)viewDidUpdate:(id<BDXKitViewProtocol>)view;

/// 页面加载中或者页面加载成功后在运行期可能会发生的错误
/// @param error 错误信息
- (void)view:(id<BDXKitViewProtocol>)view didRecieveError:(NSError *_Nullable)error;

/// 性能数据透传
/// @param perfDict 性能数据字典
- (void)view:(id<BDXKitViewProtocol>)view didReceivePerformance:(NSDictionary *)perfDict;

@end

@interface BDXKitParams : NSObject

@property (nonatomic, strong) BDXContext *context;

@end

@protocol BDXKitViewProtocol <NSObject>

// 容器ID
@property(nonatomic, copy, readonly) NSString *containerID;

// 实际UIView，可以是lynxview或者webview，在configWithParams之前调用为nil
@property(nonatomic, strong, readonly, nullable) UIView *rawView;

// 配置初始化参数，params可以为BDXLynxKitParams
@property(nonatomic, strong, readonly) BDXKitParams *params;

// bridge instance
@property(nonatomic, strong, readonly) id kitBridge;

// 生命周期协议
@property(nonatomic, weak) id<BDXKitViewLifecycleProtocol> lifecycleDelegate;

// 配置初始化参数，params可以为BDXLynxKitParams
- (void)configWithParams:(BDXKitParams *)params;

// 加载lynxview或者webview
- (void)load;

// 重新加载lynxview或者webview
- (void)reloadWithContext:(BDXContext *)context;

// 触发布局
- (void)triggerLayout;

/// 触发前端的onShow
/// @param params 类似 @{@"event":kBDXKitEventViewDidAppear}
- (void)onShow:(NSDictionary *)params;

/// // 触发前端的onHide
/// @param params  类似 @{@"event":kBDXKitEventViewDidDisappear}
- (void)onHide:(NSDictionary *)params;

/// 向Lynx或者Webview发送事件
/// @param event 跟前端约定的事件名称
/// @param params 事件携带的参数
- (void)sendEvent:(NSString *_Nonnull)event params:(nullable NSDictionary *)params;
- (void)sendEvent:(NSString *_Nonnull)event params:(nullable NSDictionary *)params callback:(nullable void (^)(id _Nullable res))callback;

- (void)configGlobalProps:(nonnull id)globalProps;

/// 更新Lynx或者Webview数据
/// @param data 可以是NSDictionary或者LynxTemplateData
- (void)updateWithData:(id _Nullable)data;

// 更新Lynx/Web 数据，data 可以是 NSString、NSDictionary，也可以是 TemplateData（Web 不消费），内部会做处理
- (void)updateData:(id _Nullable)data processorName:(NSString * _Nullable)processor;

// 注册Xbridge方法, Class必须集成自BDXBridgeMethod
- (void)registerXBridgeMethod:(NSArray<Class> *)bridgeMethods;
- (void)registerXBridgeMethodInstance:(NSArray<BDXBridgeMethod *> *)bridgeMethods;

@optional

- (void)registerUI:(Class)ui withName:(NSString *)name;

// 更新主题
- (void)updateAppThemeWithKey:(NSString *)themeKey value:(NSString *)appTheme;

@end

NS_ASSUME_NONNULL_END
