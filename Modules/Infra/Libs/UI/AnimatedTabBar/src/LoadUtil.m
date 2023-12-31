//
//  LoadUtil.m
//  AnimatedTabBar
//
//  Created by 李晨 on 2020/6/5.
//

#import "LoadUtil.h"
#import <AnimatedTabBar/AnimatedTabBar-Swift.h>
#import <LKLoadable/Loadable.h>

@implementation AnimatedTabLoadUtil
@end

LoadableDidFinishLaunchFuncBegin(hookMethodByAnimatedTabbar)
[AnimatedTabbarSwizzleKit swizzledIfNeeed];
LoadableDidFinishLaunchFuncEnd(hookMethodByAnimatedTabbar)
