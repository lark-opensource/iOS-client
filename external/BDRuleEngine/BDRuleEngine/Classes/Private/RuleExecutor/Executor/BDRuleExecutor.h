//
//  BDRuleExecutor.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDRuleGroupModel;
@class BDRuleResultModel;

@interface BDRuleExecutor : NSObject

- (instancetype)initWithParameters:(NSDictionary *)parameters;

/// 默认短路执行
- (BDRuleResultModel *)executeRule:(BDRuleGroupModel *)rule;

- (BDRuleResultModel *)executeRule:(BDRuleGroupModel *)rule execAllRules:(BOOL)execAllRules;

@property (nonatomic, copy, readonly) NSString *uuid;

@end

NS_ASSUME_NONNULL_END
