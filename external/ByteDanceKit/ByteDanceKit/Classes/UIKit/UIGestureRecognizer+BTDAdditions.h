//
//  UIGestureRecognizer+BTDAdditions.h
//  ByteDanceKit
//
//  Created by wangdi on 2018/3/2.
//

#import <UIKit/UIKit.h>

@interface UIGestureRecognizer (BTDAdditions)

/**
 以block的形式创建一个手势

 @param block 当手势触发的时候回调block
 @return 生成一个手势对象
 */
+ (nonnull instancetype)btd_gestureRecognizerWithActionBlock:(nonnull void (^)(id _Nonnull sender))block;

/**
 添加一个手势的回调

 @param block 当手势触发的时候回调block
 */
- (void)btd_addActionBlock:(nonnull void (^)(id _Nonnull sender))block;

/**
 删除所有的回调
 */
- (void)btd_removeAllActionBlocks;

@end
