//
//  BDXCategoryViewDefines.h
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/17.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static const CGFloat BDXCategoryViewAutomaticDimension = -1;

typedef void(^BDXCategoryCellSelectedAnimationBlock)(CGFloat percent);


typedef NS_ENUM(NSUInteger, BDXCategoryComponentPosition) {
    BDXCategoryComponentPosition_Bottom,
    BDXCategoryComponentPosition_Top
};


typedef NS_ENUM(NSUInteger, BDXCategoryCellSelectedType) {
    BDXCategoryCellSelectedTypeUnknown,
    BDXCategoryCellSelectedTypeClick,
    BDXCategoryCellSelectedTypeCode,
    BDXCategoryCellSelectedTypeScroll   
};


typedef NS_ENUM(NSUInteger, BDXCategoryTitleLabelAnchorPointStyle) {
    BDXCategoryTitleLabelAnchorPointStyleCenter,
    BDXCategoryTitleLabelAnchorPointStyleTop,
    BDXCategoryTitleLabelAnchorPointStyleBottom
};


typedef NS_ENUM(NSUInteger, BDXCategoryIndicatorScrollStyle) {
    BDXCategoryIndicatorScrollStyleSimple,
    BDXCategoryIndicatorScrollStyleSameAsUserScroll
};

// Cell layout direction when the tabbar is not full
typedef NS_ENUM(NSUInteger, BDXTabLayoutGravity) {
    BDXTabLayoutGravityLeft = 1,
    BDXTabLayoutGravityCenter,
    BDXTabLayoutGravityFill
};


#define BDXCategoryViewDeprecated(instead) NS_DEPRECATED(2_0, 2_0, 2_0, 2_0, instead)
