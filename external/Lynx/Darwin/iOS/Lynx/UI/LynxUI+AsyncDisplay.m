// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxUI+Internal.h"

#import <libkern/OSAtomic.h>
#import "LynxDefines.h"
#import "LynxTemplateRender+Internal.h"
#import "LynxUIText.h"
#import "LynxUIUnitUtils.h"
#import "LynxUnitUtils.h"
#import "LynxView+Internal.h"

@implementation LynxUI (AsyncDisplay)

+ (void)drawRect:(CGRect)bounds withParameters:(id)drawParameters {
}

- (id)drawParameter {
  return nil;
}

+ (dispatch_queue_t)displayQueue {
  static dispatch_queue_t displayQueue = NULL;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    displayQueue = dispatch_queue_create("com.bytedance.lynx.asyncDisplay.displayQueue",
                                         DISPATCH_QUEUE_SERIAL);
    // we use the highpri queue to prioritize UI rendering over other async operations
    dispatch_set_target_queue(displayQueue,
                              dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
  });

  return displayQueue;
}

#ifndef LYNX_CHECK_CANCELLED_AND_RETURN_NIL
#define LYNX_CHECK_CANCELLED_AND_RETURN_NIL(expr) \
  if (isCancelledBlock()) {                       \
    expr;                                         \
    return nil;                                   \
  }

- (BOOL)enableAsyncDisplay {
  BOOL config = ((LynxView *)self.context.rootView).templateRender.enableAsyncDisplay;
  return config && _asyncDisplayFromTTML;
}

- (void)displayAsynchronously {
  __weak LynxUI *weakSelf = self;
  [self displayAsyncWithCompletionBlock:^(UIImage *_Nonnull image) {
    CALayer *layer = weakSelf.view.layer;
    layer.contents = (id)image.CGImage;
    layer.contentsScale = [LynxUIUnitUtils screenScale];
  }];
}

- (void)displayComplexBackgroundAsynchronouslyWithDisplay:
            (lynx_async_get_background_image_block_t)displayBlock
                                               completion:(lynx_async_display_completion_block_t)
                                                              completionBlock {
  if (self.enableAsyncDisplay) {
    dispatch_async([self.class displayQueue], ^{
      UIImage *value = displayBlock();
      dispatch_async(dispatch_get_main_queue(), ^{
        completionBlock(value);
      });
    });
  } else {
    id value;
    @try {
      value = displayBlock();
    } @catch (NSException *exception) {
    }
    completionBlock(value);
  }
}

- (void)displayAsyncWithCompletionBlock:(lynx_async_display_completion_block_t)block {
  CGRect bounds = {.origin = CGPointZero, .size = self.frame.size};
  if (CGSizeEqualToSize(bounds.size, CGSizeZero)) {
    return;
  }
  NSAssert(self.view.layer != nil, @"LynxUI+AsyncDispaly should has layer.");
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  int32_t displaySentinelValue = OSAtomicIncrement32(&_displaySentinel);
#pragma GCC diagnostic pop
  __weak LynxUI *weakSelf = self;
  id drawParameter = [weakSelf drawParameter];
  lynx_iscancelled_block_t isCancelledBlock = ^BOOL {
    __strong LynxUI *strongSelf = weakSelf;
    return strongSelf == nil || (displaySentinelValue != strongSelf->_displaySentinel);
  };
  lynx_async_operation_block_t displayBlock = ^id {
    LYNX_CHECK_CANCELLED_AND_RETURN_NIL();
    UIGraphicsBeginImageContextWithOptions(weakSelf.frameSize, NO, [LynxUIUnitUtils screenScale]);
    [weakSelf.class drawRect:bounds withParameters:drawParameter];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
  };
  lynx_async_operation_completion_block_t completionBlock = ^(id value, BOOL canceled) {
    LynxMainThreadChecker();
    if (!canceled && !isCancelledBlock()) {
      UIImage *image = (UIImage *)value;
      block(image);
    }
  };
  if (self.enableAsyncDisplay) {
    dispatch_async([self.class displayQueue], ^{
      id value;
      @try {
        value = displayBlock();
      } @catch (NSException *exception) {
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        completionBlock(value, value == nil);
      });
    });
  } else {
    id value = displayBlock();
    completionBlock(value, value == nil);
  }
}
@end

#endif
