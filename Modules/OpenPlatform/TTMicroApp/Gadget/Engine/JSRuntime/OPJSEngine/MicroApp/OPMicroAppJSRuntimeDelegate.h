//
//  OPMicroAppJSRuntimeDelegate.h
//  OPJSEngine
//
//  Created by yi on 2021/12/25.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>


// loading加载时回调外层，告诉外层需要加载的注入基础库js、事件回调、异常等
@protocol BDPJSRuntimeDelegate <NSObject>
@optional
// Common (Game & App)
- (void)onJSRuntimeLogException:(JSValue *)exception;

// Common (Game & App)
- (void)jsRuntimePublishMessage:(NSString *)event param:(NSDictionary *)param appPageIDs:(NSArray<NSNumber *> *)appPageIDs;

// Source Controller
- (UIViewController *)jsRuntimeController;

// Only For App
- (void)jsRuntimeOnDocumentReady;

// 真机调试
- (void)onSocketDebugConnected; // 连接建立
- (void)onSocketDebugDisconnected; // 连接断开
- (void)onSocketDebugPauseInspector; // 命中断点
- (void)onSocketDebugResumeInspector; // 断点继续
- (void)onSocketDebugConnectFailed; // 连接失败

@end


#import <OPJSEngine/BDPJSRunningThread.h>

#pragma mark - <BDPJSContextInjectProtocol>

// jscontext异步执行相关
@protocol BDPJSRuntimeAyncCallProtocol <NSObject>
// 异常日志打印
- (void)logException:(JSContext *)context exception:(JSValue *)exception;
// 脚本加载
- (void)loadScriptWithURL:(NSURL *)url callbackIsMainThread: (BOOL)callbackIsMainThread completion:(void (^ __nullable)(void))completion;
- (void)loadScript:(NSString *)script withFileSource:(NSString *)fileSource  callbackIsMainThread: (BOOL)callbackIsMainThread completion:(void (^ __nullable)(void))completion;
// JSContext所在线程队列调用相关
- (void)dispatchAsyncInJSContextThread:(dispatch_block_t)blk;
- (void)cancelAllPendingAsyncDispatch;
- (void)enableAcceptAsyncDispatch:(BOOL)enabled;

// 当jsc线程发生异常被兜底销毁时，这里返回为YES，正常情况为NO
- (BOOL)isJSContextThreadForceStopped;

// 是否开启jsc异常保护兜底
+ (void)enableJSContextThreadProtection:(BOOL)enabled;
+ (BOOL)isJSContextThreadProtectionEnabled;
// 2019-5-24 为了解除BDPJSContext类对heimdallr的依赖,使用外部传入handler的方式实现(BDPExceptionMonitor中会在load的时候传入handler)
+ (void)setJSThreadCrashHandler:(nullable BDPJSThreadCrashHandler)handler;

@end
