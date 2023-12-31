//
//  UIViewController+BDPExtension.h
//  Timor
//
//  Created by liuxiangxin on 2019/9/26.
//

#import <UIKit/UIKit.h>

@interface UIViewController (BDPExtension)

/// A Boolean value indicating whether the view controller is presenting a view controller.
- (BOOL)bdp_isExcutePresenting;

/// Presents a modal view managed by the given view controller to the user.
///
/// 这个方法可以解决在当前的preset动画没完成之前，又在当前controller上present多个controller导致后面的controller无法present的问题。
/// 假设当前controller是A， 在present B controller完成之前，连续基于A present C D E 。
/// present完成之后，视图层级为 A -> B -> C -> D -> E ， 箭头左边的vc是箭头右边的presentedViewController。如 B 是 C 的presentedViewController
/// 反之， 箭头右边的是箭头左边的 presentingViewController 。
///
/// @param controller The view controller to display over the current view controller’s content.
/// @param animated Pass YES to animate the presentation; otherwise, pass NO.
/// @param completion The block to execute after the presentation finishes. This block has no return value and takes no parameters. You may specify nil for this parameter.
- (void)bdp_presentViewController:(UIViewController *)controller animated:(BOOL)animated completion:(dispatch_block_t)completion;

@end
