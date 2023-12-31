// Copyright 2021 The Lynx Authors. All rights reserved.
#import "DevtoolLepusManagerDarwin.h"
#import <Lynx/LynxLog.h>
#import "LynxDevtoolDownloader.h"

#include "jsbridge/js_debug/inspector_lepus_debugger.h"
#include "lepus/context.h"

namespace lynx {
namespace devtool {
class InspectorLepusDebuggerImpl : public InspectorLepusDebugger {
 public:
  InspectorLepusDebuggerImpl(DevtoolLepusManagerDarwin* lepus, int num) {
    _lepus = lepus;
    SetTargetNum(num);
  }

  virtual void ResponseFromJSEngine(const std::string& message) override {
    __strong typeof(_lepus) lepus = _lepus;
    if (lepus != nil) {
      [lepus ResponseFromJSEngine:message];
    }
  }

 private:
  __weak DevtoolLepusManagerDarwin* _lepus;
};
}  // namespace devtool
}  // namespace lynx

#pragma mark - DevtoolLepusManagerDarwin
@implementation DevtoolLepusManagerDarwin {
  __weak LynxInspectorOwner* owner_;
  std::shared_ptr<lynx::devtool::InspectorLepusDebuggerImpl> debugger_;
  bool _wait_flag;
  UIActivityIndicatorView* _loading_view;
  UIWindow* _loading_window;
}
static int target_num_ = 0;
static bool _debug_active = false;

- (instancetype)initWithInspectorOwner:(LynxInspectorOwner*)owner {
  self = [super init];
  if (self) {
    owner_ = owner;
    debugger_ = std::make_shared<lynx::devtool::InspectorLepusDebuggerImpl>(self, target_num_++);
    _wait_flag = true;
  }
  return self;
}

- (void)ResponseFromJSEngine:(std::string)response {
  __strong typeof(owner_) owner = owner_;
  if (owner) {
    [owner sendResponse:response];
  }
}

- (void)DispatchMessageToJSEngine:(std::string)message {
  if (debugger_) {
    debugger_->DispatchMessageToJSEngine(message);
  }
}

- (void)StopDebug {
  if (debugger_) {
    debugger_->StopDebug();
    debugger_->DispatchDebuggerDisableMessage();
  }
}

- (void)DestroyDebug {
  if (debugger_) {
    debugger_->OnDestroy();
  }
}

- (void)DispatchDebuggerDisableMessage {
  if (debugger_) {
    debugger_->DispatchDebuggerDisableMessage();
  }
}

- (intptr_t)getJavascriptDebugger:(NSString*)url {
  if (debugger_) {
    [self SetEnableNeeded:_debug_active];
    if (_debug_active) {
      [self CreateLoadingView];
      [self GetDebugInfo:url];
      CFRunLoopRef runLoop = CFRunLoopGetCurrent();
      CFRunLoopMode mode = CFRunLoopCopyCurrentMode(runLoop);
      while (_wait_flag) {
        CFRunLoopRunInMode(mode, 0.001, false);
      }
      [_loading_view stopAnimating];
      _loading_window.hidden = YES;
      _wait_flag = true;
    }
    auto sp = std::dynamic_pointer_cast<lynx::piper::JavaScriptDebugger>(debugger_);
    return reinterpret_cast<intptr_t>(new lynx::piper::JavaScriptDebuggerWrapper(sp));
  } else {
    return 0;
  }
}

- (void)CreateLoadingView {
  if (!_loading_window) {
    _loading_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  }
  if (!_loading_view) {
    _loading_view = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [_loading_window addSubview:_loading_view];
    _loading_view.center = _loading_window.center;
    _loading_view.backgroundColor = [UIColor orangeColor];
    _loading_view.alpha = 0.5;
  }
  _loading_window.hidden = NO;
  [_loading_view startAnimating];
}

+ (void)SetDebugActive:(bool)active {
  _debug_active = active;
  lynx::lepus::Context::SetDebugEnabled(active);
}

- (void)GetDebugInfo:(NSString*)url {
  LLogInfo(@"lepus debug: debug info url: %s", [url UTF8String]);
  [LynxDevtoolDownloader download:url
                     withCallback:^(NSData* _Nullable data, NSError* _Nullable error) {
                       NSString* content = [[NSString alloc] initWithData:data
                                                                 encoding:NSUTF8StringEncoding];
                       [self SetDebugInfo:content];
                       self->_wait_flag = false;
                     }];
}

- (void)SetDebugInfo:(NSString*)content {
  if (debugger_) {
    debugger_->SetDebugInfo([content UTF8String]);
  }
}

- (void)SetEnableNeeded:(bool)enable {
  if (debugger_) {
    debugger_->SetEnableNeeded(enable);
  }
}

@end
