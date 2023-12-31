//
//  UIControl+BTDAdditions.h
//  Pods
//
//  Created by yanglinfeng on 2019/7/3.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIControl (BTDAdditions)

/**
 Adds a block for a particular event (or events) to an internal dispatch table.
 It will cause a strong reference to @a block.

 @param block The block which is invoked then the action message is
 sent  (cannot be nil). The block is retained.
 @param controlEvents A bitmask specifying the control events for which the action message is sent.
 */
- (void)btd_addActionBlock:(void (^)(__kindof UIControl *sender))block forControlEvents:(UIControlEvents)controlEvents;

/**
 Removes all blocks for a particular event (or events) from an internal
 dispatch table.
 
 @param controlEvents  A bitmask specifying the control events for which the
 action message is sent.
 */
- (void)btd_removeActionBlocksForControlEvents:(UIControlEvents)controlEvents;

@end

NS_ASSUME_NONNULL_END
