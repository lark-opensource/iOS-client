//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxLogBoxProxy.h"
#import "LynxDevtoolEnv.h"
#import "LynxLogBoxHelper.h"
#import "LynxLogBoxOwner.h"

#if __has_include(<Lynx/LynxDevtool.h>)
#import <Lynx/LynxDevtool.h>
#import <Lynx/LynxLog.h>
#import <Lynx/LynxView+Internal.h>
#else
#import <LynxMacOS/LynxDevtool.h>
#import <LynxMacOS/LynxLog.h>
#import <LynxMacOS/LynxView+Internal.h>
#endif

@implementation LynxLogBoxProxy {
  __weak LynxView* _lynxView;
  __weak UIViewController* _pageViewController;
  LynxPageReloadHelper* _reloadHelper;
  NSInteger _runtimeId;
  __weak LynxLogObserver* _consoleObserver;
  NSInteger _observerId;
  BOOL _needFlush;
  NSString* _url;
}

- (instancetype)initWithLynxView:(LynxView*)view {
  LLogInfo(@"logbox: proxy initWithLynxView: %p", view);
  self = [super init];
  if (self) {
    _lynxView = view;
    _logMessages = [NSMutableDictionary dictionary];
    _consoleMessages = [NSMutableArray new];
    // See LynxLog.h, -1 for all logs.
    // When using shared js context, global js runtime does not have runtimeId, so we need to get
    // all console logs and filter out the logs belonging to current lynxview in showConsoleMessage.
    _runtimeId = -1;
    [self addConsoleObserver];
    _needFlush = NO;
  }
  return self;
}

- (void)addConsoleObserver {
  LynxLogObserver* observer = [[LynxLogObserver alloc] init];
  observer.minLogLevel = LynxLogLevelInfo;
  observer.shouldFormatMessage = NO;
  observer.acceptSource = LynxLogSourceJS;
  __weak __typeof(self) weakSelf = self;
  observer.logFunction = ^(LynxLogLevel level, NSString* message) {
    __strong __typeof(weakSelf) strongSelf = weakSelf;
    [strongSelf
        showConsoleMessage:@{@"level" : @(level), @"text" : message != nil ? message : @""}];
  };
  observer.acceptRuntimeId = _runtimeId;
  _observerId = AddLoggingDelegate(observer);
  _consoleObserver = observer;
}

- (void)removeConsoleObserver {
  if (_observerId) {
    RemoveLoggingDelegate(_observerId);
  };
}

- (UIViewController*)pageViewController {
  if (_pageViewController) {
    return _pageViewController;
  }
  UIResponder* next = [_lynxView nextResponder];
  do {
    if ([next isKindOfClass:[UIViewController class]]) {
      _pageViewController = (UIViewController*)next;
      return _pageViewController;
    }
    next = [next nextResponder];
  } while (next != nil);
  return nil;
}

- (void)onMovedToWindow {
  LLogInfo(@"logbox: onMovedToWindow, self: %p", self);
  if (_needFlush) {
    [self flushLogMessages];
  }
}

- (void)flushLogMessages {
  [_logMessages
      enumerateKeysAndObjectsUsingBlock:^(NSNumber* _Nonnull level, NSMutableArray* _Nonnull msgArr,
                                          BOOL* _Nonnull stop) {
        for (NSString* message in msgArr) {
          [self flushLogMessage:message withLevel:[level integerValue]];
        }
      }];
  _needFlush = NO;
}

- (void)setReloadHelper:(LynxPageReloadHelper*)reloadHelper {
  _reloadHelper = reloadHelper;
}

- (void)showLogMessage:(NSString*)message
             withLevel:(LynxLogBoxLevel)level
              withCode:(NSInteger)errCode {
  if ([LynxDevtoolEnv.sharedInstance isErrorTypeIgnored:errCode]) {
    return;
  }
  if ([NSThread isMainThread]) {
    [self showLogMessageOnMainThread:message withLevel:level];
  } else {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong __typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf showLogMessageOnMainThread:message withLevel:level];
    });
  }
}

- (void)showLogMessageOnMainThread:(NSString*)message withLevel:(LynxLogBoxLevel)level {
  NSNumber* levelNum = [NSNumber numberWithInteger:level];
  if ([_logMessages objectForKey:levelNum] == nil) {
    [_logMessages setObject:[NSMutableArray new] forKey:levelNum];
  }
  [[_logMessages objectForKey:levelNum] addObject:message];
  [self flushLogMessage:message withLevel:level];
}

- (void)flushLogMessage:(NSString*)message withLevel:(LynxLogBoxLevel)level {
  [self prepareOwner];
  [[LynxLogBoxOwner getInstance] onNewLog:message withLevel:level withProxy:self];
}

- (void)prepareOwner {
  UIViewController* controller = [self pageViewController];
  if (!controller) {
    LLogInfo(@"logbox: UIViewController is nil! self: %p, lynxview: %p", self, _lynxView);
    _needFlush = YES;
    _url = [self templateUrl];
    return;
  }
  [[LynxLogBoxOwner getInstance] insertLogBoxProxy:self withController:controller];
}

- (void)showConsoleMessage:(NSDictionary*)message {
  NSString* msgText = [message objectForKey:@"text"];
  NSRange range = [msgText rangeOfString:@"||"];
  if (range.location != NSNotFound) {
    NSString* msgPart1 = [msgText substringToIndex:range.location];
    NSString* msgPart2 = [msgText substringFromIndex:range.location + 2];
    while (msgPart2 != nil && [msgPart2 characterAtIndex:0] == ' ') {
      msgPart2 = [msgPart2 substringFromIndex:1];
    }
    if ([msgPart1 containsString:@"groupId:"]) {
      msgText = msgPart2;
    } else if ([msgPart1 containsString:@"runtimeId:"] ||
               [msgPart1 containsString:@"lepusRuntimeId:"]) {
      msgPart1 = [msgPart1 substringFromIndex:[msgPart1 rangeOfString:@":"].location + 1];
      msgPart1 = [msgPart1 substringToIndex:[msgPart1 rangeOfString:@"\""].location];
      NSInteger msgRuntimeId = [msgPart1 integerValue];
      if (msgRuntimeId != _runtimeId) return;
      msgText = msgPart2;
    }
  }
  NSDictionary* resultMsg =
      @{@"level" : [message objectForKey:@"level"], @"text" : msgText != nil ? msgText : @""};
  if ([NSThread isMainThread]) {
    [self showConsoleMessageOnMainThread:resultMsg];
  } else {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong __typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf showConsoleMessageOnMainThread:resultMsg];
    });
  }
}

- (void)showConsoleMessageOnMainThread:(NSDictionary*)message {
  [_consoleMessages addObject:message];
  [[LynxLogBoxOwner getInstance] onNewConsole:message withProxy:self];
}

- (void)attachLynxView:(nonnull LynxView*)lynxView {
  LLogInfo(@"logbox: attachLynxView, self: %p, lynxview: %p", self, lynxView);
  _lynxView = lynxView;
  if ([NSThread isMainThread]) {
    [[LynxLogBoxOwner getInstance] updateTemplateUrl:[self templateUrl] withProxy:self];
  } else {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong __typeof(weakSelf) strongSelf = weakSelf;
      [[LynxLogBoxOwner getInstance] updateTemplateUrl:[strongSelf templateUrl]
                                             withProxy:strongSelf];
    });
  }
}

- (void)reloadLynxView {
  [[LynxLogBoxOwner getInstance] reloadLynxViewWithProxy:self];
  [self clearMsg];
}

- (void)reloadLynxViewFromLogBox {
  [self clearMsg];
  [_reloadHelper reloadLynxView:false];
}

- (void)clearMsg {
  [_logMessages removeAllObjects];
  [_consoleMessages removeAllObjects];
}

- (void)setRuntimeId:(NSInteger)runtimeId {
  _runtimeId = runtimeId;
}

- (NSMutableArray*)logMessagesWithLevel:(LynxLogBoxLevel)level {
  NSNumber* levelNum = [NSNumber numberWithInteger:level];
  return [_logMessages objectForKey:levelNum];
}

- (void)removeLogMessagesWithLevel:(LynxLogBoxLevel)level {
  NSNumber* levelNum = [NSNumber numberWithInteger:level];
  [_logMessages removeObjectForKey:levelNum];
}

- (NSDictionary*)allJsSource {
  return [_lynxView getAllJsSource];
}

- (NSString*)templateUrl {
  LLogInfo(@"logbox: proxy getTemplateUrl view: %p, url: %@", _lynxView, [_lynxView url]);
  return _url ? _url : [_lynxView url];
}

- (void)showConsole {
  [self prepareOwner];
  [[LynxLogBoxOwner getInstance] showConsoleMsgsWithProxy:self];
}

- (void)destroy {
#if OS_IOS
  if (_needFlush) {
    LLogInfo(@"logbox: destroy, flushLogMessages: %p", self);
    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    _pageViewController = window.rootViewController;
    [self flushLogMessages];
  }
#endif
}

- (void)dealloc {
  [self removeConsoleObserver];
}

@end
