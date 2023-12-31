//
//  NSObject+HMDPerformSelector.h
//  Heimdallr
//
//  Created by joy on 2018/7/30.
//

#import <Foundation/Foundation.h>

@interface NSObject (HMDPerformSelector)

- (BOOL)hmd_checkHookConflictAndInvokeSelector:(SEL _Nonnull )aSelector withArguments:(nullable NSArray *)arguments;
- (BOOL)hmd_checkHookConflictAndInvokeSelector:(SEL _Nonnull )aSelector withArguments:(nullable NSArray *)arguments result:(nullable void *)res;
@end
