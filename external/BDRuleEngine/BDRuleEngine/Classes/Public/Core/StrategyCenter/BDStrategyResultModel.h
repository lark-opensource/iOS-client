//
//  BDStrategyResultModel.h
//  BDRuleEngine
//
//  Created by Chengmin Zhang on 2022/3/29.
//

#import <Foundation/Foundation.h>

#import "BDRuleResultModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDStrategyResultModel : NSObject

/// if the strategy select execute successfully, return all strategies match
@property (nonatomic, strong, nullable, readonly) NSArray<NSString *> *strategyNames;

@property (nonatomic, strong, nullable, readonly) BDRuleResultModel *ruleResult;

@property (nonatomic, strong, nullable, readonly) NSError *engineError;

/// identifier a rule execute
@property (nonatomic, copy, nullable, readonly) NSString *uuid;

/// identifier the name of the execute
@property (nonatomic, copy, nullable, readonly) NSString *key;

@property (nonatomic, assign, readonly) BOOL hitCache;

@property (nonatomic, assign, readonly) BOOL fromGraph;

@property (nonatomic, assign, readonly) CFTimeInterval cost;

- (instancetype)initWithStrategyNames:(NSArray *)names
                           ruleResult:(BDRuleResultModel *)ruleResult
                             hitCache:(BOOL)hitCache
                            fromGraph:(BOOL)fromGraph
                                 cost:(CFTimeInterval)cost;

- (instancetype)initWithErrorRuleResultModel:(BDRuleResultModel *)model;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
