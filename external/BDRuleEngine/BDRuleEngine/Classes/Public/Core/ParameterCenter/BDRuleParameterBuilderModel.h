//
//  BDRuleParameterBuilderModel.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/21.
//

#import <Foundation/Foundation.h>
#import "BDRuleParameterDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDRuleParameterBuilderModel : NSObject
@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) BDRuleParameterOrigin origin;
@property (nonatomic, assign) BDRuleParameterType type;
@property (nonatomic, copy) BDRuleParameterBuildBlock builder;
@end

NS_ASSUME_NONNULL_END
