//
//  UIGestureRecognizer+BTDAdditions.h
//  ByteDanceKit
//
//  Created by wangdi on 2018/3/2.
//

#import <UIKit/UIKit.h>

@interface UIGestureRecognizer (BTDAdditions)

/**
 Initialize a UIGestureRecognize with a block.

 @param block The action block.
 @return A UIGestureRecognize.
 */
+ (nonnull instancetype)btd_gestureRecognizerWithActionBlock:(nonnull void (^)(id _Nonnull sender))block;

/**
 Add an action block.

 @param block A block which will be executed after the UIGestureRecognize is triggered on.
 */
- (void)btd_addActionBlock:(nonnull void (^)(id _Nonnull sender))block;

/**
 Removing all action blocks.
 */
- (void)btd_removeAllActionBlocks;

@end
