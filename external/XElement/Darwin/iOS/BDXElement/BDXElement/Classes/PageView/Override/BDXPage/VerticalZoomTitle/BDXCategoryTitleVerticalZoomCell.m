//
//  BDXCategoryTitleVerticalZoomCell.m
//  BDXCategoryView
//
//  Created by jiaxin on 2019/2/14.
//  Copyright © 2019 jiaxin. All rights reserved.
//

#import "BDXCategoryTitleVerticalZoomCell.h"
#import "BDXCategoryTitleVerticalZoomCellModel.h"

@implementation BDXCategoryTitleVerticalZoomCell

- (void)reloadData:(BDXCategoryBaseCellModel *)cellModel {
    [super reloadData:cellModel];

    BDXCategoryTitleVerticalZoomCellModel *myCellModel = (BDXCategoryTitleVerticalZoomCellModel *)cellModel;

    if (myCellModel.isTitleLabelZoomEnabled) {
        
        UIFont *maxScaleFont = [UIFont fontWithDescriptor:myCellModel.titleFont.fontDescriptor size:myCellModel.titleFont.pointSize*myCellModel.maxVerticalFontScale];
        CGFloat baseScale = myCellModel.titleFont.lineHeight/maxScaleFont.lineHeight;
        if (myCellModel.isSelectedAnimationEnabled && [self checkCanStartSelectedAnimation:myCellModel]) {
            BDXCategoryCellSelectedAnimationBlock block = [self preferredTitleZoomAnimationBlock:myCellModel baseScale:baseScale];
            [self addSelectedAnimationBlock:block];
        } else {
            self.titleLabel.font = maxScaleFont;
            self.maskTitleLabel.font = maxScaleFont;
            CGAffineTransform currentTransform = CGAffineTransformMakeScale(baseScale*myCellModel.titleLabelCurrentZoomScale, baseScale*myCellModel.titleLabelCurrentZoomScale);
            self.titleLabel.transform = currentTransform;
            self.maskTitleLabel.transform = currentTransform;
        }
    } else {
        if (myCellModel.isSelected) {
            self.titleLabel.font = myCellModel.titleSelectedFont;
            self.maskTitleLabel.font = myCellModel.titleSelectedFont;
        }else {
            self.titleLabel.font = myCellModel.titleFont;
            self.maskTitleLabel.font = myCellModel.titleFont;
        }
    }

    [self.titleLabel sizeToFit];
}
@end
