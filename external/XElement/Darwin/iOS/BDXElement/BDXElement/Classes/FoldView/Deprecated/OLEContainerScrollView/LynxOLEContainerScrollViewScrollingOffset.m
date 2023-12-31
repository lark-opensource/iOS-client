/*
 OLEContainerScrollView
 
 Copyright (c) 2014 Ole Begemann.
 https://github.com/ole/OLEContainerScrollView
 */

#import "LynxOLEContainerScrollViewScrollingOffset.h"
#import "LynxOLEContainerScrollView.h"
#import "LynxOLEContainerScrollView_Private.h"

@implementation LynxOLEContainerScrollViewScrollingOffset

- (void)didAddSubview:(UIView *)subview
{
    [super didAddSubview:subview];
    if ([self.superview isKindOfClass:[LynxOLEContainerScrollView class]]) {
        [(LynxOLEContainerScrollView *)self.superview didAddSubviewToContainer:subview];
    }
}

- (void)willRemoveSubview:(UIView *)subview
{
    if ([self.superview isKindOfClass:[LynxOLEContainerScrollView class]]) {
        [(LynxOLEContainerScrollView *)self.superview willRemoveSubviewFromContainer:subview];
    }
    [super willRemoveSubview:subview];
}

@end
