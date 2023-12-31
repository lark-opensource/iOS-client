//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Lynx/LynxUI.h>
#import "BDXLynxTabBarPro.h"
#import "BDXTabBarCategoryView.h"
#import "BDXLynxFoldViewSlotDragLight.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxFoldViewSlotLight : LynxUI
@property (nonatomic, weak) BDXLynxTabBarPro *tabbarPro;
@property (nonatomic, weak) BDXLynxFoldViewSlotDragLight *slotDrag;
@end

NS_ASSUME_NONNULL_END
