//
//  BDStrategyCenter.h
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2021/12/10.
//

#import <Foundation/Foundation.h>

#import "BDRuleResultModel.h"
#import "BDStrategyResultModel.h"

@protocol BDStrategyProvider;
@protocol BDRuleEngineDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface BDStrategyCenter : NSObject

/// register strategy provider
/// @param provider strategy provider can provider strategy to rule engine
+ (void)registerStrategyProvider:(id<BDStrategyProvider>)provider;

/// call this function after register all providers;
/// @param delegate support service functions callback
+ (void)setupWithDelegate:(nullable id<BDRuleEngineDelegate>)delegate;

/// validate if params can pass rule engine validate
/// @param params input params for validation
+ (BDRuleResultModel *)validateParams:(NSDictionary *)params;

/// validate if params can pass rule engine validate
/// @param params input params for validation
/// @param source the specified set name
+ (BDRuleResultModel *)validateParams:(NSDictionary *)params source:(NSString *)source;

/// validate if params can pass rule engine validate
/// @param params input params for validation
/// @param source the specified set name
/// @param strategyNames the specified strategy names
+ (BDRuleResultModel *)validateParams:(NSDictionary *)params source:(NSString *)source strategyNames:(NSArray *)strategyNames;

/// perform strategies select according to source and params
/// @param source the specified set name
/// @param params input params for validation
+ (BDStrategyResultModel *)generateStrategiesInSource:(NSString *)source params:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
