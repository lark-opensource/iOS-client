//
//  BDXTabBarCellModel.h
//  BDXElement
//
//  Created by hanzheng on 2021/3/5.
//

#import "BDXCategoryIndicatorCellModel.h"
#import <UIKit/UIKit.h>
#import "BDXCategoryViewDefines.h"
#import "BDXLynxTabbarItemPro.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXTabBarCellModel : BDXCategoryIndicatorCellModel

@property (nonatomic, strong)BDXLynxTabbarItemPro* tabbarItem;

@end

NS_ASSUME_NONNULL_END
