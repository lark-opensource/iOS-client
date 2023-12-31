//
//  CJPayTransitionManager.h
//  CJPay
//
//  Created by 王新华 on 2019/6/19.
//

#import <Foundation/Foundation.h>
#import "CJPayNavigationController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayTransitionManager : NSObject<UINavigationControllerDelegate, UIViewControllerTransitioningDelegate>

+ (instancetype)transitionManagerWithNavi:(CJPayNavigationController *)navi;

- (void)handleGesture:(UIPanGestureRecognizer *)panGesture;

@end

NS_ASSUME_NONNULL_END
