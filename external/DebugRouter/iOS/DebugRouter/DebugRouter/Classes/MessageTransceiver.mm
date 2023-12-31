#import "MessageTransceiver.h"
#import <objc/message.h>

#define dispatch_main_async_safe(block)                                        \
  if ([NSThread isMainThread]) {                                               \
    block();                                                                   \
  } else {                                                                     \
    dispatch_async(dispatch_get_main_queue(), block);                          \
  }

#define WeakSelf(type) __weak typeof(type) weak##type = type;

@implementation MessageTransceiver {
  NSTimer *heart_beat_;
  NSTimeInterval reconnect_time_;
  NSString *url_;
}

- (BOOL)connect:(NSString *)url {
  return NO;
}

- (void)handleReceivedMessage:(id)message {
  if (self.delegate_) {
    [self.delegate_ onMessage:message fromTransceiver:self];
  }
}

- (void)initHeartBeat {
  dispatch_main_async_safe(^{
    [self destoryHeartBeat];
    // ping server every 30s
    self->heart_beat_ = [NSTimer timerWithTimeInterval:30
                                                target:self
                                              selector:@selector(ping)
                                              userInfo:nil
                                               repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self->heart_beat_
                                 forMode:NSRunLoopCommonModes];
  })
}

- (void)destoryHeartBeat {
  dispatch_main_async_safe(^{
    if (self->heart_beat_) {
      if ([self->heart_beat_ respondsToSelector:@selector(isValid)]) {
        if ([self->heart_beat_ isValid]) {
          [self->heart_beat_ invalidate];
          self->heart_beat_ = nil;
        }
      }
    }
  })
}

@end
