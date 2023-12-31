// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LynxEventEmitter.h"
#import "LynxEventTarget.h"

NS_ASSUME_NONNULL_BEGIN

@class LynxTouchHandler;
@class LynxUIOwner;
@class LynxUI;

@interface LynxEventHandler : NSObject

@property(nonatomic, weak, readonly) UIView *rootView;
@property(nonatomic, weak, readonly) LynxEventEmitter *eventEmitter;
@property(nonatomic, copy, readonly) LynxTouchHandler *touchRecognizer;
@property(nonatomic, copy, readonly) UIGestureRecognizer *tapRecognizer;
@property(nonatomic, copy, readonly) UIGestureRecognizer *longPressRecognizer;

- (instancetype)initWithRootView:(UIView *)rootView;
- (instancetype)initWithRootView:(UIView *)rootView withRootUI:(nullable LynxUI *)rootUI;

- (void)attachLynxView:(UIView *)rootView;

- (void)updateUiOwner:(nullable LynxUIOwner *)owner eventEmitter:(LynxEventEmitter *)eventEmitter;

- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event;

- (void)onGestureRecognized;
- (void)onGestureRecognizedByEventTarget:(id<LynxEventTarget>)ui;
- (void)resetEventEnv;
- (BOOL)canRespondTapOrClickEvent:(id<LynxEventTarget>)ui;

- (void)dispatchTapEvent:(UITapGestureRecognizer *)sender;

- (void)dispatchLongPressEvent:(UILongPressGestureRecognizer *)sender;

- (id<LynxEventTarget>)touchTarget;
@end

NS_ASSUME_NONNULL_END
