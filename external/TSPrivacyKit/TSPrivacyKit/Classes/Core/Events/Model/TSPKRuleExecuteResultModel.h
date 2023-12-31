//
//  TSPKRuleExecuteResultModel.h
//  Aweme
//
//  Created by ByteDance on 2022/9/28.
//

#import <Foundation/Foundation.h>

@interface TSPKSingleRuleExecuteResultModel : NSObject
@property (nonatomic, copy, nullable) NSString *key;
@property (nonatomic, copy, nullable) NSDictionary *config;
@end

@interface TSPKRuleExecuteResultModel : NSObject

@property (nonatomic, copy, nullable) NSDictionary *input;

@property (nonatomic, copy, nullable) NSDictionary *usedStateParams;

@property (nonatomic, copy, nullable) NSString *strategyMD5;

@property (nonatomic, copy, nullable) NSString *scene;

@property (nonatomic, copy, nullable) NSArray<NSString *> *strategies;

@property (nonatomic, copy, nullable) NSArray<TSPKSingleRuleExecuteResultModel *> *hitRules;

@property (nonatomic, assign, readonly) BOOL isCompliant;

@end
