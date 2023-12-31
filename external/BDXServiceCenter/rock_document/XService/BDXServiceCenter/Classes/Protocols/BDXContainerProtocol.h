//
//  BDXContainerProtocol.h
//  Pods
//
//  Created by tianbaideng on 2021/3/15.
//

NS_ASSUME_NONNULL_BEGIN

@class BDXBridgeMethod;
@class BDXContext;

typedef NS_ENUM(NSInteger, BDXEngineType) {
    BDXEngineTypeUnknown = 0, // load error
    BDXEngineTypeLynx, // Lynx Container
    BDXEngineTypeWeb,    // Web Container
};

@protocol BDXResourceProtocol;
@protocol BDXContainerLifecycleProtocol;
@protocol BDXKitViewProtocol;

@protocol BDXContainerProtocol <NSObject>

// 全局上下文信息
@property(nonatomic, strong) BDXContext *context;

// 当前容器是否在后台
@property(nonatomic, assign) BOOL hybridInBackground;
// 当前容器是否可见
@property(nonatomic, assign) BOOL hybridAppeared;
// 容器ID
@property(nonatomic, copy, readonly) NSString *containerID;
// 打开的原始URL
@property(nonatomic, strong, readonly) NSURL *originURL;
// Container kitview type
@property(nonatomic, assign, readonly) BDXEngineType viewType;

@property(nonatomic, weak) id<BDXContainerLifecycleProtocol> containerLifecycleDelegate;

@property(nonatomic, readonly) UIView<BDXKitViewProtocol> *kitView;

/// 主动或者被动处理对应的状态，比如发送事件给JS
- (void)handleViewDidAppear;
- (void)handleViewDidDisappear;
- (void)handleBecomeActive;
- (void)handleResignActive;

/// 注册xbridge方法，需要在loadURL之前调用
/// @param bridgeMethods xbridge方法列表
- (void)registerXBridgeMethod:(nullable NSArray<Class> *)bridgeMethods;

- (void)reload;
- (void)reloadWithContext:(BDXContext *)context;

@optional
- (void)updateTitle:(NSString *)title;
// 注册 Lynx/Web 自定义组件（目前 Web 不消费）
- (void)registerUI:(Class)ui withName:(NSString *)name;
// 更新 Lynx/Web 数据，data 可以是 NSString、NSDictionary，也可以是 TemplateData，内部会做处理（目前 Web 不消费）
- (void)updateData:(id)data processorName:(NSString *)processor;

@end

@protocol BDXContainerLifecycleProtocol <NSObject>

@optional

/// container size changed
/// @param container container
/// @param size size
- (void)container:(id<BDXContainerProtocol>)container didChangeIntrinsicContentSize:(CGSize)size;

/// container will start loading
/// @param container container
- (void)containerWillStartLoading:(id<BDXContainerProtocol>)container;

/// container will start loading
- (void)containerDidStartLoading:(id<BDXContainerProtocol>)container;

/// start fetch resource
/// @param container container
/// @param url resource url
- (void)container:(id<BDXContainerProtocol>)container didStartFetchResourceWithURL:(NSString *_Nullable)url;

/// main resource fetched
/// @param container container
/// @param resource reosurce provider
/// @param error error details
- (void)container:(id<BDXContainerProtocol>)container didFetchedResource:(nullable id<BDXResourceProtocol>)resource error:(nullable NSError *)error;

/// firsrt screen
/// @param container container
- (void)containerDidFirstScreen:(id<BDXContainerProtocol>)container;

/// load sucess
/// @param container container
/// @param url url
- (void)container:(id<BDXContainerProtocol>)container didFinishLoadWithURL:(NSString *_Nullable)url;

/// load failed
/// @param container container
/// @param url url
/// @param error error details
- (void)container:(id<BDXContainerProtocol>)container didLoadFailedWithUrl:(NSString *_Nullable)url error:(nullable NSError *)error;

/// container view upated
/// @param container container
- (void)containerDidUpdate:(id<BDXContainerProtocol>)container;

/// some error occurs
/// @param container container
/// @param error  error details
- (void)container:(id<BDXContainerProtocol>)container didRecieveError:(NSError *_Nullable)error;

/// performance
/// @param container view
/// @param perfDict performance
- (void)container:(id<BDXContainerProtocol>)view didReceivePerformance:(NSDictionary *)perfDict;

@end

NS_ASSUME_NONNULL_END
