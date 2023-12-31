//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <Lynx/LynxUI.h>
#import "BDXLynxTabBarPro.h"
#import "BDXTabBarCategoryView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxFoldViewSlotDragLight : LynxUI
@property (nonatomic, assign) BOOL forbidMovable;
@property (nonatomic, weak) BDXLynxTabBarPro *tabbarPro;
@end

NS_ASSUME_NONNULL_END
