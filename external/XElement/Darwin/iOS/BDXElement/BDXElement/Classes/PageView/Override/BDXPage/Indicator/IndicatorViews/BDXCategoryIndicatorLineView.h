//
//  BDXCategoryIndicatorLineView.h
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/17.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryIndicatorComponentView.h"

typedef NS_ENUM(NSUInteger, BDXCategoryIndicatorLineStyle) {
    BDXCategoryIndicatorLineStyle_Normal         = 0,
    BDXCategoryIndicatorLineStyle_Lengthen       = 1,
    BDXCategoryIndicatorLineStyle_LengthenOffset = 2,
};

@interface BDXCategoryIndicatorLineView : BDXCategoryIndicatorComponentView

@property (nonatomic, assign) BDXCategoryIndicatorLineStyle lineStyle;

@property (nonatomic, assign) CGFloat lineScrollOffsetX;

@end
