//
//  RTLManager.m
//  BDXCategoryView
//
//  Created by jiaxin on 2020/7/3.
//

#import "BDXRTLManager.h"

@implementation BDXRTLManager

+ (BOOL)supportRTL {
    return [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:UIView.appearance.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft;
}

+ (void)horizontalFlipView:(UIView *)view {
    view.transform = CGAffineTransformMakeScale(-1, 1);
}

+ (void)horizontalFlipViewIfNeeded:(UIView *)view {
    if ([self supportRTL]) {
        [self horizontalFlipView:view];
    }
}

@end
