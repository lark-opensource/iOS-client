//
//  UIGestureRecognizer+AutoTrack.h
//  Applog
//
//  Created by bob on 2019/1/15.
//

#import <UIKit/UIKit.h>

//  hook UIGestureRecognizer 的
//
//  target 相关方法
//
//  方法，来拦截 UIView 的手势动作
// 包括
// 1. View 的单击 长按事件
// 2. 系统alertView的长按事件也会在这里

NS_ASSUME_NONNULL_BEGIN

@interface UIGestureRecognizer (AutoTrack)

@end


NS_ASSUME_NONNULL_END
