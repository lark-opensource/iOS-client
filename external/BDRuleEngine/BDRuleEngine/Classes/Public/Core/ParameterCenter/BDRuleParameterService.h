//
//  BDRuleParameterService.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/9.
//

#import <Foundation/Foundation.h>
#import "BDRuleParameterDefine.h"
#import "BDRuleParameterBuilderModel.h"

@interface BDRuleParameterService : NSObject

+ (void)registerParameterWithKey:(nonnull NSString *)key
                            type:(BDRuleParameterType)type
                         builder:(nonnull BDRuleParameterBuildBlock)builder;

+ (nonnull NSArray<BDRuleParameterBuilderModel *> *)stateParameters;

@end

