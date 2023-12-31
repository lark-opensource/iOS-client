//
//  BDXCategoryView.h

//
//  Created by jiaxin on 2018/3/15.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryIndicatorView.h"
#import "BDXCategoryTitleCell.h"
#import "BDXCategoryTitleCellModel.h"
#import "BDXCategoryViewDefines.h"

@class BDXCategoryTitleView;

@protocol BDXCategoryTitleViewDataSource <NSObject>
@optional

- (CGFloat)categoryTitleView:(BDXCategoryTitleView *)titleView widthForTitle:(NSString *)title;
@end


@interface BDXCategoryTitleView : BDXCategoryIndicatorView

@property (nonatomic, weak) id<BDXCategoryTitleViewDataSource> titleDataSource;

@property (nonatomic, strong) NSArray <NSString *>*titles;

@property (nonatomic, assign) NSInteger titleNumberOfLines;

@property (nonatomic, strong) UIColor *titleColor;

@property (nonatomic, strong) UIColor *titleSelectedColor;

@property (nonatomic, strong) UIFont *titleFont;

@property (nonatomic, strong) UIFont *titleSelectedFont;

@property (nonatomic, assign, getter=isTitleColorGradientEnabled) BOOL titleColorGradientEnabled;

@property (nonatomic, assign, getter=isTitleLabelMaskEnabled) BOOL titleLabelMaskEnabled;

@property (nonatomic, assign, getter=isTitleLabelZoomEnabled) BOOL titleLabelZoomEnabled;

@property (nonatomic, assign, getter=isTitleLabelZoomScrollGradientEnabled) BOOL titleLabelZoomScrollGradientEnabled;

@property (nonatomic, assign) CGFloat titleLabelZoomScale;

@property (nonatomic, assign) CGFloat titleLabelZoomSelectedVerticalOffset;

@property (nonatomic, assign, getter=isTitleLabelStrokeWidthEnabled) BOOL titleLabelStrokeWidthEnabled;

@property (nonatomic, assign) CGFloat titleLabelSelectedStrokeWidth;

@property (nonatomic, assign) CGFloat titleLabelVerticalOffset;

@property (nonatomic, assign) BDXCategoryTitleLabelAnchorPointStyle titleLabelAnchorPointStyle;  

@end
