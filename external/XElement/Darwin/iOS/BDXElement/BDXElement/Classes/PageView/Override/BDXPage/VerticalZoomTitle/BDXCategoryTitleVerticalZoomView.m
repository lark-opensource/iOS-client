//
//  BDXCategoryTitleVerticalZoomView.m
//  BDXCategoryView
//
//  Created by jiaxin on 2019/2/14.
//  Copyright © 2019 jiaxin. All rights reserved.
//

#import "BDXCategoryTitleVerticalZoomView.h"
#import "BDXCategoryTitleVerticalZoomCellModel.h"
#import "BDXCategoryTitleVerticalZoomCell.h"
#import "BDXCategoryFactory.h"

@interface BDXCategoryTitleVerticalZoomView ()
@property (nonatomic, assign) CGFloat currentVerticalScale;
@end

@implementation BDXCategoryTitleVerticalZoomView

- (void)initializeData {
    [super initializeData];

    _maxVerticalFontScale = 2;
    _minVerticalFontScale = 1.3;
    _currentVerticalScale = _maxVerticalFontScale;
    self.cellWidthZoomEnabled = YES;
    self.cellWidthZoomScale = _maxVerticalFontScale;
    self.contentEdgeInsetLeft = 15;
    self.titleLabelZoomScale = _currentVerticalScale;
    self.titleLabelZoomEnabled = YES;
    self.selectedAnimationEnabled = YES;
    _maxVerticalCellSpacing = 20;
    _minVerticalCellSpacing = 10;
    self.cellSpacing = _maxVerticalCellSpacing;
}

- (void)listDidScrollWithVerticalHeightPercent:(CGFloat)percent {
    CGFloat currentScale = [BDXCategoryFactory interpolationFrom:self.minVerticalFontScale to:self.maxVerticalFontScale percent:percent];
    BOOL shouldReloadData = NO;
    if (self.currentVerticalScale != currentScale) {
        shouldReloadData = YES;
    }
    self.currentVerticalScale = currentScale;
    self.cellWidthZoomScale = currentScale;
    self.cellSpacing = [BDXCategoryFactory interpolationFrom:self.minVerticalCellSpacing to:self.maxVerticalCellSpacing percent:percent];
    if (shouldReloadData) {
        [self refreshDataSource];
        [self refreshState];
        [self.collectionView.collectionViewLayout invalidateLayout];
        [self.collectionView reloadData];
    }
}

- (void)setCurrentVerticalScale:(CGFloat)currentVerticalScale {
    _currentVerticalScale = currentVerticalScale;

    self.titleLabelZoomScale = currentVerticalScale;
}

- (void)setMaxVerticalCellSpacing:(CGFloat)maxVerticalCellSpacing {
    _maxVerticalCellSpacing = maxVerticalCellSpacing;

    self.cellSpacing = maxVerticalCellSpacing;
}

- (void)setMaxVerticalFontScale:(CGFloat)maxVerticalFontScale {
    _maxVerticalFontScale = maxVerticalFontScale;

    self.titleLabelZoomScale = maxVerticalFontScale;
    self.cellWidthZoomScale = maxVerticalFontScale;
}

- (Class)preferredCellClass {
    return [BDXCategoryTitleVerticalZoomCell class];
}

- (void)refreshDataSource {
    NSMutableArray *tempArray = [NSMutableArray array];
    for (int i = 0; i < self.titles.count; i++) {
        BDXCategoryTitleVerticalZoomCellModel *cellModel = [[BDXCategoryTitleVerticalZoomCellModel alloc] init];
        [tempArray addObject:cellModel];
    }
    self.dataSource = tempArray;
}

- (void)refreshCellModel:(BDXCategoryBaseCellModel *)cellModel index:(NSInteger)index {
    [super refreshCellModel:cellModel index:index];

    BDXCategoryTitleVerticalZoomCellModel *model = (BDXCategoryTitleVerticalZoomCellModel *)cellModel;
    model.maxVerticalFontScale = self.maxVerticalFontScale;
}

@end
