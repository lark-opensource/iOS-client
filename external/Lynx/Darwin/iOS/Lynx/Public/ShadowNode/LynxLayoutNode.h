// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LynxComponent.h"
#import "LynxCustomMeasureDelegate.h"
#import "LynxLayoutStyle.h"
#import "LynxMeasureDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxLayoutNode<__covariant V> : LynxComponent <V>

@property(nonatomic, readonly, assign) CGRect frame;
@property(nonatomic, readonly, assign) UIEdgeInsets padding;
@property(nonatomic, readonly, assign) UIEdgeInsets margin;
@property(nonatomic, readonly, assign) UIEdgeInsets border;
@property(nonatomic, readonly, nullable) LynxLayoutStyle* style;
@property(nonatomic, weak) id<LynxMeasureDelegate> measureDelegate;
@property(nonatomic, weak) id<LynxCustomMeasureDelegate> customMeasureDelegate;

- (void)adoptNativeLayoutNode:(int64_t)ptr;
- (void)updateLayoutWithFrame:(CGRect)frame;

/**
 * Request layout and it will happens on next vsync.
 * Call this method when something relevant to the frame of view has change.
 */
- (void)setNeedsLayout;
- (BOOL)needsLayout;

- (void)layoutDidStart;
- (void)layoutDidUpdate;

/**
 * When hasCustomLayout return true, this node will handle layouting
 * it's children, otherwise the layout position of children still
 * respect the result given by native layout system.
 *
 * @return If node can handle child layout, return true otherwise false.
 */
- (BOOL)hasCustomLayout;

@end

NS_ASSUME_NONNULL_END
