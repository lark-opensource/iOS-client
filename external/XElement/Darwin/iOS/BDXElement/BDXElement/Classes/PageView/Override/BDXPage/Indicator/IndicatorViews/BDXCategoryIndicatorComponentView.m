//
//  BDXCategoryComponentBaseView.m
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/17.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryIndicatorComponentView.h"

@implementation BDXCategoryIndicatorComponentView

#pragma mark - Initialize

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self configureDefaultValue];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self configureDefaultValue];
    }
    return self;
}

- (void)configureDefaultValue {
    _componentPosition = BDXCategoryComponentPosition_Bottom;
    _scrollEnabled = YES;
    _verticalMargin = 0;
    _scrollAnimationDuration = 0.25;
    _indicatorWidth = BDXCategoryViewAutomaticDimension;
    _indicatorWidthIncrement = 0;
    _indicatorHeight = 3;
    _indicatorCornerRadius = BDXCategoryViewAutomaticDimension;
    _indicatorColor = [UIColor redColor];
    _scrollStyle = BDXCategoryIndicatorScrollStyleSimple;
}

#pragma mark - Public

- (CGFloat)indicatorWidthValue:(CGRect)cellFrame {
    if (self.indicatorWidth == BDXCategoryViewAutomaticDimension) {
        return cellFrame.size.width + self.indicatorWidthIncrement;
    }
    return self.indicatorWidth + self.indicatorWidthIncrement;
}

- (CGFloat)indicatorHeightValue:(CGRect)cellFrame {
    if (self.indicatorHeight == BDXCategoryViewAutomaticDimension) {
        return cellFrame.size.height;
    }
    return self.indicatorHeight;
}

- (CGFloat)indicatorCornerRadiusValue:(CGRect)cellFrame {
    if (self.indicatorCornerRadius == BDXCategoryViewAutomaticDimension) {
        return [self indicatorHeightValue:cellFrame]/2;
    }
    return self.indicatorCornerRadius;
}

#pragma mark - BDXCategoryIndicatorProtocol

- (void)jx_refreshState:(BDXCategoryIndicatorParamsModel *)model {

}

- (void)jx_contentScrollViewDidScroll:(BDXCategoryIndicatorParamsModel *)model {

}

- (void)jx_selectedCell:(BDXCategoryIndicatorParamsModel *)model {
    
}

@end
