//
//  UIView+ACCRTL.m
//  Pods
//
//  Created by chengfei xiao on 2019/8/19.
//

#import "UIView+ACCRTL.h"
#import <objc/runtime.h>

@implementation UIView (ACCRTL)


- (void)setAccrtl_viewType:(ACCRTLViewType)accrtl_viewType
{
    if (self.accrtl_viewType == accrtl_viewType) {
        return;
    }
    objc_setAssociatedObject(self, @selector(accrtl_viewType), @(accrtl_viewType), OBJC_ASSOCIATION_RETAIN);
    
    [ACCRTL() setRTLTypeWithView:self type:accrtl_viewType];
}

- (ACCRTLViewType)accrtl_viewType
{
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}


@end
