// Copyright 2020 The Lynx Authors. All rights reserved.

#import "LynxRedBox.h"
#import <TargetConditionals.h>
#import <WebKit/WebKit.h>
#import "LynxDevtoolDownloader.h"
#import "LynxDevtoolEnv.h"

#if __has_include(<Lynx/LynxLog.h>)
#import <Lynx/LynxLog.h>
#else
#import <LynxMacOS/LynxLog.h>
#endif

#if OS_OSX
#define LynxRedBoxBaseWindow NSView
#else
#define LynxRedBoxBaseWindow UIWindow
#endif
@class LynxRedBoxWindow;

typedef void (^JsApiHandler)(NSDictionary *, NSNumber *);
CGFloat const kContentHeightPercent = 0.6;
NSDictionary *const kLevelDic = @{
  @"-1" : @"verbose",
  @"0" : @"info",
  @"1" : @"warning",
  @"2" : @"error",
  @"3" : @"error",
  @"4" : @"info",
  @"5" : @"error"
};
NSString *const BRIDGE_JS =
    @"(function () {"
     "var id = 0, callbacks = {}, eventListeners = {};"
     "var nativeBridge = window.nativeBridge || window.webkit.messageHandlers.nativeBridge;"
     "window.redbox = {"
     "  call: function(bridgeName, callback, data) {"
     "    var thisId = id++;"
     "    callbacks[thisId] = callback;"
     "    nativeBridge.postMessage({"
     "      bridgeName: bridgeName,"
     "      data: data || {},"
     "      callbackId: thisId"
     "    });"
     "  },"
     "  on: function(event, handler) {"
     "    eventListeners[event] = handler;"
     "  },"
     "  sendResult: function(msg) {"
     "    var callbackId = msg.callbackId;"
     "    if (callbacks[callbackId]) {"
     "      callbacks[callbackId](msg.data);"
     "    }"
     "  },"
     "  sendEvent: function(msg) {"
     "    if (eventListeners[msg.event]) {"
     "      eventListeners[msg.event](msg.data);"
     "    }"
     "  }"
     "};"
     "})();"
     "Object.defineProperty(navigator, 'userAgent', {"
     "  value: navigator.userAgent + ' Lynx Redbox',"
     "  writable: false"
     "});"
     "document.dispatchEvent(new Event('RedboxReady'));";

#pragma mark - RedBoxCache
@interface LynxRedBoxCache : NSObject

@property(nonatomic, readwrite) NSMutableArray *errorMessages;
@property(nonatomic, readwrite) NSMutableArray *logMessages;
@property(nonatomic, readwrite) NSDictionary *jsSource;

- (instancetype)init;

@end

@implementation LynxRedBoxCache

- (instancetype)init {
  if (self = [super init]) {
    self.errorMessages = nil;
    self.logMessages = nil;
    self.jsSource = nil;
  }
  return self;
}

@end

#pragma mark - LynxRedBoxWindowActionDelegate
@protocol LynxRedBoxWindowActionDelegate <NSObject>
@optional
// Only needed in LynxLogBox
- (void)clearCurrentLogs;
@optional
- (void)changeView:(NSDictionary *)params;
@optional
- (void)dismiss;
- (void)reloadFromRedBoxWindow:(LynxRedBoxWindow *)redBoxWindow;
- (NSDictionary *)getAllJsSource;
@end

#pragma mark - LynxRedBoxWindow
@interface LynxRedBoxWindow : LynxRedBoxBaseWindow <WKScriptMessageHandler, WKNavigationDelegate>
@property(nonatomic, weak) id<LynxRedBoxWindowActionDelegate> actionDelegate;
@property(nonatomic, copy) void (^loadingFinishCallback)();
@property(nonatomic, readwrite) LynxRedBoxCache *redBoxCache;

- (BOOL)isShowing;
- (void)onRedBoxDestroy;
- (void)destroy;

@end

@implementation LynxRedBoxWindow {
  WKWebView *_stackTraceWebView;
  NSDictionary *_jsAPI;
  NSString *_templateUrl;
  BOOL _isRedBoxDestroyed;
#if OS_OSX
  // click background to dismiss redbox
  NSView *_clickGestureView;
#else
  __weak UIWindow *_previous_keywindow;
#endif
}

- (instancetype)initWithFrame:(CGRect)frame
                          URL:(NSString *)templateUrl
             supportYellowBox:(BOOL)support {
  if (self = [super initWithFrame:frame]) {
#if OS_IOS
    self.windowLevel = UIWindowLevelStatusBar - 1;
    self.backgroundColor = [UIColor clearColor];
    _previous_keywindow = nil;
#endif
    self.redBoxCache = nil;
    self.hidden = YES;
    _isRedBoxDestroyed = false;
    __weak typeof(self) weakSelf = self;
    // clang-format off
    // clang-format cannot format correctly here
    _jsAPI = @{
        @"getCoreJs" : ^(NSDictionary *params, NSNumber *callbackId) {
            NSDictionary *msg = [NSDictionary
                dictionaryWithObjectsAndKeys:callbackId, @"callbackId",
                                             [weakSelf getJsSource:@"core.js"], @"data", nil];
            [weakSelf sendJsResult:msg];
        },
        @"getTemplateJs": ^(NSDictionary *params, NSNumber *callbackId) {
          NSString *key = params ? params[@"name"] : nil;
          NSDictionary *msg = [NSDictionary
              dictionaryWithObjectsAndKeys:callbackId, @"callbackId",
                                           [weakSelf getJsSource:key], @"data", nil];
           [weakSelf sendJsResult:msg];
        },
        @"deleteLynxview": ^(NSDictionary *params, NSNumber *callbackId) {
            [weakSelf clearCurrentLogs];
        },
        @"changeView": ^(NSDictionary *params, NSNumber *callbackId) {
          [weakSelf changeView:params];
        },
        @"reload": ^(NSDictionary *params, NSNumber *callbackId) {
          [weakSelf reload];
        },
        @"dismiss": ^(NSDictionary *params, NSNumber *callbackId) {
          [weakSelf dismiss];
        },
        @"download": ^(NSDictionary *params, NSNumber *callbackId) {
            NSString *url = params ? params[@"url"] : nil;
            [weakSelf download:url withCallbackId:callbackId];
        }
    };
    _templateUrl = templateUrl;
#if OS_OSX
    // add gesture on subview
    _clickGestureView = [[NSView alloc] init];
    _clickGestureView.wantsLayer = YES;
    _clickGestureView.layer.backgroundColor = [NSColor colorWithWhite:0 alpha:0.8].CGColor;
    [self addSubview:_clickGestureView];
    NSClickGestureRecognizer *gestureRecognizer =
    [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    [_clickGestureView addGestureRecognizer:gestureRecognizer];
#else
    UIViewController *rootController = [UIViewController new];
    self.rootViewController = rootController;
    UIView *rootView = rootController.view;
    rootView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    UITapGestureRecognizer *gestureRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    [rootView addGestureRecognizer:gestureRecognizer];
#endif
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = [[WKUserContentController alloc] init];
    [configuration.userContentController addScriptMessageHandler:self name:@"nativeBridge"];
    WKUserScript *bridgeScript =
        [[WKUserScript alloc] initWithSource:BRIDGE_JS
                               injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                            forMainFrameOnly:YES];
    [configuration.userContentController addUserScript:bridgeScript];
    _stackTraceWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    _stackTraceWebView.navigationDelegate = self;
#if OS_OSX
    [self addSubview:_stackTraceWebView];
#else
    [rootView addSubview:_stackTraceWebView];
#endif
      NSURL *url = [self getRedboxPageUrlWithSupportYellowBox:support];
      if (url) {
          [_stackTraceWebView loadFileURL:url allowingReadAccessToURL:url];
          [self resizeWindow];
      } else {
          LLogError(@"get redbox page url failed");
      }
#if OS_OSX
/**
 * When lynx view destroyed, LynxRedBoxWindow might still exist (#4780).
 * At the moment we reload lynx view, we need remove previous window (NSView).
 */
    for (NSView *window in [NSApplication sharedApplication]
             .mainWindow.contentView.subviews.reverseObjectEnumerator) {
      if ([window isKindOfClass:[LynxRedBoxWindow class]]) {
        if (((LynxRedBoxWindow *)window)->_isRedBoxDestroyed) {
          [(LynxRedBoxWindow *)window destroy];
          [window removeFromSuperview];
        }
      }
    }
    [[NSApplication sharedApplication].mainWindow.contentView addSubview:self];
    // nofitication center contains weak reference of self
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowDidResize:)
                                                 name:NSWindowDidResizeNotification
                                               object:[NSApplication sharedApplication].mainWindow];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:[NSApplication sharedApplication].mainWindow];
#endif
  }
  return self;
}
// clang-format on

#if OS_OSX
// avoid memory leak when window closed while redbox still showing
- (void)windowWillClose:(NSNotification *)notification {
  // Redbox dealloc before window close
  if (self->_isRedBoxDestroyed) {
    [self destroy];
  } else if (!self.hidden) {
    // Redbox still exists, it will destroy window when dealloc but window needs be hidden first
    self.hidden = YES;
  }
}

- (void)windowDidResize:(NSNotification *)notification {
  // when redbox is hidden, don't need to resize window
  if (!self.hidden) {
    [self resizeWindow];
  }
}
#endif

- (void)resizeWindow {
#if OS_OSX
  [self setFrame:[NSApplication sharedApplication].mainWindow.contentView.frame];
  CGRect clickFrame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
  [_clickGestureView setFrame:NSRectFromCGRect(clickFrame)];
  CGRect webViewFrame =
      CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height * kContentHeightPercent);
  [_stackTraceWebView setFrame:NSRectFromCGRect(webViewFrame)];
#else
  UIView *rootView = self.rootViewController.view;
  CGRect webViewFrame = CGRectMake(0, rootView.bounds.size.height, rootView.bounds.size.width,
                                   rootView.bounds.size.height * kContentHeightPercent);
  [_stackTraceWebView setFrame:webViewFrame];
#endif
}

- (NSURL *)getRedboxPageUrlWithSupportYellowBox:(BOOL)supportYellowBox {
  NSURL *url;
  NSURL *debugBundleUrl = [[NSBundle mainBundle] URLForResource:@"LynxDebugResources"
                                                  withExtension:@"bundle"];
  if (debugBundleUrl) {
    NSBundle *bundle = [NSBundle bundleWithURL:debugBundleUrl];
    url = [bundle URLForResource:@"redbox/index" withExtension:@".html"];
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url
                                               resolvingAgainstBaseURL:NO];
    NSMutableArray<NSURLQueryItem *> *queryItems = [[NSMutableArray alloc] init];
    [queryItems addObject:[[NSURLQueryItem alloc] initWithName:@"url" value:_templateUrl]];
    [queryItems addObject:[[NSURLQueryItem alloc] initWithName:@"downloadapi" value:@"true"]];
    if (supportYellowBox) {
      [queryItems addObject:[[NSURLQueryItem alloc] initWithName:@"supportyellowbox"
                                                           value:@"true"]];
    }
    [components setQueryItems:queryItems];
    url = [components URL];
  }
  return url;
}

- (NSString *)getJsSource:(NSString *)key {
  NSDictionary *jsSource = nil;
  if (!_isRedBoxDestroyed) {
    jsSource = [_actionDelegate getAllJsSource];
  } else {
    jsSource = _redBoxCache.jsSource;
  }

  if (key && jsSource[key]) {
    NSMutableString *src = [NSMutableString stringWithString:jsSource[key]];
    [src replaceOccurrencesOfString:@"\n"
                         withString:@""
                            options:NSLiteralSearch
                              range:{0, src.length}];
    return src;
  }
  return nil;
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
  if ([message.name isEqualToString:@"nativeBridge"]) {
    if ([message.body isKindOfClass:[NSDictionary class]]) {
      NSString *bridgeName = [message.body objectForKey:@"bridgeName"];
      NSDictionary *data = [message.body objectForKey:@"data"];
      NSNumber *callbackId = [message.body objectForKey:@"callbackId"];
      if (bridgeName) {
        JsApiHandler handler = _jsAPI[bridgeName];
        if (handler) {
          handler(data, callbackId);
        } else {
          NSLog(@"Unknown JSAPI");
        }
      }
    }
  }
}

- (void)destroy {
  [_stackTraceWebView.configuration.userContentController
      removeScriptMessageHandlerForName:@"nativeBridge"];
}

#pragma mark - Helper

- (NSString *)dict2JsonString:(NSDictionary *)dict {
  NSData *json = [NSJSONSerialization dataWithJSONObject:dict
                                                 options:NSJSONWritingPrettyPrinted
                                                   error:nil];
  NSString *str = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
  NSMutableString *mutStr = [NSMutableString stringWithString:str];
  [mutStr replaceOccurrencesOfString:@"\n"
                          withString:@""
                             options:NSLiteralSearch
                               range:{0, str.length}];
  return mutStr;
}

- (void)sendJsResult:(NSDictionary *)msg {
  NSString *js =
      [NSString stringWithFormat:@"window.redbox.sendResult(%@);", [self dict2JsonString:msg]];
  [_stackTraceWebView evaluateJavaScript:js
                       completionHandler:^(id _Nullable result, NSError *_Nullable error) {
                         if (error) {
                           NSLog(@"%@", [error localizedDescription]);
                         }
                       }];
}

- (void)sendJsEvent:(NSDictionary *)msg {
  NSString *js =
      [NSString stringWithFormat:@"window.redbox.sendEvent(%@);", [self dict2JsonString:msg]];
  [_stackTraceWebView evaluateJavaScript:js completionHandler:nil];
}

- (NSMutableDictionary *)normalizeMessage:(NSDictionary *)message {
  NSMutableDictionary *mutableMessage = [message mutableCopy];
  NSString *level = [kLevelDic objectForKey:message[@"level"]];
  if (!level) level = @"info";
  [mutableMessage setObject:level forKey:@"level"];
  return mutableMessage;
}

#pragma mark - Public Method

- (void)showLogMessage:(NSDictionary *)message {
  [self sendJsEvent:@{@"event" : @"receiveNewLog", @"data" : [self normalizeMessage:message]}];
}

- (void)showErrorMessage:(NSString *)message {
  [self sendJsEvent:@{@"event" : @"receiveNewError", @"data" : message}];
}

- (void)showWarnMessage:(NSString *)message {
  NSString *validMessage = [message substringToIndex:MIN((NSUInteger)10000, message.length)];
  [self sendJsEvent:@{@"event" : @"receiveNewWarning", @"data" : validMessage}];
}

- (void)updateViewInfo:(NSDictionary *)viewInfo {
  [self sendJsEvent:@{@"event" : @"receiveViewInfo", @"data" : viewInfo}];
}

- (void)show {
  if (self.isHidden) {
#if OS_OSX
    // resize first because window size might change when _window dismiss
    [self resizeWindow];
    self.hidden = NO;
    CGRect startAnimationFrame =
        CGRectMake(0, -self.bounds.size.height * kContentHeightPercent, self.frame.size.width,
                   self.frame.size.height * kContentHeightPercent);
    self->_stackTraceWebView.animator.frame = startAnimationFrame;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *_Nonnull context) {
      context.duration = 0.3;
      CGRect endAnimationFrame =
          CGRectMake(0, 0, self.frame.size.width, self.frame.size.height * kContentHeightPercent);
      self->_stackTraceWebView.animator.frame = endAnimationFrame;
    }];
#else
    _previous_keywindow = [UIApplication sharedApplication].keyWindow;
    self.hidden = NO;
    CGFloat rootViewHeight = self.rootViewController.view.bounds.size.height;
    [UIView animateWithDuration:0.3
                     animations:^{
                       CGRect frame = CGRectMake(0, rootViewHeight * (1 - kContentHeightPercent),
                                                 [UIScreen mainScreen].bounds.size.width,
                                                 rootViewHeight * kContentHeightPercent);
                       [self->_stackTraceWebView setFrame:frame];
                     }];
#endif
  }
}

- (void)dismiss {
#if OS_OSX
  CGRect startAnimationFrame =
      CGRectMake(0, 0, self.frame.size.width, self.frame.size.height * kContentHeightPercent);
  self->_stackTraceWebView.animator.frame = startAnimationFrame;
  [NSAnimationContext
      runAnimationGroup:^(NSAnimationContext *_Nonnull context) {
        context.duration = 0.3;
        CGRect endAnimationFrame =
            CGRectMake(0, -self.bounds.size.height * kContentHeightPercent, self.frame.size.width,
                       self.frame.size.height * kContentHeightPercent);
        self->_stackTraceWebView.animator.frame = endAnimationFrame;
      }
      completionHandler:^{
        self.hidden = YES;
      }];
#else
  CGFloat rootViewHeight = self.rootViewController.view.bounds.size.height;
  [UIView animateWithDuration:0.3
      animations:^{
        CGRect frame = CGRectMake(0, rootViewHeight, [UIScreen mainScreen].bounds.size.width,
                                  rootViewHeight * kContentHeightPercent);
        [self->_stackTraceWebView setFrame:frame];
      }
      completion:^(BOOL finished) {
        [self sendJsEvent:@{@"event" : @"reset"}];
        self.hidden = YES;
        // restore previous key window when dismiss
        if (self->_previous_keywindow) {
          [self->_previous_keywindow makeKeyWindow];
          self->_previous_keywindow = nil;
        }
      }];
#endif
  if (_actionDelegate && [_actionDelegate respondsToSelector:@selector(dismiss)]) {
    [_actionDelegate dismiss];
  }
  if (_isRedBoxDestroyed) {
    [self destroy];
  }
}

- (void)clearCurrentLogs {
  if (_actionDelegate && [_actionDelegate respondsToSelector:@selector(clearCurrentLogs)]) {
    [_actionDelegate clearCurrentLogs];
  }
}

- (void)changeView:(NSDictionary *)params {
  if (_actionDelegate && [_actionDelegate respondsToSelector:@selector(changeView:)]) {
    [_actionDelegate changeView:params];
  }
}

- (void)reload {
  if (_actionDelegate) {
    [_actionDelegate reloadFromRedBoxWindow:self];
  }
}

- (void)download:(NSString *)url withCallbackId:(NSNumber *)callbackId {
  if (url) {
    [LynxDevtoolDownloader
            download:url
        withCallback:^(NSData *_Nullable data, NSError *_Nullable error) {
          NSDictionary *msg = nil;
          if (!error) {
            NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            msg = [NSDictionary
                dictionaryWithObjectsAndKeys:callbackId, @"callbackId", content, @"data", nil];
          } else {
            msg = [NSDictionary dictionaryWithObjectsAndKeys:callbackId, @"callbackId",
                                                             @"Download failed", @"data", nil];
          }
          dispatch_async(dispatch_get_main_queue(), ^{
            [self sendJsResult:msg];
          });
        }];
  } else {
    NSDictionary *msg = [NSDictionary
        dictionaryWithObjectsAndKeys:callbackId, @"callbackId", @"no url in params", @"data", nil];
    [self sendJsResult:msg];
  }
}

- (BOOL)isShowing {
  return !self.isHidden;
}

- (void)onRedBoxDestroy {
  _isRedBoxDestroyed = true;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
  if (!_isRedBoxDestroyed) {
    if (self.loadingFinishCallback) {
      self.loadingFinishCallback();
    }
  } else {
    [self.redBoxCache.logMessages
        enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull message, NSUInteger idx,
                                     BOOL *_Nonnull stop) {
          [self showLogMessage:message];
        }];
    [self.redBoxCache.errorMessages
        enumerateObjectsUsingBlock:^(NSString *_Nonnull message, NSUInteger idx,
                                     BOOL *_Nonnull stop) {
          [self showErrorMessage:message];
        }];
  }
}

- (void)webView:(WKWebView *)webView
    didFailProvisionalNavigation:(WKNavigation *)navigation
                       withError:(NSError *)error {
  if (error && !_stackTraceWebView.isLoading) {
    LLogInfo(@"Load redbox page failed: %@", [error localizedDescription]);
  }
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
                      decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
  if ([navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
    NSInteger statusCode = ((NSHTTPURLResponse *)navigationResponse.response).statusCode;
    if (statusCode / 100 == 4 || statusCode / 100 == 5) {
      decisionHandler(WKNavigationResponsePolicyCancel);
    } else {
      decisionHandler(WKNavigationResponsePolicyAllow);
    }
  } else {
    decisionHandler(WKNavigationResponsePolicyAllow);
  }
}

@end

#pragma mark - LynxRedBox
@interface LynxRedBox () <LynxRedBoxWindowActionDelegate>
- (void)showErrorMessageOnMainThread:(NSString *)message;
@end

@implementation LynxRedBox {
  LynxRedBoxWindow *_window;
  __weak LynxView *_lynxView;
  LynxPageReloadHelper *_reloadHelper;
  NSInteger _runtimeId;
  __weak LynxLogObserver *_logObserver;
  NSMutableArray *_errorMessages;
  NSMutableArray *_logMessages;
  bool _isLoadingFinished;
  NSInteger _observerId;
}

- (nonnull instancetype)initWithLynxView:(nullable LynxView *)view {
  _lynxView = view;
  _window = nil;
  _reloadHelper = nil;
  _errorMessages = [[NSMutableArray alloc] init];
  _logMessages = [[NSMutableArray alloc] init];
  _isLoadingFinished = NO;
  LynxLogObserver *observer = [[LynxLogObserver alloc] init];
  observer.minLogLevel = LynxLogLevelInfo;
  observer.shouldFormatMessage = NO;
  observer.acceptSource = LynxLogSourceJS;
  __weak __typeof(self) weakSelf = self;
  observer.logFunction = ^(LynxLogLevel level, NSString *message) {
    __strong __typeof(weakSelf) strongSelf = weakSelf;
    [strongSelf showLogMessage:@{@"level" : @(level), @"text" : message}];
  };
  observer.acceptRuntimeId = _runtimeId;
  _observerId = AddLoggingDelegate(observer);
  _logObserver = observer;
  return self;
}

- (void)setReloadHelper:(nullable LynxPageReloadHelper *)reload_helper {
  _reloadHelper = reload_helper;
}

- (void)showErrorMessage:(nullable NSString *)message withCode:(NSInteger)errCode {
  if ([LynxDevtoolEnv.sharedInstance isErrorTypeIgnored:errCode]) {
    return;
  }

  if ([NSThread isMainThread]) {
    [self showErrorMessageOnMainThread:message];
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self showErrorMessageOnMainThread:message];
    });
  }
}

- (void)showLogMessage:(NSDictionary *)message {
  if ([NSThread isMainThread]) {
    [self showLogMessageOnMainThread:message];
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self showLogMessageOnMainThread:message];
    });
  }
}

- (void)show {
  if ([NSThread isMainThread]) {
    [self showOnMainThread];
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self showOnMainThread];
    });
  }
}

- (void)showErrorMessageOnMainThread:(nullable NSString *)message {
  if (_isLoadingFinished) {
    [_window showErrorMessage:message];
  } else {
    [_errorMessages addObject:message];
  }
  [self showOnMainThread];
}

- (void)showLogMessageOnMainThread:(NSDictionary *)message {
  if (_isLoadingFinished) {
    [_window showLogMessage:message];
  } else {
    [_logMessages addObject:message];
  }
}

- (void)showOnMainThread {
  if (!self->_window) {
    CGRect windowFrame;
#if OS_OSX
    windowFrame = [NSApplication sharedApplication].mainWindow.frame;
#else
    windowFrame = [UIScreen mainScreen].bounds;
#endif
    self->_window = [[LynxRedBoxWindow alloc] initWithFrame:windowFrame
                                                        URL:self->_lynxView.url
                                           supportYellowBox:NO];
    self->_window.actionDelegate = self;
    __weak __typeof(self) weakSelf = self;
    [self->_window setLoadingFinishCallback:^{
      __strong __typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf) {
        strongSelf->_isLoadingFinished = YES;
        [strongSelf->_logMessages
            enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull message, NSUInteger idx,
                                         BOOL *_Nonnull stop) {
              [strongSelf->_window showLogMessage:message];
            }];
        [strongSelf->_errorMessages
            enumerateObjectsUsingBlock:^(NSString *_Nonnull message, NSUInteger idx,
                                         BOOL *_Nonnull stop) {
              [strongSelf->_window showErrorMessage:message];
            }];
      }
    }];
  }
  [self->_window show];
}

- (void)reloadFromRedBoxWindow:(LynxRedBoxWindow *)redBoxWindow {
  [self->_window dismiss];
  [_reloadHelper reloadLynxView:false];
}

- (NSDictionary *)getAllJsSource {
  return [self->_lynxView getAllJsSource];
}

- (void)attachLynxView:(nonnull LynxView *)lynxView {
  _lynxView = lynxView;
}

- (void)setRuntimeId:(NSInteger)runtimeId {
  _runtimeId = runtimeId;
  _logObserver.acceptRuntimeId = runtimeId;
}

- (void)dealloc {
  if (_observerId) {
    RemoveLoggingDelegate(_observerId);
  };
  if (_window) {
    if ([_window isShowing]) {
      [self copySnapShotToWindow];
      [_window onRedBoxDestroy];
    } else {
      [_window destroy];
    }
  }
}

- (void)copySnapShotToWindow {
  LynxRedBoxCache *cache = [[LynxRedBoxCache alloc] init];
  cache.errorMessages = _errorMessages;
  cache.logMessages = _logMessages;
  cache.jsSource = [self getAllJsSource];
  _window.redBoxCache = cache;
}

@end

#pragma mark - LynxLogBox
@interface LynxLogBox () <LynxRedBoxWindowActionDelegate>
@end

@implementation LynxLogBox {
  __weak LynxLogBoxManager *_manager;
  LynxRedBoxWindow *_window;
  __weak LynxLogBoxProxy *_currentProxy;
  LynxLogBoxLevel _currentLevel;
  NSString *_templateUrl;
  // start from 1, send updateViewInfo to webview when it changes, default for -1.
  NSInteger _index;
  NSInteger _count;
  bool _isLoadingFinished;
  bool _isConsoleOnly;
}

- (instancetype)initWithLogBoxManager:(LynxLogBoxManager *)manager {
  _window = nil;
  _manager = manager;
  _currentProxy = nil;
  _templateUrl = @"";
  _index = -1;
  _count = -1;
  _isLoadingFinished = false;
  _isConsoleOnly = false;
  return self;
}

- (void)updateViewInfo:(NSString *)url currentIndex:(NSInteger)index totalCount:(NSInteger)count {
  if ([NSThread isMainThread]) {
    [self updateViewInfoOnMainThread:url currentIndex:index totalCount:count];
  } else {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong __typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf updateViewInfoOnMainThread:url currentIndex:index totalCount:count];
    });
  }
}

- (void)updateTemplateUrl:(NSString *)url {
  if ([NSThread isMainThread]) {
    [self updateViewInfoOnMainThread:url currentIndex:_index totalCount:_count];
  } else {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong __typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf updateViewInfoOnMainThread:url
                                currentIndex:strongSelf->_index
                                  totalCount:strongSelf->_count];
    });
  }
}

- (void)updateViewInfoOnMainThread:(NSString *)url
                      currentIndex:(NSInteger)index
                        totalCount:(NSInteger)count {
  LLogInfo(@"logbox: logbox updateViewInfoOnMainThread, url: %@", url);
  if (index != _index || count != _count || ![_templateUrl isEqualToString:url]) {
    _index = index;
    _count = count;
    _templateUrl = url != nil ? url : @"";
    if (!_isLoadingFinished) {
      return;
    }
    [self updateViewInfoOnWindow];
  }
}

- (void)updateViewInfoOnWindow {
  [self->_window updateViewInfo:@{
    @"currentView" : [NSNumber numberWithInteger:_index],
    @"viewsCount" : [NSNumber numberWithInteger:_count],
    @"type" : _currentLevel == kLevelWarning ? @"yellowbox" : @"redbox",
    @"templateUrl" : _templateUrl != nil ? _templateUrl : @""
  }];
}

- (BOOL)onNewLog:(NSString *)message
       withLevel:(LynxLogBoxLevel)level
       withProxy:(LynxLogBoxProxy *)proxy {
  if ([NSThread isMainThread]) {
    [self showLogMessageOnMainThread:message withLevel:level withProxy:proxy];
  } else {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong __typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf showLogMessageOnMainThread:message withLevel:level withProxy:proxy];
    });
  }
  return _isLoadingFinished;
}

- (BOOL)onNewConsole:(NSDictionary *)message withProxy:(LynxLogBoxProxy *)proxy isOnly:(BOOL)only {
  if ([NSThread isMainThread]) {
    [self showConsoleMessageOnMainThread:message withProxy:proxy isOnly:only];
  } else {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong __typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf showConsoleMessageOnMainThread:message withProxy:proxy isOnly:only];
    });
  }
  return _isLoadingFinished;
}

- (void)showLogMessageOnMainThread:(NSString *)message
                         withLevel:(LynxLogBoxLevel)level
                         withProxy:(LynxLogBoxProxy *)proxy {
  _currentProxy = proxy;
  _currentLevel = level;
  NSString *url = [proxy templateUrl];
  _templateUrl = url != nil ? url : @"";
  _isConsoleOnly = false;
  if (_isLoadingFinished) {
    [self showLogMessageOnWindow:message];
  }
  [self showOnMainThread];
}

- (void)showLogMessageOnWindow:(NSString *)message {
  if (_currentLevel == kLevelWarning) {
    [_window showWarnMessage:message];
  } else {
    [_window showErrorMessage:message];
  }
}

- (void)showConsoleMessageOnMainThread:(NSDictionary *)message
                             withProxy:(LynxLogBoxProxy *)proxy
                                isOnly:(BOOL)only {
  _currentProxy = proxy;
  NSString *url = [proxy templateUrl];
  _templateUrl = url != nil ? url : @"";
  _isConsoleOnly = only;
  if (_isLoadingFinished) {
    [_window showLogMessage:message];
  }
  if (_isConsoleOnly) {
    [self showOnMainThread];
  }
}

- (void)showOnMainThread {
  if (!self->_window) {
    CGRect windowFrame;
#if TARGET_OS_OSX
    windowFrame = [NSApplication sharedApplication].mainWindow.frame;
#else
    windowFrame = [UIScreen mainScreen].bounds;
#endif
    self->_window = [[LynxRedBoxWindow alloc] initWithFrame:windowFrame
                                                        URL:_templateUrl
                                           supportYellowBox:YES];
    self->_window.actionDelegate = self;
    __weak __typeof(self) weakSelf = self;
    [self->_window setLoadingFinishCallback:^{
      __strong __typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf) {
        strongSelf->_isLoadingFinished = true;
        [strongSelf updateViewInfoOnWindow];
        if (!strongSelf->_isConsoleOnly) {
          [[strongSelf getCurrentLogMsgs]
              enumerateObjectsUsingBlock:^(NSString *_Nonnull message, NSUInteger idx,
                                           BOOL *_Nonnull stop) {
                [strongSelf showLogMessageOnWindow:message];
              }];
        }
        [[strongSelf getCurrentConsoleMsgs]
            enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull message, NSUInteger idx,
                                         BOOL *_Nonnull stop) {
              [strongSelf->_window showLogMessage:message];
            }];
      }
    }];
  }
  [self->_window show];
}

- (NSMutableArray *)getCurrentLogMsgs {
  return [_currentProxy logMessagesWithLevel:_currentLevel];
}

- (NSMutableArray *)getCurrentConsoleMsgs {
  return [_currentProxy consoleMessages];
}

- (BOOL)isShowing {
  return [_window isShowing];
}

- (BOOL)isConsoleOnly {
  return _isConsoleOnly;
}

- (LynxLogBoxLevel)getCurrentLevel {
  return _currentLevel;
}

- (nullable LynxLogBoxProxy *)getCurrentProxy {
  return _currentProxy;
}

- (void)clearCurrentLogs {
  [_manager removeCurrentLogsWithLevel:_currentLevel];
}

- (void)dismissIfNeeded {
  if ([_window isShowing]) {
    [_window dismiss];
  }
}

- (void)dismiss {
  _index = -1;
  _count = -1;
  _templateUrl = @"";
}

- (void)reloadFromRedBoxWindow:(LynxRedBoxWindow *)redBoxWindow {
  [self->_window dismiss];
  [_manager reloadFromLogBox:_currentProxy];
}

- (void)changeView:(NSDictionary *)params {
  NSNumber *indexNum = [params objectForKey:@"viewNumber"];
  if (indexNum != nil) {
    [_manager changeView:indexNum withLevel:_currentLevel];
  }
}

- (NSDictionary *)getAllJsSource {
  return [_currentProxy allJsSource];
}

- (void)copySnapShotToWindow {
  LynxRedBoxCache *cache = [[LynxRedBoxCache alloc] init];
  cache.errorMessages = [self getCurrentLogMsgs];
  cache.logMessages = [self getCurrentConsoleMsgs];
  cache.jsSource = [self getAllJsSource];
  _window.redBoxCache = cache;
}

- (void)dealloc {
  if (_window) {
    if ([_window isShowing]) {
      [self copySnapShotToWindow];
      [_window onRedBoxDestroy];
    } else {
      [_window destroy];
    }
  }
}

@end
