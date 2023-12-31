//
//  BDXCategoryTitleCell.h

//
//  Created by jiaxin on 2018/3/15.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryIndicatorCell.h"
#import "BDXCategoryViewDefines.h"
@class BDXCategoryTitleCellModel;

@interface BDXCategoryTitleCell : BDXCategoryIndicatorCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *maskTitleLabel;
@property (nonatomic, strong) NSLayoutConstraint *titleLabelCenterX;
@property (nonatomic, strong) NSLayoutConstraint *titleLabelCenterY;
@property (nonatomic, strong) NSLayoutConstraint *maskTitleLabelCenterX;

- (BDXCategoryCellSelectedAnimationBlock)preferredTitleZoomAnimationBlock:(BDXCategoryTitleCellModel *)cellModel baseScale:(CGFloat)baseScale;

- (BDXCategoryCellSelectedAnimationBlock)preferredTitleStrokeWidthAnimationBlock:(BDXCategoryTitleCellModel *)cellModel attributedString:(NSMutableAttributedString *)attributedString;

- (BDXCategoryCellSelectedAnimationBlock)preferredTitleColorAnimationBlock:(BDXCategoryTitleCellModel *)cellModel;

@end
