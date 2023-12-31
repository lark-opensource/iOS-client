// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxEvent.h"
#import "LynxEventTarget.h"
#import "LynxTouchEvent.h"

NS_ASSUME_NONNULL_BEGIN

@class LynxTemplateRender;

typedef NS_ENUM(NSInteger, LynxEventType) {
  LynxEventTypeTouchEvent,
  LynxEventTypeCustomEvent,
  LynxEventTypeLayoutEvent,
};

@protocol LynxEventObserver

- (void)onLynxEvent:(LynxEventType)type event:(LynxEvent*)event;

@end

/**
 * Emit event to front-end
 */
@interface LynxEventEmitter : NSObject

- (instancetype)initWithLynxTemplateRender:(LynxTemplateRender*)render;

- (bool)dispatchTouchEvent:(LynxTouchEvent*)event target:(id<LynxEventTarget>)target;

- (void)dispatchCustomEvent:(LynxCustomEvent*)event;

- (void)sendCustomEvent:(LynxCustomEvent*)event;

// TODO(songshourui.null): use this interface to handle touch status change
- (void)onPseudoStatusChanged:(int32_t)tag
                fromPreStatus:(int32_t)preStatus
              toCurrentStatus:(int32_t)currentStatus;

- (void)dispatchLayoutEvent;

- (void)addObserver:(id<LynxEventObserver>)observer;
- (void)removeObserver:(id<LynxEventObserver>)observer;
- (void)notifyIntersectionObserver;

@end

NS_ASSUME_NONNULL_END
