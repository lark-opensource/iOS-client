//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <vmsdk/js_native_api.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KryptonService;

@interface KryptonApp : NSObject

/// Krypton app init.
/// Any thread.
- (instancetype)init;

/// Register a service in krypton app.
/// @param protocol Obj-C protocol
/// @param impl  the implementation of the service
- (void)registerService:(Protocol*)protocol withImpl:(id<KryptonService>)impl;

/// Get registered service in krypton app.
/// @param protocol Obj-C protocol
- (id)getService:(Protocol*)protocol;

/// Krypton app bootstrap.
/// JS thread only!
/// @param env a pointer to initialized napi_env
- (void)bootstrap:(napi_env)env;

/// Krypton app destroy.
/// JS thread only!
- (void)destroy;

/// Krypton app onHide.
/// JS thread only!
- (void)onHide;

/// Krypton app onShow.
/// JS thread only!
- (void)onShow;

/// Pause krypton app.
/// Should be called when the application becomes background.
/// JS thread only!
- (void)pause;

/// Resume krypton app.
/// Should be called when the application becomes foreground.
/// JS thread only!
- (void)resume;

/// todo: may be replaced with in other way
- (void)setRuntimeActor:(void*)actorNativePtr;
- (void)setRuntimeTaskRunner:(void*)taskRunnerNativePtr;
- (void)setGPUTaskRunner:(void*)taskRunnerNativePtr;

- (int64_t)getNativeHandler;

@end

NS_ASSUME_NONNULL_END
