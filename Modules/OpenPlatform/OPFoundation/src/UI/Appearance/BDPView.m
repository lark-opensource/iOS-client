//
//  BDPView.m
//  Timor
//
//  Created by liuxiangxin on 2019/11/23.
//

#import "BDPView.h"
#import "UIView+BDPAppearance.h"
#import "BDPCascadeStyleManager.h"
#import "BDPAppearanceHelper.h"

@interface BDPView ()

@end

@implementation BDPView
@synthesize bdp_styleCategories = _bdp_styleCategories;

#pragma mark - life cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    [BDPAppearanceHelper applyStyleForImpl:self];
}

- (void)layoutSubviews
{
    [BDPAppearanceHelper updateStyleForView:self];
    
    [super layoutSubviews];
}

#pragma mark - BDPAppearance Implementation

+ (instancetype)bdp_styleForCategory:(NSString *)category
{
    return (BDPView *)[[BDPCascadeStyleManager sharedManager] styleNodeForClass:self category:category];
}

- (void)setBdp_styleCategories:(NSArray<NSString *> *)bdp_styleCategories
{
    _bdp_styleCategories = bdp_styleCategories;
    
    for (NSString *category in bdp_styleCategories) {
        //pre set node
        [[BDPCascadeStyleManager sharedManager] styleNodeForClass:self.class category:category];
    }
}

@end
