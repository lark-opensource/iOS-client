//
//  BDPJSRunningThread.h
//  Timor
//
//  Created by dingruoshan on 2019/6/14.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#include <mach/mach_types.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^BDPJSThreadCrashHandler)(NSString *exceptionType,
                                       thread_t keyThread,
                                       NSUInteger skippedDepth,
                                       NSDictionary<NSString *, id> *customParams,
                                       NSDictionary<NSString *, id> *filters,
                                       void(^callback)(NSError * error));

@class BDPJSRunningThread;

@protocol BDPJSRunningThreadDelegate <NSObject>
@optional
- (void)onBDPJSRunningThreadForceStopped:(BDPJSRunningThread*)thread exceptionMsg:(NSString * _Nullable)exceptionMsg;
@end

@interface BDPJSRunningThread : NSThread

@property (nonatomic, readonly) NSRunLoop *runLoop;
@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic,weak) NSRunLoop* weakRunLoop;
@property (nonatomic,strong) JSContext* jsContext;
@property (nonatomic,strong) JSVirtualMachine* jsVM;

@property (nonatomic,assign) BOOL forceStopped;
@property (nonatomic,assign) thread_t threadId;
@property (nonatomic,weak) id<BDPJSRunningThreadDelegate> delegate;

- (instancetype)initWithName:(NSString*)threadName;
- (void)startThread:(BOOL)waitUntilStarted;
- (void)stopThread:(BOOL)waitUntilDone;
- (void)forceStopThread:(NSString * _Nullable)exceptionMsg;

+ (NSInteger)runningThreadCount;    // 存活的thread统计，为了方便检查调试和确认线程能够正确销毁
+ (void)enableThreadProtection:(BOOL)enabled;
+ (BOOL)isThreadProtectionEnabled;
+ (void)setCrashHandler:(BDPJSThreadCrashHandler)handler;

@end

NS_ASSUME_NONNULL_END
