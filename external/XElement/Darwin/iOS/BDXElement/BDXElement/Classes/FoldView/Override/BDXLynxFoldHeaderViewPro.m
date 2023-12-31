//
//  BDXLynxFoldViewProItem.m
//  BDXElement
//
//  Created by AKing on 2020/9/24.
//

#import "BDXLynxFoldHeaderViewPro.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>

@interface BDXLynxFoldHeaderViewPro ()

@property (nonatomic, assign) CGRect headerViewFrame;

@end

@implementation BDXLynxFoldHeaderViewPro

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-foldview-header-pro")
#else
LYNX_REGISTER_UI("x-foldview-header-pro")
#endif

- (UIView*)createView {
    UIView* view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor clearColor]];
    return view;
}

- (void)layoutDidFinished {
    if (!CGRectEqualToRect(self.headerViewFrame, self.view.frame)) {
        self.headerViewFrame = self.view.frame;
        [self.delegate lynxFoldHeaderLayoutIfNeeded:self];
    }
}

@end
