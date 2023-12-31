//
//  BDPImageView.m
//  Timor
//
//  Created by liuxiangxin on 2019/11/23.
//

#import "BDPImageView.h"
#import "BDPAppearanceHelper.h"

@implementation BDPImageView
@synthesize bdp_styleCategories = _bdp_styleCategories;

#pragma mark - Life cycle

STANDARD_MOVE_TO_WINDOW_IMPL

STANDARD_LAYOUT_SUB_VIES_IMPL

#pragma mark - BDPAppearance Implementation

+ (instancetype)bdp_styleForCategory:(NSString *)category
{
    return (BDPImageView *)[[BDPCascadeStyleManager sharedManager] styleNodeForClass:self category:category];
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
