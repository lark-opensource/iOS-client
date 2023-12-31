// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxEventEmitter.h"
#import "LynxEventDetail.h"
#import "LynxLog.h"
#import "LynxRootUI.h"
#import "LynxTemplateData+Converter.h"
#import "LynxTemplateRender+Internal.h"
#import "LynxUIIntersectionObserver.h"

#include "lepus/json_parser.h"
#include "lepus/table.h"
#include "tasm/lepus_api_actor/lepus_api_actor.h"
#include "tasm/react/element.h"
#include "tasm/react/element_manager.h"

using namespace lynx::tasm;
using namespace lynx::lepus;

@implementation LynxEventEmitter {
  __weak LynxTemplateRender* _render;
  NSMutableArray* eventObservers_;
}

- (instancetype)initWithLynxTemplateRender:(LynxTemplateRender*)render {
  self = [super init];
  if (self) {
    _render = render;
    eventObservers_ = [[NSMutableArray alloc] init];
  }
  return self;
}

- (bool)dispatchTouchEvent:(LynxTouchEvent*)event target:(id<LynxEventTarget>)target {
  __strong LynxTemplateRender* render = _render;
  if (render == nil) {
    LLogError(@"dispatchTouchEvent event: %@ failed since render is nil", event.eventName);
    return NO;
  }
  LynxEventDetail* detail = [[LynxEventDetail alloc] initWithEvent:TOUCH_EVENT
                                                              name:[event eventName]
                                                          lynxView:_render.uiOwner.rootUI.lynxView];
  detail.targetPoint = [event viewPoint];
  if ([target dispatchEvent:detail]) {
    return YES;
  }
  [render onLynxEvent:detail];
  return [render sendSyncTouchEvent:event];
}

- (void)dispatchCustomEvent:(LynxCustomEvent*)event {
  __strong LynxTemplateRender* render = _render;
  if (render != nil) {
    [render sendCustomEvent:event];
  } else {
    LLogError(@"dispatchCustomEvent event: %@ failed since render is nil", event.eventName);
  }
  [self notifyEventObservers:LynxEventTypeCustomEvent event:event];
}

- (void)sendCustomEvent:(LynxCustomEvent*)event {
  [self dispatchCustomEvent:event];
}

- (void)onPseudoStatusChanged:(int32_t)tag
                fromPreStatus:(int32_t)preStatus
              toCurrentStatus:(int32_t)currentStatus {
  __strong LynxTemplateRender* render = _render;
  if (render == nil) {
    LLogError(@"onPseudoStatusChanged id: %d failed since render is nil", tag);
    return;
  }
  if (preStatus == currentStatus) {
    return;
  }
  [render onPseudoStatusChanged:tag fromPreStatus:preStatus toCurrentStatus:currentStatus];
}

- (void)dispatchLayoutEvent {
  [self notifyEventObservers:LynxEventTypeLayoutEvent event:nil];
}

- (void)addObserver:(id<LynxEventObserver>)observer {
  if (![eventObservers_ containsObject:observer]) {
    [eventObservers_ addObject:observer];
  }
}

- (void)removeObserver:(id<LynxEventObserver>)observer {
  if ([eventObservers_ containsObject:observer]) {
    [eventObservers_ removeObject:observer];
  }
}

- (void)notifyEventObservers:(LynxEventType)type event:(LynxEvent*)event {
  [eventObservers_
      enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        // if use new IntersectionObserver, don't notify observer here.
        if ([obj isKindOfClass:[LynxUIIntersectionObserverManager class]] &&
            ((LynxUIIntersectionObserverManager*)obj).enableNewIntersectionObserver) {
          return;
        }
        [(id<LynxEventObserver>(obj)) onLynxEvent:type event:event];
      }];
}

- (void)notifyIntersectionObserver {
  dispatch_block_t block = ^() {
    __strong LynxTemplateRender* render = self->_render;
    if (render == nil) {
      return;
    }
    [render notifyIntersectionObservers];
  };
  if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL),
             dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
    // if on main thread, exec block
    block();
  } else {
    // if not on main thread, post to main thread
    dispatch_async(dispatch_get_main_queue(), block);
  }
}

@end
