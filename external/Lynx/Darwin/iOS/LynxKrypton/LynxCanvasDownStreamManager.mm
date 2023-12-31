//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxCanvasDownStreamManager.h"

#include <memory>

#import "LynxTemplateRender+Internal.h"
#import "LynxView+Internal.h"

#include "canvas/base/log.h"
#include "canvas/ios/canvas_app_ios.h"
#include "canvas/ios/gl_surface_cv_pixel_buffer.h"
#include "canvas/platform_view_observer.h"
#include "shell/lynx_shell.h"

@implementation LynxCanvasDownStreamManager

+ (instancetype)sharedInstance {
  static LynxCanvasDownStreamManager *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[LynxCanvasDownStreamManager alloc] init];
  });
  return instance;
}

- (std::shared_ptr<lynx::canvas::CanvasApp>)getCanvasApp:(LynxView *)view {
  LynxTemplateRender *templateRender = view.templateRender;

  if (templateRender == nil) {
    KRYPTON_LOGE("can not get templateRender");
    return nullptr;
  }

  LynxUIContext *uiContext = [templateRender.uiOwner uiContext];

  if (uiContext == nil) {
    KRYPTON_LOGE("can not get LynxUIContext");
    return nullptr;
  }

  auto *shell = reinterpret_cast<lynx::shell::LynxShell *>([uiContext shellPtr]);
  if (!shell) {
    KRYPTON_LOGE("can not get LynxShell");
    return nullptr;
  }

  auto manager = shell->GetCanvasManager().lock();
  if (!manager) {
    KRYPTON_LOGE("can not get canvas manager");
    return nullptr;
  }

  auto canvasAppHandler = manager->GetCanvasAppHandler();
  if (!canvasAppHandler) {
    KRYPTON_LOGE("can not get canvas app handler");
    return nullptr;
  }

  return lynx::canvas::CanvasAppIOS::CanvasAppFromHandler(canvasAppHandler);
}

- (NSInteger)addDownStreamListenerForView:(LynxView *)view
                                   withId:(NSString *)canvasId
                                    width:(NSInteger)width
                                   height:(NSInteger)height
                              AndListener:(id<DownStreamListener>)listener {
  auto canvasApp = [self getCanvasApp:view];

  if (!canvasApp) {
    return 0;
  }

  auto surface = std::make_unique<lynx::canvas::GLSurfaceCVPixelBuffer>(width, height, listener);
  uintptr_t returnKey = reinterpret_cast<uintptr_t>(surface.get());
  std::string cppIdString = [canvasId UTF8String];
  canvasApp->runtime_actor()->Act([surface = std::move(surface), surfaceKey = returnKey, canvasApp,
                                   cppIdString, surfaceWidth = width,
                                   surfaceHeight = height](auto &impl) mutable {
    canvasApp->platform_view_observer()->OnSurfaceCreated(std::move(surface), surfaceKey,
                                                          cppIdString, surfaceWidth, surfaceHeight);
  });
  return returnKey;
}

- (void)removeDownStreamListenerForView:(LynxView *)view
                                 withId:(NSString *)canvasId
                          AndListenerId:(NSInteger)listenerId {
  auto canvasApp = [self getCanvasApp:view];

  if (!canvasApp) {
    return;
  }

  std::string cppIdString = [canvasId UTF8String];
  canvasApp->runtime_actor()->Act([canvasApp, cppIdString, listenerId](auto &impl) mutable {
    canvasApp->platform_view_observer()->OnSurfaceDestroyed(cppIdString, listenerId);
  });
}
@end
