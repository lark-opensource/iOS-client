//
//  UIButton+BTDAdditions.m
//  Pods
//
//  Created by yanglinfeng on 2019/7/3.
//

#import "UIButton+BTDAdditions.h"
#import "UIControl+BTDAdditions.h"

@implementation UIButton (BTDAdditions)

- (void)btd_addActionBlockForTouchUpInside:(void (^)(__kindof UIButton * _Nonnull))block {
    [self btd_addActionBlock:block forControlEvents:UIControlEventTouchUpInside];
}

@end
