//
//  PNSRuleEngineProtocol.h
//  Musically
//
//  Created by ByteDance on 2022/9/27.
//

#import <Foundation/Foundation.h>

#pragma mark - StrategyCenter

typedef NS_ENUM(NSUInteger, PNSRuleParameterType) {
    PNSRuleParameterTypeNumberOrBool = 1,
    PNSRuleParameterTypeString = 2,
    PNSRuleParameterTypeArray = 3,
    PNSRuleParameterTypeDictionary = 4,
    PNSRuleParameterTypeUnknown = 999
};

typedef NS_ENUM(NSUInteger, PNSRuleParameterOrigin) {
    PNSRuleParameterOriginState = 1,
    PNSRuleParameterOriginConst = 2,
    PNSRuleParameterOriginInput = 3
};

typedef id _Nonnull (^PNSRuleParameterBuildBlock)(void);

@protocol PNSRuleParameterBuilderModelProtocol <NSObject>

@property (nonatomic, copy, nullable) NSString *key;
@property (nonatomic, assign) PNSRuleParameterOrigin origin;
@property (nonatomic, assign) PNSRuleParameterType type;
@property (nonatomic, copy, nullable) PNSRuleParameterBuildBlock builder;

@end

@protocol PNSREFunc <NSObject>

- (nonnull NSString *)symbol;
- (nullable id)execute:(nullable NSMutableArray *)params;

@end

@protocol PNSSingleRuleResultProtocol <NSObject>

@property (nonatomic, copy, nonnull) NSDictionary *conf;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *key;

@end

@protocol PNSRuleResultProtocol <NSObject>

@property (nonatomic, copy, nullable) NSString *signature;
@property (nonatomic, copy, nullable) NSString *scene;
@property (nonatomic, copy, nullable) NSArray<NSString *> *ruleSetNames;
@property (nonatomic, copy, nullable) NSArray<id <PNSSingleRuleResultProtocol>> *values;
@property (nonatomic, copy, nullable) NSDictionary *usedParameters;

@end


@protocol PNSRuleEngineProtocol <NSObject>

- (nullable id<PNSRuleResultProtocol>)validateParams:(nullable NSDictionary *)params;
- (nullable NSDictionary *)contextInfo;
- (void)registerFunc:(nonnull id <PNSREFunc>)func;

@end
