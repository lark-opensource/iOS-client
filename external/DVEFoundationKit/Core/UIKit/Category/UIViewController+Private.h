//
//  UIViewController+Private.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/11/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (Private)

/// 关闭当前的VC，没有完成回调
/// @param animated 是否有动画效果
- (void)dve_closeViewControllerAnimated:(BOOL)animated;

/// 关闭当前VC，有完成回调
/// @param animated 是否有动画效果
/// @param completion 完成回调
- (void)dve_closeViewControllerAnimated:(BOOL)animated completion:(dispatch_block_t _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
