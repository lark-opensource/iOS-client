//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "KryptonApp.h"
#import "KryptonLLog.h"
#import "KryptonService.h"
#include "canvas/ios/canvas_app_ios.h"
#include "canvas/platform/ios/resource_loader_ios.h"
#include "jsbridge/napi/napi_environment.h"

@interface KryptonApp ()
@property(nonatomic, readonly) NSMutableDictionary<NSString *, id<KryptonService>> *serviceMap;
@property(nonatomic, readonly) NSMutableArray<id<KryptonService>> *serviceArray;
@end

@implementation KryptonApp {
  bool _destroyed;
  std::shared_ptr<lynx::canvas::CanvasApp> _nativeApp;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _serviceArray = [[NSMutableArray alloc] init];
    _serviceMap = [[NSMutableDictionary alloc] init];
    _destroyed = NO;

    [self createCanvasApp];
  }
  return self;
}

- (void)createCanvasApp {
  auto canvas_app = new lynx::canvas::CanvasAppIOS(self);

  canvas_app->SetResourceLoader(std::make_unique<lynx::canvas::ResourceLoaderIOS>(self));

  CGFloat scale = [UIScreen mainScreen].scale;
  canvas_app->SetDevicePixelRatio(scale);

  _nativeApp = std::shared_ptr<lynx::canvas::CanvasApp>(canvas_app);
}

- (void)registerService:(Protocol *)protocol withImpl:(id<KryptonService>)impl {
  if (_destroyed) {
    return;
  }

  assert([impl conformsToProtocol:protocol]);

  KRYPTON_LLogInfo(@"register service %@ with class %@", NSStringFromProtocol(protocol),
                   NSStringFromClass([impl class]));

  [self.serviceMap setObject:impl forKey:NSStringFromProtocol(protocol)];
  [self.serviceArray addObject:impl];
}

- (id)getService:(Protocol *)protocol {
  id impl = [self.serviceMap objectForKey:NSStringFromProtocol(protocol)];
  assert([impl conformsToProtocol:protocol]);

  return impl;
}

- (void)bootstrap:(napi_env)env {
  if (_destroyed) {
    return;
  }

  KRYPTON_LLogInfo(@"KryptonApp bootstrap");

  DCHECK(env);

  for (id<KryptonService> service in self.serviceArray) {
    if ([service respondsToSelector:@selector(onBootstrap:)]) {
      [service onBootstrap:self];
    }
  }

  auto piper_env = lynx::piper::NapiEnvironment::From(env);
  DCHECK(piper_env);

  _nativeApp->OnRuntimeAttach(piper_env);
}

- (void)destroy {
  KRYPTON_LLogInfo(@"KryptonApp destroy");

  _destroyed = YES;

  for (id<KryptonService> service in [self.serviceArray reverseObjectEnumerator]) {
    if ([service respondsToSelector:@selector(onDestroy)]) {
      [service onDestroy];
    }
  }

  _nativeApp->OnRuntimeDetach();

  [self.serviceArray removeAllObjects];
  [self.serviceMap removeAllObjects];
}

- (void)pause {
  if (_destroyed) {
    return;
  }

  KRYPTON_LLogInfo(@"KryptonApp pause");

  for (id<KryptonService> service in self.serviceArray) {
    if ([service respondsToSelector:@selector(onPause)]) {
      [service onPause];
    }
  }
}

- (void)resume {
  if (_destroyed) {
    return;
  }

  KRYPTON_LLogInfo(@"KryptonApp resume");

  for (id<KryptonService> service in self.serviceArray) {
    if ([service respondsToSelector:@selector(onResume)]) {
      [service onResume];
    }
  }
}

- (void)onHide {
  if (_destroyed) {
    return;
  }

  KRYPTON_LLogInfo(@"KryptonApp onHide");

  for (id<KryptonService> service in self.serviceArray) {
    if ([service respondsToSelector:@selector(onHide)]) {
      [service onHide];
    }
  }

  _nativeApp->OnAppEnterBackground();
}

- (void)onShow {
  if (_destroyed) {
    return;
  }

  KRYPTON_LLogInfo(@"KryptonApp onShow");

  for (id<KryptonService> service in self.serviceArray) {
    if ([service respondsToSelector:@selector(onShow)]) {
      [service onShow];
    }
  }

  _nativeApp->OnAppEnterForeground();
}

- (void)setRuntimeActor:(void *)actorNativePtr {
  reinterpret_cast<lynx::canvas::CanvasAppIOS *>(_nativeApp.get())->SetRuntimeActor(actorNativePtr);
}

- (void)setRuntimeTaskRunner:(void *)taskRunnerNativePtr {
  reinterpret_cast<lynx::canvas::CanvasAppIOS *>(_nativeApp.get())
      ->SetRuntimeTaskRunner(taskRunnerNativePtr);
}

- (void)setGPUTaskRunner:(void *)taskRunnerNativePtr {
  reinterpret_cast<lynx::canvas::CanvasAppIOS *>(_nativeApp.get())
      ->SetGPUTaskRunner(taskRunnerNativePtr);
}

- (int64_t)getNativeHandler {
  return reinterpret_cast<lynx::canvas::CanvasAppIOS *>(_nativeApp.get())->GetNativeHandler();
}

@end
