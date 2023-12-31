//
//  TSPKCacheStoreFactory.h
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/7/8.
//

#import <Foundation/Foundation.h>
#import "TSPKCacheStore.h"

@interface TSPKCacheStoreFactory : NSObject

+ (nullable id<TSPKCacheStore>)getStore:(nullable NSString *)name;

@end
