//
//  OPMicroAppJSRuntime.h
//  TTMicroApp
//
//  Created by yi on 2021/12/8.
//

#import <Foundation/Foundation.h>

#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPPluginManagerAdapter/BDPJSBridge.h>
#import <OPJSEngine/BDPMultiDelegateProxy.h>
#import <OPJSEngine/OPJSEngine-Swift.h>
#import "OPMicroAppJSRuntimeProtocol.h"
#import <OPJSEngine/GeneralJSRuntimeDelegate.h>

typedef void(^BDPJSRuntimeCoreCompleteBlock)(void);
typedef NS_ENUM(NSInteger, OPRuntimeType);

@class GeneralJSRuntime;
@class BDPTracing;
#pragma mark - BDPJSRuntime

/**
 * 小程序逻辑层执行所在JS虚拟机、JSContext及相应调用方法的封装。2.10.0中会实现JSContext异步分线程执行，目前版本在主线程执行。
 * 1.对js提供调用native的基本接口，通过向jscontext注入ttJSCore对象，提供invoke、publish等方法。2.invoke用于调用native端静态插件和动态插件。
 * 3.publish用于向每个BDPAppPage轮流发一遍消息。
 * 4.fireEvent接口用于Native向JSC层发消息，当isFireEventReady标志位未设置时，native的调用都会先排入队列，JSC和Webview的js基础库都加载成功后再循环执行。
 *
 * 具体加载时序图见：https://bytedance.feishu.cn/space/doc/doccnUnYJ4KNWZd6rjqjXd#
 */
@interface OPMicroAppJSRuntime : NSObject<BDPJSBridgeEngineProtocol, BDPJSRuntimeAyncCallProtocol, BDPEngineProtocol, OPMicroAppJSRuntimeProtocol, GeneralJSRuntimeDelegate>

@property (nonatomic, strong) BDPUniqueID * _Nonnull uniqueID;
@property (nonatomic, weak) id<BDPJSRuntimeDelegate> _Nullable delegate;    // 给BDPAppPage用
@property (nonatomic, strong, readonly) BDPMultiDelegateProxy<BDPJSRuntimeDelegate>* _Nullable otherDelegates;  // <BDPJSContextInjectProtocol> 给其他组件或逻辑层做扩展用
@property (nonatomic, assign) BOOL isContextReady; // onDocumentReady
@property (nonatomic, assign) BOOL isFireEventReady;
/// jscore.js执行耗时, 执行成功非0, 失败或未执行完成为0
@property (nonatomic, assign) NSInteger jsCoreExecCost;
/// 保存已经执行了的JS文件路径（外部可以用来判断是否已经执行过了，可避免重复执行）
@property (nonatomic, strong, readonly) NSArray<NSString *> * executedJSPathes;
// jscontext分线程
@property (nonatomic, weak, readonly) JSContext* _Nullable jsContext; // 真正的js虚拟机

@property (nonatomic, assign) BDPType appType;
@property (nonatomic, strong) GeneralJSRuntime *jsRuntime;
// 用于端监控
@property (nonatomic, strong, nullable) NSDate *loadTmaCoreBegin;
@property (nonatomic, strong, nullable) NSDate *loadTmaCoreEnd;

@property (nonatomic, assign, readwrite) BOOL isJSContextThreadForceStopped;    // js是否是在异步线程执行

@property (nonatomic, assign) NSTimeInterval finishedInitTime;
@property (nonatomic, copy) NSString * preloadFrom;

// debug
/// 构造方法
/// @param address 建立连接的地址
/// @param completeBlk 完成回调
- (instancetype)initWithAddress:(NSString *)address completeBlk:(BDPJSRuntimeCoreCompleteBlock)completeBlk;
- (instancetype)initWithAddress:(NSString *)address completeBlk:(BDPJSRuntimeCoreCompleteBlock)completeBlk runtimeType:(OPRuntimeType)runtimeType;

- (void)finishDebug;

@property (nonatomic, assign) BOOL isSocketDebug;
// init
- (instancetype)initWithCoreCompleteBlk:(BDPJSRuntimeCoreCompleteBlock)completeBlk;
- (instancetype)initWithCoreCompleteBlk:(BDPJSRuntimeCoreCompleteBlock)completeBlk withAppType:(BDPType )appType;
- (instancetype)initWithCoreCompleteBlk:(BDPJSRuntimeCoreCompleteBlock)completeBlk withAppType:(BDPType )appType runtimeType:(OPRuntimeType)runtimeType;

@property (nonatomic, assign) OPRuntimeType runtimeType;

@end

//发送更新事件的逻辑统一收口
//https://bytedance.feishu.cn/docs/doccnrGxIrFALHFIwJmLh5A04yd
@interface OPMicroAppJSRuntime (UpdateStrategyControl)
//从关于页逻辑中触发的 onUpdateReady 事件，native->jsc
-(void)sendOnUpdateReadyEventFromUpdateManager;
//从异步起动流程逻辑中触发的 onUpdateReady 事件，native->jsc
-(void)sendOnUpdateReadyEventFromAsyncStartupWithError:(NSError * _Nullable)error;
//成功更新后更新过期时间戳
-(void)updateTimestampAfterApplyUpdateSuccessWith:(BDPUniqueID * _Nonnull)uniqueID;
//是否可以执行更新操作
//更新操作指1、发送onUpdateReady事件， 2、applyUpdate调用，允许重启App
-(BOOL)shouldSendOnUpdateReadyEventOrApplyUpdateWith:(BDPUniqueID * _Nonnull)uniqueID;
@end

