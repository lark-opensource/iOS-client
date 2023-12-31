//
//  HMDStingerBlocker.h
//  Pods
//
//  Created by fengyadong on 2021/9/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDStingerBlocker : NSObject

+ (instancetype)sharedInstance;

/// check if a method is in the hook blocklist of stinger
/// @param cls the target class
/// @param selector the target selector
/// @param isInstance whther the method is an instance method or a class method
- (BOOL)hitBlockListForCls:(Class)cls selector:(SEL)selector isInstance:(BOOL)isInstance;

@end

NS_ASSUME_NONNULL_END
