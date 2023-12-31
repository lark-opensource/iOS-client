//
//  TMAVideoOrientationHandler.m
//  OPPluginBiz
//
//  Created by bupozhuang on 2019/1/3.
//

#import "TMAVideoOrientationHandler.h"
#import "TMAPlayerView.h"
#import <Masonry/Masonry.h>
#import <OPFoundation/UIWindow+EMA.h>
#import "TMAVideoFullScreenViewController.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/OPFoundation-Swift.h>

@implementation TMAVideoOrientationHandler

/**
 *  屏幕转屏
 *
 *  @param orientation 屏幕方向
 */
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation
                isFullScreen:(BOOL)fullscreen
                  completion:(void (^)(BOOL))completion
{
    if (fullscreen) {
        WeakSelf;
        TMAVideoFullScreenViewController *vc = [[TMAVideoFullScreenViewController alloc] initWithTragetView:self.targetView orientation:orientation dismissCompletion:^{
            [wself.targetView addPlayerToFatherView];
            !completion ?: completion(NO);
            BDPLogInfo(@"TMAVideoOrientationHandler swipe exit fullscreen");
        }];
        UIViewController *topVC = [OPNavigatorHelper topMostAppControllerWithWindow:self.targetView.window];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        __weak TMAVideoFullScreenViewController *weakVC = vc;
        [[self topParent:topVC] presentViewController:vc animated:NO completion:^{
            [weakVC enter];
            !completion ?: completion(YES);
        }];
        self.targetView.isFullScreen = YES;
        BDPLogInfo(@"TMAVideoOrientationHandler fullscreen");
    } else {
        UIViewController *topVC = [OPNavigatorHelper topMostAppControllerWithWindow:self.targetView.window];
        if ([topVC isKindOfClass:TMAVideoFullScreenViewController.class]) {
            WeakSelf;
            [((TMAVideoFullScreenViewController *)topVC) exitWithCompletion:^{
                [wself.targetView addPlayerToFatherView];
                !completion ?: completion(NO);
                BDPLogInfo(@"TMAVideoOrientationHandler exit fullscreen complete");
            }];
        }
        BDPLogInfo(@"TMAVideoOrientationHandler exit fullscreen");
    }
}

- (UIViewController *)topParent:(UIViewController *)vc
{
    while (vc.parentViewController) {
        vc = vc.parentViewController;
    }
    return vc;
}

@end
