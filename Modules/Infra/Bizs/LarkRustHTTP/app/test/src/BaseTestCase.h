//
//  BaseTestCase.h
//  LarkRustHTTPDev
//
//  Created by SolaWing on 2019/7/21.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN
@interface BaseTestCase : XCTestCase
/// 白名单
+ (nullable NSArray<NSString*>*)testSelectors;

@end
NS_ASSUME_NONNULL_END
