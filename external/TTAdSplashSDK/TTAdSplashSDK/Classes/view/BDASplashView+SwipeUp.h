//
//  BDASplashView+SwipeUp.h
//  ABRInterface
//
//  Created by YangFani on 2020/8/23.
//

#import "BDASplashView.h"

NS_ASSUME_NONNULL_BEGIN

/// 给 self.bgButton 添加上滑手势能力支持
@interface BDASplashView (SwipeUp)

/// 若需要则创建向上滑动手势
- (void)setupSplashSwipGestureIfNeeded;

@end

NS_ASSUME_NONNULL_END
