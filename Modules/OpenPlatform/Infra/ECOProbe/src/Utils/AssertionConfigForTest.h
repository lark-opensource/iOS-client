//
//  AssertionConfigForTest.h
//  ECOProbe
//
//  Created by baojianjun on 2022/12/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 在单测环境下使用，需要在tearDown reset, 避免其他用例被影响
/// 解决mock网络请求时中assert
@interface AssertionConfigForTest : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (BOOL)isEnable;
+ (void)reset;
+ (void)disableAssertWhenTesting;
+ (BOOL)isTesting;

@end

NS_ASSUME_NONNULL_END
