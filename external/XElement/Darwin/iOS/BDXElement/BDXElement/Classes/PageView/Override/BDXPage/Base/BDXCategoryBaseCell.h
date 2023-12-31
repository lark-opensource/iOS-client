//
//  BDXCategoryBaseCell.h

//
//  Created by jiaxin on 2018/3/15.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDXCategoryBaseCellModel.h"
#import "BDXCategoryViewAnimator.h"
#import "BDXCategoryViewDefines.h"

@interface BDXCategoryBaseCell : UICollectionViewCell

@property (nonatomic, strong, readonly) BDXCategoryBaseCellModel *cellModel;
@property (nonatomic, strong, readonly) BDXCategoryViewAnimator *animator;

- (void)initializeViews NS_REQUIRES_SUPER;

- (void)reloadData:(BDXCategoryBaseCellModel *)cellModel NS_REQUIRES_SUPER;

- (BOOL)checkCanStartSelectedAnimation:(BDXCategoryBaseCellModel *)cellModel;

- (void)addSelectedAnimationBlock:(BDXCategoryCellSelectedAnimationBlock)block;

- (void)startSelectedAnimationIfNeeded:(BDXCategoryBaseCellModel *)cellModel;

@end
