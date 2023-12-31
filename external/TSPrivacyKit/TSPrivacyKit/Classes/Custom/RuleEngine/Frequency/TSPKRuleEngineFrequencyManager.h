//
//  TSPKRuleEnegineFrequencyManager.h
//  Indexer
//
//  Created by admin on 2022/2/24.
//

#import <Foundation/Foundation.h>
#import "TSPKSubscriber.h"

@interface TSPKRuleEngineFrequencyManager : NSObject<TSPKSubscriber>

+ (nonnull instancetype)sharedManager;
- (BOOL)isVaildWithName:(nullable NSString *)name;

@end
