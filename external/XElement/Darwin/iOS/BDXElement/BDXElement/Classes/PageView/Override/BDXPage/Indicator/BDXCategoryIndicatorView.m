//
//  BDXCategoryIndicatorView.m
//  DQGuess
//
//  Created by jiaxin on 2018/7/25.
//  Copyright © 2018年 jingbo. All rights reserved.
//

#import "BDXCategoryIndicatorView.h"
#import "BDXCategoryIndicatorBackgroundView.h"
#import "BDXCategoryFactory.h"
#import "BDXCategoryIndicatorLineView.h"

@interface BDXCategoryIndicatorView()

@property (nonatomic,strong)UIView *lineView;

@end

@implementation BDXCategoryIndicatorView

- (void)initializeData {
    [super initializeData];
    _separatorLineShowEnabled = NO;
    _separatorLineColor = [UIColor lightGrayColor];
    _separatorLineSize = CGSizeMake(1/[UIScreen mainScreen].scale, 20);
    _cellBackgroundColorGradientEnabled = NO;
    _cellBackgroundUnselectedColor = [UIColor whiteColor];
    _cellBackgroundSelectedColor = [UIColor lightGrayColor];
}

- (void)initializeViews {
    [super initializeViews];
    _lineView = [[UIView alloc]initWithFrame:CGRectZero];
    _lineView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_lineView];
    [self sendSubviewToBack:_lineView];
}

- (void)setIndicators:(NSArray<UIView<BDXCategoryIndicatorProtocol> *> *)indicators {
    _indicators = indicators;

    self.collectionView.indicators = indicators;
}

- (void)refreshState {
    [super refreshState];
    [self resetLineView];
    CGRect selectedCellFrame = CGRectZero;
    BDXCategoryIndicatorCellModel *selectedCellModel;
    for (int i = 0; i < self.dataSource.count; i++) {
        BDXCategoryIndicatorCellModel *cellModel = (BDXCategoryIndicatorCellModel *)self.dataSource[i];
        cellModel.sepratorLineShowEnabled = self.isSeparatorLineShowEnabled;
        cellModel.separatorLineColor = self.separatorLineColor;
        cellModel.separatorLineSize = self.separatorLineSize;
        cellModel.backgroundViewMaskFrame = CGRectZero;
        cellModel.cellBackgroundColorGradientEnabled = self.isCellBackgroundColorGradientEnabled;
        cellModel.cellBackgroundSelectedColor = self.cellBackgroundSelectedColor;
        cellModel.cellBackgroundUnselectedColor = self.cellBackgroundUnselectedColor;
        if (i == self.dataSource.count - 1) {
            cellModel.sepratorLineShowEnabled = NO;
        }
        if (i == self.selectedIndex) {
            selectedCellModel = cellModel;
            selectedCellFrame = [self getTargetCellFrame:i];
        }
    }

    for (UIView<BDXCategoryIndicatorProtocol> *indicator in self.indicators) {
        if (self.dataSource.count <= 0) {
            indicator.hidden = YES;
        } else {
            indicator.hidden = NO;
            BDXCategoryIndicatorParamsModel *indicatorParamsModel = [[BDXCategoryIndicatorParamsModel alloc] init];
            indicatorParamsModel.selectedIndex = self.selectedIndex;
            indicatorParamsModel.selectedCellFrame = selectedCellFrame;
            [indicator jx_refreshState:indicatorParamsModel];

            if ([indicator isKindOfClass:[BDXCategoryIndicatorBackgroundView class]]) {
                CGRect maskFrame = indicator.frame;
                maskFrame.origin.x = maskFrame.origin.x - selectedCellFrame.origin.x;
                selectedCellModel.backgroundViewMaskFrame = maskFrame;
            }
        }
    }
}

- (void)resetLineView {
    _lineView.hidden = self.bottomBorderConfig.hidden;
    if (self.bottomBorderConfig.hidden) {
        return;
    }
    [_lineView setBackgroundColor:self.bottomBorderConfig.color];
    [_lineView removeConstraints:_lineView.constraints];
    [NSLayoutConstraint activateConstraints:@[
        [_lineView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_lineView.widthAnchor constraintEqualToConstant:self.bottomBorderConfig.width],
        [_lineView.heightAnchor constraintEqualToConstant:self.bottomBorderConfig.height],
        [_lineView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-self.bottomBorderConfig.margin]
    ]];
}

- (void)refreshSelectedCellModel:(BDXCategoryBaseCellModel *)selectedCellModel unselectedCellModel:(BDXCategoryBaseCellModel *)unselectedCellModel {
    [super refreshSelectedCellModel:selectedCellModel unselectedCellModel:unselectedCellModel];

    BDXCategoryIndicatorCellModel *myUnselectedCellModel = (BDXCategoryIndicatorCellModel *)unselectedCellModel;
    myUnselectedCellModel.backgroundViewMaskFrame = CGRectZero;
    myUnselectedCellModel.cellBackgroundUnselectedColor = self.cellBackgroundUnselectedColor;
    myUnselectedCellModel.cellBackgroundSelectedColor = self.cellBackgroundSelectedColor;

    BDXCategoryIndicatorCellModel *myselectedCellModel = (BDXCategoryIndicatorCellModel *)selectedCellModel;
    myselectedCellModel.cellBackgroundUnselectedColor = self.cellBackgroundUnselectedColor;
    myselectedCellModel.cellBackgroundSelectedColor = self.cellBackgroundSelectedColor;
}

- (void)contentOffsetOfContentScrollViewDidChanged:(CGPoint)contentOffset {
    [super contentOffsetOfContentScrollViewDidChanged:contentOffset];
    
    CGFloat ratio = contentOffset.x/self.contentScrollView.bounds.size.width;
    if (ratio > self.dataSource.count - 1 || ratio < 0) {
        return;
    }
    ratio = MAX(0, MIN(self.dataSource.count - 1, ratio));
    NSInteger baseIndex = floorf(ratio);
    if (baseIndex + 1 >= self.dataSource.count) {
        return;
    }
    CGFloat remainderRatio = ratio - baseIndex;

    CGRect leftCellFrame = [self getTargetCellFrame:baseIndex];
    CGRect rightCellFrame = [self getTargetCellFrame:baseIndex + 1];

    BDXCategoryIndicatorParamsModel *indicatorParamsModel = [[BDXCategoryIndicatorParamsModel alloc] init];
    indicatorParamsModel.selectedIndex = self.selectedIndex;
    indicatorParamsModel.leftIndex = baseIndex;
    indicatorParamsModel.leftCellFrame = leftCellFrame;
    indicatorParamsModel.rightIndex = baseIndex + 1;
    indicatorParamsModel.rightCellFrame = rightCellFrame;
    indicatorParamsModel.percent = remainderRatio;
    if (remainderRatio == 0) {
        for (UIView<BDXCategoryIndicatorProtocol> *indicator in self.indicators) {
            [indicator jx_contentScrollViewDidScroll:indicatorParamsModel];
        }
    } else {
        BDXCategoryIndicatorCellModel *leftCellModel = (BDXCategoryIndicatorCellModel *)self.dataSource[baseIndex];
        leftCellModel.selectedType = BDXCategoryCellSelectedTypeUnknown;
        BDXCategoryIndicatorCellModel *rightCellModel = (BDXCategoryIndicatorCellModel *)self.dataSource[baseIndex + 1];
        rightCellModel.selectedType = BDXCategoryCellSelectedTypeUnknown;
        [self refreshLeftCellModel:leftCellModel rightCellModel:rightCellModel ratio:remainderRatio];

        for (UIView<BDXCategoryIndicatorProtocol> *indicator in self.indicators) {
            [indicator jx_contentScrollViewDidScroll:indicatorParamsModel];
            if ([indicator isKindOfClass:[BDXCategoryIndicatorBackgroundView class]]) {
                CGRect leftMaskFrame = indicator.frame;
                leftMaskFrame.origin.x = leftMaskFrame.origin.x - leftCellFrame.origin.x;
                leftCellModel.backgroundViewMaskFrame = leftMaskFrame;

                CGRect rightMaskFrame = indicator.frame;
                rightMaskFrame.origin.x = rightMaskFrame.origin.x - rightCellFrame.origin.x;
                rightCellModel.backgroundViewMaskFrame = rightMaskFrame;
            }
        }

        BDXCategoryBaseCell *leftCell = (BDXCategoryBaseCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:baseIndex inSection:0]];
        [leftCell reloadData:leftCellModel];
        BDXCategoryBaseCell *rightCell = (BDXCategoryBaseCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:baseIndex + 1 inSection:0]];
        [rightCell reloadData:rightCellModel];
    }
}

- (BOOL)selectCellAtIndex:(NSInteger)index selectedType:(BDXCategoryCellSelectedType)selectedType {
    NSInteger lastSelectedIndex = self.selectedIndex;
    BOOL result = [super selectCellAtIndex:index selectedType:selectedType];
    if (!result) {
        return NO;
    }

    CGRect clickedCellFrame = [self getTargetSelectedCellFrame:index selectedType:selectedType];
    
    BDXCategoryIndicatorCellModel *selectedCellModel = (BDXCategoryIndicatorCellModel *)self.dataSource[index];
    selectedCellModel.selectedType = selectedType;
    for (UIView<BDXCategoryIndicatorProtocol> *indicator in self.indicators) {
        BDXCategoryIndicatorParamsModel *indicatorParamsModel = [[BDXCategoryIndicatorParamsModel alloc] init];
        indicatorParamsModel.lastSelectedIndex = lastSelectedIndex;
        indicatorParamsModel.selectedIndex = index;
        indicatorParamsModel.selectedCellFrame = clickedCellFrame;
        indicatorParamsModel.selectedType = selectedType;
        [indicator jx_selectedCell:indicatorParamsModel];
        if ([indicator isKindOfClass:[BDXCategoryIndicatorBackgroundView class]]) {
            CGRect maskFrame = indicator.frame;
            maskFrame.origin.x = maskFrame.origin.x - clickedCellFrame.origin.x;
            selectedCellModel.backgroundViewMaskFrame = maskFrame;
        }
    }

    BDXCategoryIndicatorCell *selectedCell = (BDXCategoryIndicatorCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    [selectedCell reloadData:selectedCellModel];

    return YES;
}

@end

@implementation BDXCategoryIndicatorView (UISubclassingIndicatorHooks)

- (void)refreshLeftCellModel:(BDXCategoryBaseCellModel *)leftCellModel rightCellModel:(BDXCategoryBaseCellModel *)rightCellModel ratio:(CGFloat)ratio {
    if (self.isCellBackgroundColorGradientEnabled) {

        BDXCategoryIndicatorCellModel *leftModel = (BDXCategoryIndicatorCellModel *)leftCellModel;
        BDXCategoryIndicatorCellModel *rightModel = (BDXCategoryIndicatorCellModel *)rightCellModel;
        if (leftModel.isSelected) {
            leftModel.cellBackgroundSelectedColor = [BDXCategoryFactory interpolationColorFrom:self.cellBackgroundSelectedColor to:self.cellBackgroundUnselectedColor percent:ratio];
            leftModel.cellBackgroundUnselectedColor = self.cellBackgroundUnselectedColor;
        }else {
            leftModel.cellBackgroundUnselectedColor = [BDXCategoryFactory interpolationColorFrom:self.cellBackgroundSelectedColor to:self.cellBackgroundUnselectedColor percent:ratio];
            leftModel.cellBackgroundSelectedColor = self.cellBackgroundSelectedColor;
        }
        if (rightModel.isSelected) {
            rightModel.cellBackgroundSelectedColor = [BDXCategoryFactory interpolationColorFrom:self.cellBackgroundUnselectedColor to:self.cellBackgroundSelectedColor percent:ratio];
            rightModel.cellBackgroundUnselectedColor = self.cellBackgroundUnselectedColor;
        }else {
            rightModel.cellBackgroundUnselectedColor = [BDXCategoryFactory interpolationColorFrom:self.cellBackgroundUnselectedColor to:self.cellBackgroundSelectedColor percent:ratio];
            rightModel.cellBackgroundSelectedColor = self.cellBackgroundSelectedColor;
        }
    }
}

@end
