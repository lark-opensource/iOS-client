//
//  UIView+removeFromSuperview.h
//  LarkWebViewContainer
//
//  Created by baojianjun on 2022/7/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RenderState;
@interface UIView (LWRemoveFromSuperview)

- (void)hook_removeFromSuperview;

- (void)addNativeRenderState:(RenderState *)state;

@end

NS_ASSUME_NONNULL_END
