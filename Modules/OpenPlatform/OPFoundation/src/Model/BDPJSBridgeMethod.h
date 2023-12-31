//
//  BDPJSBridgeMethod.h
//  Timor
//
//  Created by 王浩宇 on 2019/8/28.
//

#import <Foundation/Foundation.h>

/**
 JSBridge 方法(API)，用来存储「方法」及「参数」
 */
@interface BDPJSBridgeMethod : NSObject <NSCopying>

@property(nonatomic, copy, nonnull) NSString *name;          // 方法 - 方法名
@property(nonatomic, copy, nullable) NSDictionary *params;    // 方法 - 参数

- (instancetype _Nonnull)init NS_UNAVAILABLE;
+ (instancetype _Nonnull)new NS_UNAVAILABLE;

+ (instancetype _Nonnull)methodWithName:(NSString * _Nonnull)name params:(NSDictionary * _Nullable)params;

@end
