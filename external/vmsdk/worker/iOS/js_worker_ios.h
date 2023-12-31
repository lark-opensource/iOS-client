// Copyright 2021 The VMSDK author. All rights reserved.

#import <Foundation/Foundation.h>
#if __has_include(<vmsdk/iOS/framework/JSModule.h>)
#import <vmsdk/iOS/framework/JSModule.h>
#elif __has_include(<vmsdk/jsb/iOS/framework/JSModule.h>)
#import <vmsdk/jsb/iOS/framework/JSModule.h>
#else
#import "jsb/iOS/framework/JSModule.h"
#endif

#if __has_include(<vmsdk/iOS/net/request_ios.h>)
#import <vmsdk/iOS/net/request_ios.h>
#elif __has_include(<vmsdk/worker/iOS/net/request_ios.h>)
#import <vmsdk/worker/iOS/net/request_ios.h>
#else
#import "worker/iOS/net/request_ios.h"
#endif

#if __has_include(<vmsdk/iOS/net/response_ios.h>)
#import <vmsdk/iOS/net/response_ios.h>
#elif __has_include(<vmsdk/worker/iOS/net/response_ios.h>)
#import <vmsdk/worker/iOS/net/response_ios.h>
#else
#import "worker/iOS/net/response_ios.h"
#endif

@protocol MessageCallback <NSObject>
- (void)handleMessage:(NSString *_Nonnull)msg;
@end

@protocol ErrorCallback <NSObject>
- (void)handleError:(NSString *_Nonnull)msg;
@end

typedef void (^NetCallbackBlock)(NSError *_Nullable error, NSData *_Nullable body,
                                 ResponseIOS *_Nonnull response);

@protocol HTTPReleaseDelegate <NSObject>
- (void)cancel;
@end

@protocol WorkerDelegate <NSObject>
- (NSString *_Nonnull)fetchWithUrlSync:(NSString *_Nonnull)msg;
- (id<HTTPReleaseDelegate> _Nullable)
     loadAsync:(RequestIOS *_Nonnull)request
    completion:(void (^_Nonnull)(NSError *_Nullable error, NSData *_Nullable body,
                                 ResponseIOS *_Nonnull response))completion;
@end

@interface JsWorkerIOS : NSObject
@property(readwrite, nullable, weak) id<MessageCallback> onMessageCallback;
@property(readwrite, nullable, weak) id<ErrorCallback> onErrorCallback;
@property(readwrite, nullable, weak, nonatomic) id<WorkerDelegate> workerDelegate;

// useJSCore false -> QuickJS; true -> JSCore
- (instancetype _Nonnull)init:(Boolean)useJSCore
                        param:(NSString *_Nullable)path
                 isMutiThread:(Boolean)isMutiThread
                     biz_name:(NSString *_Nullable)biz_name;
- (instancetype _Nonnull)init:(Boolean)useJSCore
                        param:(NSString *_Nullable)path
                 isMutiThread:(Boolean)isMutiThread;
- (instancetype _Nonnull)init:(Boolean)useJSCore param:(NSString *_Nullable)path;
- (instancetype _Nonnull)init:(Boolean)useJSCore;
- (instancetype _Nonnull)init;

- (void)evaluateJavaScript:(NSString *_Nonnull)script;
- (void)evaluateJavaScript:(NSString *_Nonnull)script param:(NSString *_Nullable)filename;
- (void)terminate;
- (void)postMessage:(NSString *_Nonnull)msg;

- (void)onMessage:(NSString *_Nonnull)msg;
- (void)onError:(NSString *_Nonnull)msg;
- (NSString *_Nonnull)FetchJsWithUrlSync:(NSString *_Nonnull)url;
- (void)Fetch:(NSString *_Nonnull)url
         param:(NSString *_Nonnull)param
      bodyData:(const void *_Nullable)bodyData
    bodyLength:(int)bodyLength
        delPtr:(void *_Nonnull)delPtr;

- (void)initJSBridge;
- (void)registerModule:(Class<JSModule> _Nonnull)module;
- (void)registerModule:(Class<JSModule> _Nonnull)module param:(nullable id)param;
- (void *_Nonnull)getTaskRunnerManufacture;
- (void *_Nonnull)getWorker;
- (void)postOnJSRunner:(void (^_Nonnull)(void))runnable;
- (void)postOnJSRunnerDelay:(void (^_Nonnull)(void))runnable
          delayMilliseconds:(long)delayMilliseconds;
- (void)setGlobalProperties:(NSDictionary *_Nonnull)props;
- (void)setContextName:(NSString *_Nonnull)name;
- (void)invokeJavaScriptModule:(NSString *_Nonnull)moduleName
                    methodName:(NSString *_Nonnull)methodName
                        params:(NSArray *_Nullable)params;
- (id _Nullable)invokeJavaScriptModuleSync:(NSString *_Nonnull)moduleName
                                methodName:(NSString *_Nonnull)methodName
                                    params:(NSArray *_Nullable)params;
- (void)invokeJavaScriptFunction:(NSString *_Nonnull)methodName params:(NSArray *_Nullable)params;
- (id _Nullable)invokeJavaScriptFunctionSync:(NSString *_Nonnull)methodName
                                      params:(NSArray *_Nullable)params;
- (bool)isRunning;
- (NSString *_Nullable)getCacheFilePath;
@end
