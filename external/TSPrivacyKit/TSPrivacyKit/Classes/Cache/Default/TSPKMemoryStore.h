//
//  TSPKMemoryStore.h
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/29.
//

#import <Foundation/Foundation.h>
#import "TSPKCacheStore.h"

@interface TSPKMemoryStore : NSObject<TSPKCacheStore>

+ (nonnull instancetype)sharedStore;

@end
