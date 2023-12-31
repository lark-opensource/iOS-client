//
//  OPMicroAppJSRuntimeProtocol.h
//  TTMicroApp
//
//  Created by yi on 2021/12/8.
//
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/OPJSEngineProtocol.h>
#import <OPFoundation/BDPModuleEngineType.h>
#import <OPFoundation/BDPTracing.h>
#import <OPJSEngine/OPJSEngineDefine.h>

@protocol OPMicroAppJSRuntimeProtocol;
/// FROM: OPJSEngineProtocol.h
typedef id<OPMicroAppJSRuntimeProtocol> BDPMicroAppJSRuntimeEngine;

@protocol BDPJSRuntimeDelegate;
@protocol BDPJSRuntimeAyncCallProtocol;
@class JSContext;
@class BDPMultiDelegateProxy;
@protocol OPMicroAppJSRuntimeProtocol <OPBaseJSRuntimeProtocol, BDPJSRuntimeAyncCallProtocol>
@property (nonatomic, weak) id<BDPJSRuntimeDelegate> _Nullable delegate;    // 给BDPAppPage用
@property (nonatomic, strong, readonly) BDPMultiDelegateProxy<BDPJSRuntimeDelegate>* _Nullable otherDelegates;  // <BDPJSContextInjectProtocol> 给其他组件或逻辑层做扩展用
@property (nonatomic, assign) BOOL isFireEventReady;
@property (nonatomic, assign) BOOL isContextReady; // onDocumentReady
/// jscore.js执行耗时, 执行成功非0, 失败或未执行完成为0
@property (nonatomic, assign) NSInteger jsCoreExecCost;
/// 保存已经执行了的JS文件路径（外部可以用来判断是否已经执行过了，可避免重复执行）
@property (nonatomic, strong, readonly) NSArray<NSString *> * executedJSPathes;
@property (nonatomic, assign) BDPType appType;
// 用于端监控
@property (nonatomic, strong, nullable) NSDate *loadTmaCoreBegin;
@property (nonatomic, strong, nullable) NSDate *loadTmaCoreEnd;
@property (nonatomic, weak, readonly) JSContext* _Nullable jsContext; // 真正的js虚拟机

@property (nonatomic, assign) NSTimeInterval finishedInitTime;
@property (nonatomic, copy) NSString * preloadFrom;

//从关于页逻辑中触发的 onUpdateReady 事件，native->jsc
-(void)sendOnUpdateReadyEventFromUpdateManager;
//从异步起动流程逻辑中触发的 onUpdateReady 事件，native->jsc
-(void)sendOnUpdateReadyEventFromAsyncStartupWithError:(NSError * _Nullable)error;
//成功更新后更新过期时间戳
-(void)updateTimestampAfterApplyUpdateSuccessWith:(BDPUniqueID * _Nonnull)uniqueID;
//是否可以执行更新操作
//更新操作指1、发送onUpdateReady事件， 2、applyUpdate调用，允许重启App
-(BOOL)shouldSendOnUpdateReadyEventOrApplyUpdateWith:(BDPUniqueID * _Nonnull)uniqueID;

- (void)bindTracing:(BDPTracing *)trace;
- (BDPTracing *)trace;

- (void)updateUniqueID:(BDPUniqueID *)uniqueID delegate:(id<BDPJSRuntimeDelegate>)delegate;

@property (nonatomic, assign) BOOL isSocketDebug;
- (void) finishDebug;

- (void)handleInvokeInterruptionWithStatus:(GeneralJSRuntimeRenderStatus)status data:(NSDictionary *)data;

@optional

- (void)appConfigLoaded:(BDPUniqueID *)uniqueID;

@end

