//
//  TSPKCacheEnv.h
//  T-Develop
//
//  Created by admin on 2022/6/29.
//

#import <Foundation/Foundation.h>
@class TSPKCacheProcessor;

@interface TSPKCacheEnv : NSObject

+ (nonnull instancetype)shareEnv;
- (void)registerProcessor:(nullable TSPKCacheProcessor *)processor key:(nullable NSString *)key;
- (void)unregisterProcessor:(nullable NSString *)key;
- (BOOL)containsProcessor:(nullable NSString *)key;

- (BOOL)needUpdate:(nullable NSString *)key;
- (nullable id)get:(nullable NSString *)key;
- (void)updateCache:(nullable NSString *)key newValue:(nullable id)value;

@end
