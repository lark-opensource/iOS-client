//
//  BDXTabBarCategoryView.h
//  BDXElement
//
//  Created by hanzheng on 2021/3/5.
//

#import <Foundation/Foundation.h>
#import "BDXCategoryIndicatorView.h"

NS_ASSUME_NONNULL_BEGIN
@class BDXLynxTabBarPro;

@interface BDXTabBarCategoryView : BDXCategoryIndicatorView

@property (nonatomic, weak)BDXLynxTabBarPro* lynxTabbar;

@end

NS_ASSUME_NONNULL_END
