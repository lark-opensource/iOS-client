//
//  BDXCategoryComponentBaseView.h
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/17.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDXCategoryIndicatorProtocol.h"
#import "BDXCategoryViewDefines.h"

@interface BDXCategoryIndicatorComponentView : UIView <BDXCategoryIndicatorProtocol>


@property (nonatomic, assign) BDXCategoryComponentPosition componentPosition;

@property (nonatomic, assign) CGFloat indicatorWidth;

@property (nonatomic, assign) CGFloat indicatorWidthIncrement;

@property (nonatomic, assign) CGFloat indicatorHeight;

@property (nonatomic, assign) CGFloat indicatorCornerRadius;

@property (nonatomic, strong) UIColor *indicatorColor;

@property (nonatomic, assign) CGFloat verticalMargin;

@property (nonatomic, assign, getter=isScrollEnabled) BOOL scrollEnabled;

@property (nonatomic, assign) BDXCategoryIndicatorScrollStyle scrollStyle;

@property (nonatomic, assign) NSTimeInterval scrollAnimationDuration;

- (CGFloat)indicatorWidthValue:(CGRect)cellFrame;

- (CGFloat)indicatorHeightValue:(CGRect)cellFrame;

- (CGFloat)indicatorCornerRadiusValue:(CGRect)cellFrame;

@end
