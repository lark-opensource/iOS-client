//
//  BDXTabBarCell.m
//  BDXElement
//
//  Created by hanzheng on 2021/3/5.
//

#import "BDXTabBarCell.h"
#import "BDXTabBarCellModel.h"

@implementation BDXTabBarCell

- (void)initializeViews {
    [super initializeViews];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)reloadData:(BDXCategoryBaseCellModel *)cellModel {
    [super reloadData:cellModel];
    BDXTabBarCellModel *tabbarModel = (BDXTabBarCellModel *)cellModel;
    for (UIView *view in self.contentView.subviews) {
        [view removeFromSuperview];
    }
    [self.contentView addSubview:tabbarModel.tabbarItem.view];
    tabbarModel.tabbarItem.view.frame = self.bounds;
}

@end
