// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxUIComponent.h"
#import "LynxComponentRegistry.h"
#import "LynxPropsProcessor.h"
#import "LynxUI+Internal.h"

@implementation LynxUIComponent
#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("component")
#else
LYNX_REGISTER_UI("component")
#endif

- (void)onNodeReady {
  [super onNodeReady];
  if (self.layoutObserver &&
      [self.layoutObserver respondsToSelector:@selector(onComponentLayoutUpdated:)]) {
    [self.layoutObserver onComponentLayoutUpdated:self];
  }
}

LYNX_PROP_SETTER("item-key", setItemKey, NSString*) {
  if (requestReset) {
    value = nil;
  }
  self.itemKey = value;
}

- (void)asyncListItemRenderFinished:(int64_t)operationID {
  if (self.layoutObserver && [self.layoutObserver respondsToSelector:@selector
                                                  (onAsyncComponentLayoutUpdated:operationID:)]) {
    [self.layoutObserver onAsyncComponentLayoutUpdated:self operationID:operationID];
  }
}
@end
