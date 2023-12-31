//
//  BDXLossImageView.m
//  Pods
//
//  Created by hanzheng on 2021/2/23.
//

#import "BDXLossImageView.h"

@implementation BDXLossImageView

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [_delegate viewWillMoveToWindow:newWindow];
}

@end
