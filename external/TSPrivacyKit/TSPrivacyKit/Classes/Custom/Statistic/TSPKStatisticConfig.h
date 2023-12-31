//
//  TSPKStatisticConfig.h
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/7/21.
//

#import <Foundation/Foundation.h>

@interface TSPKStatisticConfig : NSObject

@property(nonatomic, assign) NSInteger factTimeout;
@property(nonatomic, assign) NSInteger factQueueSize;
@property(nonatomic, copy, nullable) NSArray *factParameters;

@end
