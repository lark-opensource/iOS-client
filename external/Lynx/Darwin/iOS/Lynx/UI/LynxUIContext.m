// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxUIContext.h"
#import "LynxEnv.h"
#import "LynxEventHandler.h"
#import "LynxGlobalObserver.h"
#import "LynxRootUI.h"
#import "LynxScrollFluency.h"
#import "LynxTemplateRender+Internal.h"
#import "LynxUIContext+Internal.h"
#import "LynxUIExposure+Internal.h"
#import "LynxUIIntersectionObserver.h"
#import "LynxUIOwner.h"
#import "LynxUIReportInfoDelegate.h"
#import "LynxView+Internal.h"

@implementation LynxUIContext {
  BOOL _isDev;
}

- (instancetype)initWithScreenMetrics:(LynxScreenMetrics*)screenMetrics {
  if (self = [super init]) {
    _screenMetrics = screenMetrics;
    _isDev = NSClassFromString(@"LynxInspectorOwner") ? YES : NO;
    // Be in charge of notifying exposure detection can be executed when the UI has changed.
    _observer = [[LynxGlobalObserver alloc] init];
    _uiExposure = [[LynxUIExposure alloc] initWithObserver:_observer];
    _scrollFluencyMonitor = [[LynxScrollFluency alloc] init];

    _defaultAutoResumeAnimation = [LynxEnv.sharedInstance getAutoResumeAnimation];
    _defaultEnableNewTransformOrigin = [LynxEnv.sharedInstance getEnableNewTransformOrigin];
  }
  return self;
}

- (void)updateScreenSize:(CGSize)screenSize {
  [_screenMetrics setLynxScreenSize:screenSize];
}

- (void)onGestureRecognized {
  if (self.eventHandler != nil) {
    [self.eventHandler onGestureRecognized];
  }
}

- (void)onGestureRecognizedByUI:(LynxUI*)ui {
  if (self.eventHandler != nil) {
    [self.eventHandler onGestureRecognizedByEventTarget:ui];
  }
}

- (void)didReceiveResourceError:(NSError*)error {
  LynxView* lynxView = self.rootUI.lynxView;
  [[lynxView getLifecycleDispatcher] lynxView:lynxView didRecieveError:error];
}

- (void)reportError:(NSError*)error {
  LynxView* lynxView = self.rootUI.lynxView;
  [lynxView.templateRender onErrorOccurred:error.code sourceError:error];
}

- (void)didReceiveException:(NSException*)exception
                withMessage:(NSString*)message
                      forUI:(LynxUI*)ui {
  // stack message
  NSArray<NSString*>* stacks = exception.callStackSymbols;
  NSMutableString* stackInfo = [NSMutableString string];
  // save the first 20 lines of information on the stack
  for (NSUInteger i = 0; i < MIN(stacks.count, 20); ++i) {
    [stackInfo appendFormat:@"%@\n", stacks[i]];
  }
  NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
  [userInfo setValue:message forKey:LynxErrorUserInfoKeyMessage];
  [userInfo setValue:stackInfo forKey:LynxErrorUserInfoKeyStackInfo];
  // custom info
  if ([ui conformsToProtocol:@protocol(LynxUIReportInfoDelegate)]) {
    if ([ui respondsToSelector:@selector(reportUserInfoOnError)]) {
      [userInfo setValue:[(id<LynxUIReportInfoDelegate>)ui reportUserInfoOnError]
                  forKey:LynxErrorUserInfoKeyCustomInfo];
    }
  }
  LynxError* error = [LynxError lynxErrorWithCode:LynxErrorCodeException userInfo:userInfo];
  [self didReceiveResourceError:error];
}

- (NSNumber*)getLynxRuntimeId {
  UIView* rootView = [self rootView];
  if (rootView != nil && [rootView respondsToSelector:@selector(getLynxRuntimeId)]) {
    return [rootView performSelector:@selector(getLynxRuntimeId)];
  }
  return nil;
}

- (BOOL)isDev {
  return _isDev && [[LynxEnv sharedInstance] automationEnabled];
}

- (void)addUIToExposuredMap:(LynxUI*)ui {
  [_uiExposure addLynxUI:ui];
}

- (void)removeUIFromExposuredMap:(LynxUI*)ui {
  [_uiExposure removeLynxUI:ui];
}

- (LynxUIIntersectionObserverManager*)intersectionManager {
  return [((LynxView*)_rootView).templateRender getLynxUIIntersectionObserverManager];
}

- (void)removeUIFromIntersectionManager:(LynxUI*)ui {
  if (![self intersectionManager].enableNewIntersectionObserver) {
    return;
  }
  [[self intersectionManager] removeAttachedIntersectionObserver:ui];
}

- (void)setDefaultOverflowVisible:(BOOL)enable {
  _defaultOverflowVisible = enable;
}

- (void)setDefaultImplicitAnimation:(BOOL)enable {
  _defaultImplicitAnimation = enable;
}

- (void)setEnableTextRefactor:(BOOL)enable {
  _enableTextRefactor = enable;
}

- (void)setEnableTextOverflow:(BOOL)enable {
  _enableTextOverflow = enable;
}

- (void)setEnableNewClipMode:(BOOL)enable {
  _enableNewClipMode = enable;
}

- (void)setEnableEventRefactor:(BOOL)enable {
  _enableEventRefactor = enable;
}

- (void)setEnableA11yIDMutationObserver:(BOOL)enable {
  _enableA11yIDMutationObserver = enable;
}

- (void)setEnableEventThrough:(BOOL)enable {
  _enableEventThrough = enable;
}

- (void)setEnableBackgroundShapeLayer:(BOOL)enable {
  _enableBackgroundShapeLayer = enable;
}

- (void)setEnableFiberArch:(BOOL)enable {
  _enableFiberArch = enable;
}

- (void)setEnableExposureUIMargin:(BOOL)enable {
  _enableExposureUIMargin = enable;
}

- (void)setEnableTextLayerRender:(BOOL)enable {
  _enableTextLayerRender = enable;
}

- (void)setEnableTextLanguageAlignment:(BOOL)enable {
  _enableTextLanguageAlignment = enable;
}

- (void)setEnableXTextLayoutReused:(BOOL)enableXTextLayoutReused {
  _enableXTextLayoutReused = enableXTextLayoutReused;
}

- (void)setTargetSdkVersion:(NSString*)version {
  _targetSdkVersion = version;
}

@end
