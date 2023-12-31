//
//  TSPKCacheStore.h
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/28.
//

#import <Foundation/Foundation.h>

@protocol TSPKCacheStore <NSObject>

- (void)put:(nullable NSString *)key value:(nullable id)value;
- (nullable id)get:(nullable NSString *)key;
- (BOOL)containsKey:(nullable NSString *)key;

@end
