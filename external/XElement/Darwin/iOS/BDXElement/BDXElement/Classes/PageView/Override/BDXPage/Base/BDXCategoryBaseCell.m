//
//  BDXCategoryBaseCell.m

//
//  Created by jiaxin on 2018/3/15.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryBaseCell.h"
#import "BDXRTLManager.h"

@interface BDXCategoryBaseCell ()
@property (nonatomic, strong) BDXCategoryBaseCellModel *cellModel;
@property (nonatomic, strong) BDXCategoryViewAnimator *animator;
@property (nonatomic, strong) NSMutableArray <BDXCategoryCellSelectedAnimationBlock> *animationBlockArray;
@end

@implementation BDXCategoryBaseCell

#pragma mark - Initialize

- (void)dealloc {
    [self.animator stop];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [self.animator stop];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initializeViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self initializeViews];
    }
    return self;
}

#pragma mark - Public

- (void)initializeViews {
    _animationBlockArray = [NSMutableArray array];

    [BDXRTLManager horizontalFlipViewIfNeeded:self];
    [BDXRTLManager horizontalFlipViewIfNeeded:self.contentView];
}

- (void)reloadData:(BDXCategoryBaseCellModel *)cellModel {
    self.cellModel = cellModel;

    if (cellModel.isSelectedAnimationEnabled) {
        [self.animationBlockArray removeLastObject];
        if ([self checkCanStartSelectedAnimation:cellModel]) {
            self.animator = [[BDXCategoryViewAnimator alloc] init];
            self.animator.duration = cellModel.selectedAnimationDuration;
        } else {
            [self.animator stop];
        }
    }
}

- (BOOL)checkCanStartSelectedAnimation:(BDXCategoryBaseCellModel *)cellModel {
    BOOL canStartSelectedAnimation = ((cellModel.selectedType == BDXCategoryCellSelectedTypeCode) || (cellModel.selectedType == BDXCategoryCellSelectedTypeClick));
    return canStartSelectedAnimation;
}

- (void)addSelectedAnimationBlock:(BDXCategoryCellSelectedAnimationBlock)block {
    [self.animationBlockArray addObject:block];
}

- (void)startSelectedAnimationIfNeeded:(BDXCategoryBaseCellModel *)cellModel {
    if (cellModel.isSelectedAnimationEnabled && [self checkCanStartSelectedAnimation:cellModel]) {
        
        cellModel.transitionAnimating = YES;
        __weak typeof(self)weakSelf = self;
        self.animator.progressCallback = ^(CGFloat percent) {
            for (BDXCategoryCellSelectedAnimationBlock block in weakSelf.animationBlockArray) {
                block(percent);
            }
        };
        self.animator.completeCallback = ^{
            cellModel.transitionAnimating = NO;
            [weakSelf.animationBlockArray removeAllObjects];
        };
        [self.animator start];
    }
}

@end
