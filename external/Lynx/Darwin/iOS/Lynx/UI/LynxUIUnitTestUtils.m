//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxUIUnitTestUtils.h"
#import "LynxUI+Internal.h"
#import "LynxUI.h"
#import "LynxUIOwner.h"
#import "LynxUIView.h"

@implementation LynxEventEmitterUnitTestHelper

- (void)sendCustomEvent:(LynxCustomEvent *)event {
  [super sendCustomEvent:event];
  _event = event;
}

@end

@implementation LynxUIMockContext
@end

@implementation LynxUIUnitTestUtils

+ (LynxUIMockContext *)initUIMockContextWithUI:(LynxUI *)ui {
  LynxUIMockContext *context = [[LynxUIMockContext alloc] init];
  context.mockUI = ui;
  [context.mockUI updateFrame:CGRectMake(0, 0, 428, 926)
                  withPadding:UIEdgeInsetsZero
                       border:UIEdgeInsetsZero
          withLayoutAnimation:false];

  // make strong reference to eventEmitter and UIContext, or they will only have weak references.
  context.mockEventEmitter = [[LynxEventEmitterUnitTestHelper alloc] init];
  context.mockUIContext = [[LynxUIContext alloc] init];

  context.mockUIContext.eventEmitter = context.mockEventEmitter;
  context.mockUI.context = context.mockUIContext;
  return context;
}

@end
