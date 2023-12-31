//
//  BDPAppearanceHelper.h
//  Timor
//
//  Created by liuxiangxin on 2019/11/23.
//

#import <UIKit/UIKit.h>
#import "BDPAppearance.h"
#import "BDPCascadeStyleManager.h"

#define STANDARD_MOVE_TO_WINDOW_IMPL \
- (void)didMoveToWindow \
{ \
    [super didMoveToWindow]; \
    [BDPAppearanceHelper applyStyleForImpl:self]; \
}

#define STANDARD_LAYOUT_SUB_VIES_IMPL \
- (void)layoutSubviews \
{ \
    [super layoutSubviews]; \
    [BDPAppearanceHelper updateStyleForView:self]; \
} \

NS_ASSUME_NONNULL_BEGIN

@interface BDPAppearanceHelper : NSObject

+ (void)applyStyleForImpl:(id<BDPAppearance>)impl;

+ (void)updateStyleForView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
