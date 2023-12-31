//
//  BDPAppearanceHelper.m
//  Timor
//
//  Created by liuxiangxin on 2019/11/23.
//


#import "BDPAppearanceHelper.h"
#import "BDPCascadeStyleManager.h"
#import "UIView+BDPAppearance.h"

@implementation BDPAppearanceHelper

+ (void)applyStyleForImpl:(id<BDPAppearance>)impl
{
    for (NSString *category in impl.bdp_styleCategories) {
        [[BDPCascadeStyleManager sharedManager] applyStyleForObject:impl category:category];
    }
}

+ (void)updateStyleForView:(UIView *)view
{
    [view bdp_updateCornerRadius];
    [view bdp_updateRectCorners];
}

@end
