//
//  BDXCategoryView.m

//
//  Created by jiaxin on 2018/3/15.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryTitleView.h"
#import "BDXCategoryFactory.h"

@implementation BDXCategoryTitleView

- (void)initializeData {
    [super initializeData];

    _titleNumberOfLines = 1;
    _titleLabelZoomEnabled = NO;
    _titleLabelZoomScale = 1.2;
    _titleColor = [UIColor blackColor];
    _titleSelectedColor = [UIColor redColor];
    _titleFont = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _titleSelectedFont = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    _titleColorGradientEnabled = NO;
    _titleLabelMaskEnabled = NO;
    _titleLabelZoomScrollGradientEnabled = YES;
    _titleLabelStrokeWidthEnabled = NO;
    _titleLabelSelectedStrokeWidth = -3;
    _titleLabelVerticalOffset = 0;
    _titleLabelAnchorPointStyle = BDXCategoryTitleLabelAnchorPointStyleCenter;
}

- (UIFont *)titleSelectedFont {
    if (_titleSelectedFont) {
        return _titleSelectedFont;
    }
    return self.titleFont;
}

#pragma mark - Override

- (Class)preferredCellClass {
    return [BDXCategoryTitleCell class];
}

- (void)refreshDataSource {
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:self.titles.count];
    for (int i = 0; i < self.titles.count; i++) {
        BDXCategoryTitleCellModel *cellModel = [[BDXCategoryTitleCellModel alloc] init];
        [tempArray addObject:cellModel];
    }
    self.dataSource = [NSArray arrayWithArray:tempArray];
}

- (void)refreshSelectedCellModel:(BDXCategoryBaseCellModel *)selectedCellModel unselectedCellModel:(BDXCategoryBaseCellModel *)unselectedCellModel {
    [super refreshSelectedCellModel:selectedCellModel unselectedCellModel:unselectedCellModel];

    BDXCategoryTitleCellModel *myUnselectedCellModel = (BDXCategoryTitleCellModel *)unselectedCellModel;
    BDXCategoryTitleCellModel *myselectedCellModel = (BDXCategoryTitleCellModel *)selectedCellModel;
    if (self.isSelectedAnimationEnabled && (selectedCellModel.selectedType == BDXCategoryCellSelectedTypeClick || selectedCellModel.selectedType == BDXCategoryCellSelectedTypeCode)) {
     
        BOOL isUnselectedCellVisible = NO;
        BOOL isSelectedCellVisible = NO;
        NSArray *indexPaths = [self.collectionView indexPathsForVisibleItems];
        for (NSIndexPath *indexPath in indexPaths) {
            if (indexPath.item == myUnselectedCellModel.index) {
                isUnselectedCellVisible = YES;
                continue;
            } else if (indexPath.item == myselectedCellModel.index) {
                isSelectedCellVisible = YES;
                continue;
            }
        }
        if (!isUnselectedCellVisible) {
          
            myUnselectedCellModel.titleCurrentColor = myUnselectedCellModel.titleNormalColor;
            myUnselectedCellModel.titleLabelCurrentZoomScale = myUnselectedCellModel.titleLabelNormalZoomScale;
            myUnselectedCellModel.titleLabelCurrentStrokeWidth = myUnselectedCellModel.titleLabelNormalStrokeWidth;
        }
        if (!isSelectedCellVisible) {
            
            myselectedCellModel.titleCurrentColor = myselectedCellModel.titleSelectedColor;
            myselectedCellModel.titleLabelCurrentZoomScale = myselectedCellModel.titleLabelSelectedZoomScale;
            myselectedCellModel.titleLabelCurrentStrokeWidth = myselectedCellModel.titleLabelSelectedStrokeWidth;
        }
    } else {
     
        myselectedCellModel.titleCurrentColor = myselectedCellModel.titleSelectedColor;
        myselectedCellModel.titleLabelCurrentZoomScale = myselectedCellModel.titleLabelSelectedZoomScale;
        myselectedCellModel.titleLabelCurrentStrokeWidth = myselectedCellModel.titleLabelSelectedStrokeWidth;

        myUnselectedCellModel.titleCurrentColor = myUnselectedCellModel.titleNormalColor;
        myUnselectedCellModel.titleLabelCurrentZoomScale = myUnselectedCellModel.titleLabelNormalZoomScale;
        myUnselectedCellModel.titleLabelCurrentStrokeWidth = myUnselectedCellModel.titleLabelNormalStrokeWidth;
    }
}

- (void)refreshLeftCellModel:(BDXCategoryBaseCellModel *)leftCellModel rightCellModel:(BDXCategoryBaseCellModel *)rightCellModel ratio:(CGFloat)ratio {
    [super refreshLeftCellModel:leftCellModel rightCellModel:rightCellModel ratio:ratio];

    BDXCategoryTitleCellModel *leftModel = (BDXCategoryTitleCellModel *)leftCellModel;
    BDXCategoryTitleCellModel *rightModel = (BDXCategoryTitleCellModel *)rightCellModel;

    if (self.isTitleLabelZoomEnabled && self.isTitleLabelZoomScrollGradientEnabled) {
        leftModel.titleLabelCurrentZoomScale = [BDXCategoryFactory interpolationFrom:self.titleLabelZoomScale to:1.0 percent:ratio];
        rightModel.titleLabelCurrentZoomScale = [BDXCategoryFactory interpolationFrom:1.0 to:self.titleLabelZoomScale percent:ratio];
    }

    if (self.isTitleLabelStrokeWidthEnabled) {
        leftModel.titleLabelCurrentStrokeWidth = [BDXCategoryFactory interpolationFrom:leftModel.titleLabelSelectedStrokeWidth to:leftModel.titleLabelNormalStrokeWidth percent:ratio];
        rightModel.titleLabelCurrentStrokeWidth = [BDXCategoryFactory interpolationFrom:rightModel.titleLabelNormalStrokeWidth to:rightModel.titleLabelSelectedStrokeWidth percent:ratio];
    }

    if (self.isTitleColorGradientEnabled) {
        leftModel.titleCurrentColor = [BDXCategoryFactory interpolationColorFrom:self.titleSelectedColor to:self.titleColor percent:ratio];
        rightModel.titleCurrentColor = [BDXCategoryFactory interpolationColorFrom:self.titleColor to:self.titleSelectedColor percent:ratio];
    }
}

- (CGFloat)preferredCellWidthAtIndex:(NSInteger)index {
    if (self.cellWidth == BDXCategoryViewAutomaticDimension) {
        if (self.titleDataSource && [self.titleDataSource respondsToSelector:@selector(categoryTitleView:widthForTitle:)]) {
            return [self.titleDataSource categoryTitleView:self widthForTitle:self.titles[index]];
        } else {
            return ceilf([self.titles[index] boundingRectWithSize:CGSizeMake(MAXFLOAT, self.bounds.size.height) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : self.titleFont} context:nil].size.width);
        }
    } else {
        return self.cellWidth;
    }
}

- (void)refreshCellModel:(BDXCategoryBaseCellModel *)cellModel index:(NSInteger)index {
    [super refreshCellModel:cellModel index:index];

    BDXCategoryTitleCellModel *model = (BDXCategoryTitleCellModel *)cellModel;
    model.title = self.titles[index];
    model.titleNumberOfLines = self.titleNumberOfLines;
    model.titleFont = self.titleFont;
    model.titleSelectedFont = self.titleSelectedFont;
    model.titleNormalColor = self.titleColor;
    model.titleSelectedColor = self.titleSelectedColor;
    model.titleLabelMaskEnabled = self.isTitleLabelMaskEnabled;
    model.titleLabelZoomEnabled = self.isTitleLabelZoomEnabled;
    model.titleLabelNormalZoomScale = 1;
    model.titleLabelZoomSelectedVerticalOffset = self.titleLabelZoomSelectedVerticalOffset;
    if(self.titleFont.pointSize != 0) {
        self.titleLabelZoomScale = self.titleSelectedFont.pointSize/self.titleFont.pointSize;
    }
    model.titleLabelSelectedZoomScale = self.titleLabelZoomScale;
    model.titleLabelStrokeWidthEnabled = self.isTitleLabelStrokeWidthEnabled;
    model.titleLabelNormalStrokeWidth = 0;
    model.titleLabelSelectedStrokeWidth = self.titleLabelSelectedStrokeWidth;
    model.titleLabelVerticalOffset = self.titleLabelVerticalOffset;
    model.titleLabelAnchorPointStyle = self.titleLabelAnchorPointStyle;
    if (index == self.selectedIndex) {
        model.titleCurrentColor = model.titleSelectedColor;
        model.titleLabelCurrentZoomScale = model.titleLabelSelectedZoomScale;
        model.titleLabelCurrentStrokeWidth= model.titleLabelSelectedStrokeWidth;
    }else {
        model.titleCurrentColor = model.titleNormalColor;
        model.titleLabelCurrentZoomScale = model.titleLabelNormalZoomScale;
        model.titleLabelCurrentStrokeWidth = model.titleLabelNormalStrokeWidth;
    }
}

@end
