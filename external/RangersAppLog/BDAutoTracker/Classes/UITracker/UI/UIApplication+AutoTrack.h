//
//  UIApplication+AutoTrack.h
//  Applog
//
//  Created by bob on 2019/1/15.
//

#import <UIKit/UIKit.h>

//  hook UIApplication 的
//
//  sendAction:(SEL)action
//          to:(nullable id)to
//        from:(nullable id)from
//    forEvent:(nullable UIEvent *)event
//
//  方法，来拦截 UIControl 的action
// 包括
// 1. button 的点击事件
// 2.系统导航栏按钮的事件


NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (AutoTrack)

@end

NS_ASSUME_NONNULL_END
