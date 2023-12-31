//
//  BDXCategoryDotCellModel.h
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/20.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryTitleCellModel.h"

typedef NS_ENUM(NSUInteger, BDXCategoryDotRelativePosition) {
    BDXCategoryDotRelativePosition_TopLeft = 0,
    BDXCategoryDotRelativePosition_TopRight,
    BDXCategoryDotRelativePosition_BottomLeft,
    BDXCategoryDotRelativePosition_BottomRight,
};

@interface BDXCategoryDotCellModel : BDXCategoryTitleCellModel

@property (nonatomic, assign) BOOL dotHidden;
@property (nonatomic, assign) BDXCategoryDotRelativePosition relativePosition;
@property (nonatomic, assign) CGSize dotSize;
@property (nonatomic, assign) CGFloat dotCornerRadius;
@property (nonatomic, strong) UIColor *dotColor;
@property (nonatomic, assign) CGPoint dotOffset;

@end
