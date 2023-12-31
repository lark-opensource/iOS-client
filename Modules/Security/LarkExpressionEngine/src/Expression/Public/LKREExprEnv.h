//
//  LKREExprEnv.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LKREExprEnv<NSObject>

- (nullable id)envValueOfKey:(NSString *)key;

// 埋点用，重置取参时间
- (void)resetCost;

- (CFTimeInterval)cost;

@end

@interface LKREExprEnv : NSObject<LKREExprEnv>

@end

NS_ASSUME_NONNULL_END
