//
//  BDXCategoryIndicatorRainbowLineView.m
//  BDXCategoryView
//
//  Created by jiaxin on 2018/12/13.
//  Copyright © 2018 jiaxin. All rights reserved.
//

#import "BDXCategoryIndicatorRainbowLineView.h"
#import "BDXCategoryFactory.h"

@implementation BDXCategoryIndicatorRainbowLineView

- (void)jx_refreshState:(BDXCategoryIndicatorParamsModel *)model {
    [super jx_refreshState:model];

    UIColor *color = self.indicatorColors[model.selectedIndex];
    self.backgroundColor = color;
}

- (void)jx_contentScrollViewDidScroll:(BDXCategoryIndicatorParamsModel *)model {
    [super jx_contentScrollViewDidScroll:model];

    UIColor *leftColor = self.indicatorColors[model.leftIndex];
    UIColor *rightColor = self.indicatorColors[model.rightIndex];
    UIColor *color = [BDXCategoryFactory interpolationColorFrom:leftColor to:rightColor percent:model.percent];
    self.backgroundColor = color;
}

- (void)jx_selectedCell:(BDXCategoryIndicatorParamsModel *)model {
    [super jx_selectedCell:model];

    UIColor *color = self.indicatorColors[model.selectedIndex];
    self.backgroundColor = color;
}


@end
