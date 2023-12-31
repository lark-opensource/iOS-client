//
//  LarkBackgroundTaskMonitor.m
//  Action
//
//  Created by KT on 2019/7/17.
//

#import "LarkBackgroundTaskMonitor.h"
#import <LKLoadable/Loadable.h>
//#import <LarkApp/LarkApp-swift.h>
#pragma GCC diagnostic ignored "-Wundeclared-selector"

@implementation UIApplication(LarkBackgroundTaskMonitor)

@end

LoadableRunloopIdleFuncBegin(backgroundTask)
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    [UIApplication performSelector: @selector(swizzleMethod)];
});
LoadableRunloopIdleFuncEnd(backgroundTask)
