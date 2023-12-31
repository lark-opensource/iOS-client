//
//  UIViewController+TroubleKillerHook.m
//  EETroubleKiller
//
//  Created by Meng on 2019/5/13.
//

#import "UIViewController+TroubleKillerHook.h"
#import <LKLoadable/Loadable.h>

#pragma GCC diagnostic ignored "-Wundeclared-selector"

@implementation UIViewController(TroubleKillerHook)

@end

LoadableMainFuncBegin(troubleKillerTask)
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    [UIViewController performSelector: @selector(troubleKillerSwizzleMethod)];
});
LoadableMainFuncEnd(troubleKillerTask)
