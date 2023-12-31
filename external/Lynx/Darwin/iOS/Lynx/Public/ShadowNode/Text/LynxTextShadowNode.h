// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxBaseTextShadowNode.h"
#import "LynxConverter.h"
#import "LynxCustomMeasureDelegate.h"
#import "LynxMeasureDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxTextShadowNode : LynxBaseTextShadowNode <LynxCustomMeasureDelegate>

@end

@interface LynxConverter (LynxWhiteSpaceType)

@end

@interface LynxConverter (LynxTextOverflow)

@end

@interface LineSpacingAdaptation : NSObject <NSLayoutManagerDelegate>
@property(nonatomic) CGFloat calculatedLineSpacing;
@property(nonatomic) BOOL adjustBaseLineOffsetForVerticalAlignCenter;
@property(nonatomic) CGFloat baseLineOffsetForVerticalAlignCenter;
@property(nonatomic) BOOL breakByChar;
@property(nonatomic) CGFloat halfLeading;
@property(nonatomic) CGFloat lineHeight;
@property(nonatomic) CGFloat maxLineAscender;
@property(nonatomic) CGFloat maxLineDescender;
@property(nonatomic) BOOL enableLayoutRefactor;
@property(nonatomic) NSMutableAttributedString *attributedString;
@property(nonatomic) CGFloat baseline;
@end

NS_ASSUME_NONNULL_END
