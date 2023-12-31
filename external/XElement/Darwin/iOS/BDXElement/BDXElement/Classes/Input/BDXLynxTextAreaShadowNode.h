// Copyright 2020 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <Lynx/LynxCustomMeasureShadowNode.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxTextAreaShadowNode : LynxCustomMeasureShadowNode<LynxCustomMeasureDelegate>

@property (nonatomic, assign, readwrite) BOOL needRelayout;
@property (nonatomic, assign, readonly) BOOL isAutoSize;
@property (nonatomic, assign, readwrite) CGFloat mHeightAtMost;
@property (nonatomic, assign, readwrite) CGFloat mWidthAtMost;
@property (atomic, strong, readwrite) UIFont *fontFromUI;
@property (atomic, strong, readwrite) NSNumber *textHeightFromUI;
@property (atomic, strong, readwrite) NSNumber *heightFromUI;

- (BOOL)updateSizeIfNeeded;
@end

NS_ASSUME_NONNULL_END
