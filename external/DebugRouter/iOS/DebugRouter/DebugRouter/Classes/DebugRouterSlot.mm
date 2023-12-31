#import "DebugRouterSlot.h"
#import "DebugRouter.h"

#include "processor/message_assembler.h"
#include "json/reader.h"
#include <unordered_map>

@implementation DebugRouterSlot {
  BOOL plugged_;
  NSString *screenshot_cache_;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.session_id = 0;
    plugged_ = NO;
    screenshot_cache_ = nil;
    self.type = @"";
  }
  return self;
}

- (int)plug {
  [self pull];
  self.session_id = [[DebugRouter instance] plug:self];
  plugged_ = YES;
  return self.session_id;
}

- (void)pull {
  if (plugged_) {
    [[DebugRouter instance] pull:self.session_id];
    plugged_ = NO;
  }
}

- (void)send:(NSString *)message {
  [[DebugRouter instance] send:message];
}

- (void)sendData:(NSString *)data WithType:(NSString *)type {
  [[DebugRouter instance] sendData:data
                          WithType:type
                        ForSession:self.session_id];
}

- (void)sendData:(NSString *)data WithType:(NSString *)type WithMark:(int)mark {
  [[DebugRouter instance] sendData:data
                          WithType:type
                        ForSession:self.session_id
                          WithMark:mark];
}

- (void)sendAsync:(NSString *)message {
  [[DebugRouter instance] sendAsync:message];
}
- (void)sendDataAsync:(NSString *)data WithType:(NSString *)type {
  [[DebugRouter instance] sendDataAsync:data
                               WithType:type
                             ForSession:self.session_id];
}

- (void)sendDataAsync:(NSString *)data
             WithType:(NSString *)type
             WithMark:(int)mark {
  [[DebugRouter instance] sendDataAsync:data
                               WithType:type
                             ForSession:self.session_id
                               WithMark:mark];
}

- (NSString *)getTemplateUrl {
  return self.delegate ? [self.delegate getTemplateUrl] : @"___UNKNOWN___";
}

#if defined(OS_IOS)
- (UIView *)getTemplateView {
#elif defined(OS_OSX)
- (NSView *)getTemplateView {
#endif
  if (self.delegate) {
    SEL sel = NSSelectorFromString(@"getTemplateView");
    if ([self.delegate respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      id res = [self.delegate performSelector:sel];
#pragma clang diagnostic pop
#if defined(OS_IOS)
      UIView *view = (UIView *)res;
#elif defined(OS_OSX)
      NSView *view = (NSView *)res;
#endif
      return view;
    }
  }
  return nil;
}

- (void)onMessage:(NSString *)message WithType:(NSString *)type {
  [self.delegate onMessage:message WithType:type];
}

- (void)dispatchDocumentUpdated {
  std::string data = debugrouter::processor::MessageAssembler::
      AssembleDispatchDocumentUpdated();
  [self sendDataAsync:[NSString stringWithUTF8String:data.c_str()]
             WithType:@"CDP"];
}
- (void)dispatchFrameNavigated:(NSString *)url {
  std::string data =
      debugrouter::processor::MessageAssembler::AssembleDispatchFrameNavigated(
          [url UTF8String]);
  [self sendDataAsync:[NSString stringWithUTF8String:data.c_str()]
             WithType:@"CDP"];
}

- (void)clearScreenCastCache {
  screenshot_cache_ = nil;
}

- (void)dispatchScreencastVisibilityChanged:(BOOL)status {
  std::string data = debugrouter::processor::MessageAssembler::
      AssembleDispatchScreencastVisibilityChanged(status);
  [self sendDataAsync:[NSString stringWithUTF8String:data.c_str()]
             WithType:@"CDP"];
}

- (void)sendScreenCast:(NSString *)data andMetadata:(NSDictionary *)metadata {
  if (!screenshot_cache_ || ![screenshot_cache_ isEqual:data]) {
    std::unordered_map<std::string, float> md;
    for (NSString *key in metadata) {
      md[[key UTF8String]] = [metadata[key] floatValue];
    }

    auto cdp_data =
        debugrouter::processor::MessageAssembler::AssembleScreenCastFrame(
            self.session_id, [data UTF8String], md);
    NSString *msg = [NSString stringWithUTF8String:cdp_data.c_str()];

    [self sendDataAsync:msg WithType:@"CDP"];
    screenshot_cache_ = data;
  }
}

@end
