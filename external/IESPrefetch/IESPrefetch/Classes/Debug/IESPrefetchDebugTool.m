//
//  IESPrefetchDebugTool.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/18.
//

#import "IESPrefetchDebugTool.h"
#import "IESPrefetchDebugViewController.h"

@implementation IESPrefetchDebugTool

+ (void)showDebugUIFromVC:(UIViewController *)vc
{
    IESPrefetchDebugViewController *debugVC = [IESPrefetchDebugViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:debugVC];
    [vc presentViewController:nav animated:YES completion:nil];
}

@end
