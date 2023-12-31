// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxDevtool.h"

#import <AudioToolbox/AudioToolbox.h>

#import "LynxBaseInspectorOwner.h"
#import "LynxBaseLogBoxProxy.h"
#import "LynxBasePerfMonitor.h"
#import "LynxBaseRedBox.h"
#import "LynxContextModule.h"
#import "LynxDevtool+Internal.h"
#import "LynxEnv.h"
#import "LynxLog.h"
#import "LynxPageReloadHelper.h"
#import "LynxTraceEvent.h"

#pragma mark - LynxDevtool
@implementation LynxDevtool {
  __weak LynxView *_lynxView;
  id<LynxBaseRedBox> _redBox;
  id<LynxBaseLogBoxProxy> _logBoxProxy;

  LynxPageReloadHelper *_reloader;
  id<LynxViewStateListener> _lynxViewStateListener;
  id<LynxBasePerfMonitor> _perfMonitor;
}

- (nonnull instancetype)initWithLynxView:(LynxView *)view debuggable:(BOOL)debuggable {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxDevtool initWithLynxView")
  _lynxView = view;

  if (LynxEnv.sharedInstance.lynxDebugEnabled) {
    if (LynxEnv.sharedInstance.devtoolEnabled ||
        (LynxEnv.sharedInstance.devtoolEnabledForDebuggableView && debuggable)) {
      Class inspectorClass = NSClassFromString(@"LynxInspectorOwner");
      if ([inspectorClass conformsToProtocol:@protocol(LynxBaseInspectorOwner)]) {
        _owner = [[inspectorClass alloc] initWithLynxView:view];
      } else {
        _owner = nil;
      }
    } else {
      _owner = nil;
    }

    if (LynxEnv.sharedInstance.redBoxEnabled && !LynxEnv.sharedInstance.redBoxNextEnabled) {
      Class redBoxClass = NSClassFromString(@"LynxRedBox");
      if ([redBoxClass conformsToProtocol:@protocol(LynxBaseRedBox)]) {
        _redBox = [[redBoxClass alloc] initWithLynxView:view];
        if (_owner) {
          __weak __typeof(self) weakSelf = self;
          [_owner setShowConsoleBlock:^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf->_redBox show];
          }];
        }
      } else {
        _redBox = nil;
      }
    } else {
      _redBox = nil;
    }

    if (LynxEnv.sharedInstance.redBoxEnabled && LynxEnv.sharedInstance.redBoxNextEnabled) {
      Class logBoxProxyClass = NSClassFromString(@"LynxLogBoxProxy");
      if ([logBoxProxyClass conformsToProtocol:@protocol(LynxBaseLogBoxProxy)]) {
        _logBoxProxy = [[logBoxProxyClass alloc] initWithLynxView:view];
        __weak __typeof(self) weakSelf = self;
        [_owner setShowConsoleBlock:^{
          __strong __typeof(weakSelf) strongSelf = weakSelf;
          [strongSelf->_logBoxProxy showConsole];
        }];
      } else {
        _logBoxProxy = nil;
      }
    } else {
      _logBoxProxy = nil;
    }

    if (LynxEnv.sharedInstance.perfMonitorEnabled && _owner != nil) {
      Class perfMonitorClass = NSClassFromString(@"LynxPerfMonitorDarwin");
      if ([perfMonitorClass conformsToProtocol:@protocol(LynxBasePerfMonitor)]) {
        _perfMonitor = [[perfMonitorClass alloc] initWithInspectorOwner:_owner];
      }
    }
  }

  if (_owner != nil || _redBox != nil || _logBoxProxy != nil) {
    _reloader = [[LynxPageReloadHelper alloc] initWithLynxView:view];
  } else {
    _reloader = nil;
  }
  if (_owner != nil) {
    [_owner setReloadHelper:_reloader];
  }
  if (_redBox != nil) {
    [_redBox setReloadHelper:_reloader];
  }
  [_logBoxProxy setReloadHelper:_reloader];

  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
  return self;
}

- (void)registerModule:(LynxTemplateRender *)render {
  Class moduleClass = NSClassFromString(@"LynxDevtoolSetModule");
  if ([moduleClass conformsToProtocol:@protocol(LynxContextModule)]) {
    [render registerModule:moduleClass param:nil];
  } else {
    LLogError(@"failed to register LynxDevtoolSetModule!");
  }
}

- (void)onLoadFromLocalFile:(NSData *)tem
                    withURL:(NSString *)url
                   initData:(LynxTemplateData *)data {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxDevtool onLoadFromLocalFile")
  if (_reloader != nil) {
    [_reloader loadFromLocalFile:tem withURL:url initData:data];
  }
  [self attachDebugBridge];
  [_logBoxProxy reloadLynxView];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)onLoadFromURL:(NSString *)url
             initData:(LynxTemplateData *)data
              postURL:(NSString *)postUrl {
  if (_reloader != nil) {
    [_reloader loadFromURL:url initData:data];
  }
  [self attachDebugBridge];
  [_logBoxProxy reloadLynxView];
}

- (void)onTemplateAssemblerCreated:(intptr_t)ptr {
  if (_owner != nil) {
    [_owner onTemplateAssemblerCreated:ptr];
  }
}

- (void)onEnterForeground {
  if (_owner != nil) {
    [_owner continueCasting];
  }
  if (_lynxViewStateListener) {
    [_lynxViewStateListener onEnterForeground];
  }

  if (LynxEnv.sharedInstance.perfMonitorEnabled && _perfMonitor != nil) {
    [_perfMonitor show];
  }
}

- (void)onEnterBackground {
  if (_owner != nil) {
    [_owner pauseCasting];
  }
  if (_lynxViewStateListener) {
    [_lynxViewStateListener onEnterBackground];
  }

  if (_perfMonitor != nil) {
    [_perfMonitor hide];
  }
}

- (void)onMovedToWindow {
  if ([_owner respondsToSelector:@selector(onMovedToWindow)]) {
    [_owner performSelector:@selector(onMovedToWindow)];
  }
  if (_lynxViewStateListener) {
    [_lynxViewStateListener onMovedToWindow];
  }
  [_logBoxProxy onMovedToWindow];
}

- (void)onLoadFinished {
  if (_owner != nil) {
    [_owner onLoadFinished];
  }
  if (_lynxViewStateListener) {
    [_lynxViewStateListener onLoadFinished];
  }
}

- (void)onFirstScreen {
  [_owner onFirstScreen];
}

- (void)handleLongPress {
  if (_owner != nil) {
    [_owner handleLongPress];
  }
}

- (void)showErrorMessage:(nullable NSString *)message withCode:(NSInteger)errCode {
  if (_redBox != nil) {
    [_redBox showErrorMessage:message withCode:errCode];
  }
  [_logBoxProxy showLogMessage:message withLevel:kLevelError withCode:errCode];
}

- (void)attachLynxView:(LynxView *)lynxView {
  _lynxView = lynxView;
  if (_owner != nil) {
    [_owner attach:lynxView];
  }
  if (_reloader != nil) {
    [_reloader attachLynxView:lynxView];
  }
  if (_redBox != nil) {
    [_redBox attachLynxView:lynxView];
  }
  [_logBoxProxy attachLynxView:lynxView];
}

- (void)setRuntimeId:(NSInteger)runtimeId {
  if (_redBox != nil) {
    [_redBox setRuntimeId:runtimeId];
  }
  [_logBoxProxy setRuntimeId:runtimeId];
}

- (void)dealloc {
  if (_lynxViewStateListener) {
    [_lynxViewStateListener onDestroy];
  }
  [_logBoxProxy destroy];
}

- (NSInteger)attachDebugBridge {
  return [_owner attachDebugBridge];
}

- (void)setSharedVM:(LynxGroup *)group {
  [_owner setSharedVM:group];
}

- (void)destroyDebugger {
  [_owner destroyDebugger];
}

- (void)onPageUpdate {
  if (_owner != nil) {
    [_owner onPageUpdate];
  }
}

- (void)downloadResource:(NSString *)url callback:(LynxResourceLoadBlock)callback {
  if (_owner != nil) {
    [_owner downloadResource:url callback:callback];
  }
}

// Use TARGET_OS_IOS rather than OS_IOS to stay consistent with the header file
#if TARGET_OS_IOS
- (void)attachLynxUIOwner:(nullable LynxUIOwner *)uiOwner {
  if (_owner != nil) {
    [_owner attachLynxUIOwnerToAgent:uiOwner];
  }
}
#endif

@end
