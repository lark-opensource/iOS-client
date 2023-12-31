//
//  BDXLynxTabBarPro.h
//  BDXElement
//
//  Created by hanzheng on 2021/3/17.
//

#import <Foundation/Foundation.h>
#import <Lynx/LynxUI.h>
#import "BDXTabBarCategoryView.h"

NS_ASSUME_NONNULL_BEGIN

@class BDXLynxTabbarItemPro;

@protocol BDXTabBarProTagDelegate <NSObject>

- (void)tabBarTagDidChanged;

@end

@interface BDXLynxTabBarPro : LynxUI <BDXTabBarCategoryView *>

@property (nonatomic) NSMutableArray<BDXLynxTabbarItemPro *> *tabItems;

@property (nonatomic, weak) id<BDXTabBarProTagDelegate> tagDelegate;

@end

NS_ASSUME_NONNULL_END
