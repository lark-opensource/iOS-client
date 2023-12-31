//
//  BDRuleParameterRegistry.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/29.
//

#import <Foundation/Foundation.h>
#import "BDRuleParameterBuilderModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDRuleParameterRegistry : NSObject

/// register state parameter
+ (void)registerParameterWithKey:(nonnull NSString *)key
                            type:(BDRuleParameterType)type
                         builder:(nonnull BDRuleParameterBuildBlock)builder;

/// register constant parameter
+ (void)registerConstParameterWithKey:(nonnull NSString *)key
                                 type:(BDRuleParameterType)type
                              builder:(nonnull BDRuleParameterBuildBlock)builder;

+ (BDRuleParameterBuilderModel *)builderForKey:(NSString *)key;

+ (NSArray<BDRuleParameterBuilderModel *> *)allParameters;

+ (NSArray<BDRuleParameterBuilderModel *> *)stateParameters;

+ (NSArray<BDRuleParameterBuilderModel *> *)constParameters;

@end

NS_ASSUME_NONNULL_END
