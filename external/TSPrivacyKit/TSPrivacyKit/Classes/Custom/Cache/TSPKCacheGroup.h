//
//  TSPKCacheGroup.h
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/7/6.
//

#import <Foundation/Foundation.h>

@interface TSPKCacheGroup : NSObject

@property (nonatomic, copy, nonnull) NSArray *apiList;
@property (nonatomic, copy, nonnull) NSString *strategy;
@property (nonatomic, copy, nullable) NSString *store;
@property (nonatomic, copy, nullable) NSDictionary *params;

@end
