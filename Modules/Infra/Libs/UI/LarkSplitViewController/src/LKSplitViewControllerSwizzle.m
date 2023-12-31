//
//  LKSplitViewControllerSwizzle.m
//  LarkUIKit
//
//  Created by Jiayun Huang on 2019/9/26.
//

#import "LKSplitViewControllerSwizzle.h"
#import <LKLoadable/Loadable.h>

#pragma GCC diagnostic ignored "-Wundeclared-selector"

@implementation LKSplitViewControllerSwizzle
@end

LoadableDidFinishLaunchFuncBegin(hookViewControllerMethodBySplit)
[UIViewController performSelector: @selector(splitViewControllerSwizzleMethod)];
[UIViewController performSelector: @selector(lkSplitViewControllerSetupTababr)];
LoadableDidFinishLaunchFuncEnd(hookViewControllerMethodBySplit)

