//
//  TSPKRuleEngine.h
//  Indexer
//
//  Created by admin on 2022/2/13.
//

#import <Foundation/Foundation.h>
#import "TSPKHandleResult.h"
#import "TSPKEventData.h"
#import "TSPKSubscriber.h"

typedef NSDictionary*_Nullable (^TSPKRuleEngineExtraParameterBuilder)(void);

@interface TSPKRuleEngineManager : NSObject

+ (nonnull instancetype)sharedEngine;

- (void)setExtraParams:(TSPKRuleEngineExtraParameterBuilder _Nullable)block;
- (void)registerDefaultFunc;

@end
