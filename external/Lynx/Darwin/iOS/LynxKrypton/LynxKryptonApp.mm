// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxKryptonApp.h"
#import "KryptonDefaultCamera.h"
#import "KryptonDefaultPermissionService.h"
#import "KryptonDefaultVideoPlayer.h"
#import "KryptonService.h"
#import "LynxKryptonLoader.h"
#import "LynxLog.h"
#import "LynxTemplateRender.h"
#include "canvas/background_lock.h"
#include "canvas/ios/canvas_app_ios.h"
#include "canvas/ios/canvas_manager_ios.h"
#include "canvas/platform/ios/resource_loader_ios.h"
#include "canvas/text/font_registry.h"
#include "config/config.h"

#if ENABLE_KRYPTON_RECORDER
#import "KryptonDefaultMediaRecorder.h"
#endif

@implementation LynxKryptonApp {
  NSString *_temporaryDirectory;
  id<LynxKryptonEffectHandlerProtocol> _effectHandler;
}

- (void)registerServices {
  LynxKryptonLoader *loader = [[LynxKryptonLoader alloc] init];
  [self registerService:@protocol(KryptonLoaderService) withImpl:loader];

  auto videoPlayerService = [[KryptonDefaultVideoPlayerService alloc] init];
  [self registerService:@protocol(KryptonVideoPlayerService) withImpl:videoPlayerService];

  auto cameraService = [[KryptonDefaultCameraService alloc] init];
  [self registerService:@protocol(KryptonCameraService) withImpl:cameraService];

  auto permissionService = [[KryptonDefaultPermissionService alloc] init];
  [self registerService:@protocol(KryptonPermissionService) withImpl:permissionService];

#if ENABLE_KRYPTON_RECORDER
  id recorderService = [[KryptonDefaultMediaRecorderService alloc] init];
  if (_temporaryDirectory) {
    [recorderService setTemporaryDirectory:_temporaryDirectory];
  }
  [self registerService:@protocol(KryptonMediaRecorderService) withImpl:recorderService];
#endif
}

- (void)setupWithTemplateRender:(LynxTemplateRender *)templateRender {
  if (@available(iOS 10.0, *)) {
    [self registerServices];

    auto canvas_manager = new lynx::canvas::CanvasManagerIOS(self);
    [templateRender registerCanvasManager:canvas_manager];

    [LynxKrypton shareInstance];
  }
}

- (void)setTemporaryDirectory:(nullable NSString *)directory {
  _temporaryDirectory = directory;

#if ENABLE_KRYPTON_RECORDER
  id service = [self getService:@protocol(KryptonMediaRecorderService)];
  if ([service isKindOfClass:[KryptonDefaultMediaRecorderService class]]) {
    [(KryptonDefaultMediaRecorderService *)service setTemporaryDirectory:_temporaryDirectory];
  }
#endif
}

- (nullable NSString *)temporaryDirectory {
  if ([_temporaryDirectory length] > 0) {
    return _temporaryDirectory;
  }
  return NSTemporaryDirectory();
}

- (void)setEffectHandler:(nullable id<LynxKryptonEffectHandlerProtocol>)handler {
  _effectHandler = handler;
}

@end

@implementation LynxKrypton
+ (instancetype)shareInstance {
  static LynxKrypton *_instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[self alloc] init];
  });

  return _instance;
}

- (id)init {
  if (self = [super init]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
  }
  return self;
}

- (void)appWillEnterForeground:(UIApplication *)application {
  LLogInfo(@"LynxKryptonHelper receive appWillEnterForeground notification.");
  lynx::canvas::BackgroundLock::Instance().NotifyEnteringForeground();
}

- (void)appDidEnterBackground:(UIApplication *)application {
  LLogInfo(@"LynxKryptonHelper receive appDidEnterBackground notification.");
  lynx::canvas::BackgroundLock::Instance().NotifyEnteringBackground();
}

- (void)appWillTerminate:(UIApplication *)application {
  LLogInfo(@"LynxKryptonHelper receive appWillTerminate notification.");
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerFontWithFamilyName:(nullable NSString *)familyName
                          localUrl:(nullable NSString *)localUrl
                            weight:(NSInteger)weight
                             style:(NSInteger)style {
  auto &instance = lynx::canvas::FontRegistry::Instance();
  instance.Add([familyName UTF8String], [localUrl UTF8String], static_cast<int>(weight),
               static_cast<int>(style));
}

@end
