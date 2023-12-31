//
//  BDRuleExecutorResultModel.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDSingleRuleResult: NSObject
@property (nonatomic, copy, nonnull) NSDictionary *conf;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *key;
@end


@interface BDRuleResultModel : NSObject

/// engine error occurs during the validate process
@property (nonatomic, strong, nullable) NSError *engineError;

/// if match any rule, the value is the conf in rule; if no rule matched or there is an engine error, value would be nil
@property (nonatomic, strong, nullable) BDSingleRuleResult *value;

/// if the strategy execute all rules, return all rules match
@property (nonatomic, strong, nullable) NSArray<BDSingleRuleResult *> *values;

@property (nonatomic, strong, nullable) NSArray<NSString *> *ruleSetNames;

@property (nonatomic, copy, nullable) NSString *scene;

@property (nonatomic, copy, nullable) NSString *signature;

/// identifier a rule execute
@property (nonatomic, copy) NSString *uuid;

/// identifier the name of the execute
@property (nonatomic, copy) NSString *key;

/// the cost of each stage
@property (nonatomic, assign) CFTimeInterval fetchParametersCost;

@property (nonatomic, assign) CFTimeInterval sceneSelectCost;

@property (nonatomic, assign) CFTimeInterval strategySelectCost;

@property (nonatomic, assign) CFTimeInterval ruleBuildCost;

@property (nonatomic, assign) CFTimeInterval ruleExecCost;

@property (nonatomic, assign) CFTimeInterval cost;

@property (nonatomic, assign) BOOL strategySelectHitCache;

@property (nonatomic, assign) BOOL strategySelectFromGraph;

/// whether result is calculated from main thread
@property (nonatomic, assign) BOOL isMainThread;

@property (nonatomic, copy) NSDictionary *usedParameters;

+ (instancetype)instanceWithError:(NSError *)error
                             uuid:(NSString *)uuid;

- (instancetype)initWithUUID:(NSString *)uuid;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
