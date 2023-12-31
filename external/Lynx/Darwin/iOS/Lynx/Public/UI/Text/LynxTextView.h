// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LynxUIText;
@class LynxTextRenderer;

@interface LynxTextView : UIView

@property(nonatomic, strong) CALayer* contentLayer;
@property(nonatomic, weak) LynxUIText* ui;
@property(nonatomic, weak) LynxTextRenderer* textRenderer;
@property(nonatomic, assign) UIEdgeInsets border;
@property(nonatomic, assign) UIEdgeInsets padding;
@property(nonatomic, assign) BOOL enableTextSelection;

- (void)updateSelectionColor:(UIColor*)color;

@end

NS_ASSUME_NONNULL_END
