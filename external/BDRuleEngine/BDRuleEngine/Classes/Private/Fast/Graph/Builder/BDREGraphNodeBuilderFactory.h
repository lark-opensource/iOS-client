//
//  BDREGraphNodeBuilderFactory.h
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/17.
//

#import <Foundation/Foundation.h>

#import "BDREGraphNodeBuilder.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREGraphNodeBuilderFactory : NSObject

+ (nullable BDREGraphNodeBuilder *)builderWithOpName:(NSString *)name;

+ (nullable BDREGraphNodeBuilder *)builderWithFuncName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
