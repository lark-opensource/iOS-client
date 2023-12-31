//
//  BDXCategoryDotView.h
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/20.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryTitleView.h"
#import "BDXCategoryDotCell.h"
#import "BDXCategoryDotCellModel.h"

@interface BDXCategoryDotView : BDXCategoryTitleView


@property (nonatomic, assign) BDXCategoryDotRelativePosition relativePosition;

@property (nonatomic, strong) NSArray <NSNumber *> *dotStates;
//default：CGSizeMake(10, 10)
@property (nonatomic, assign) CGSize dotSize;
//default：BDXCategoryViewAutomaticDimension（self.dotSize.height/2）
@property (nonatomic, assign) CGFloat dotCornerRadius;
//default：[UIColor redColor]
@property (nonatomic, strong) UIColor *dotColor;

@property (nonatomic, assign) CGPoint dotOffset;

@end
