//
//  BDRuleQuickExecutor.h
//  BDRuleEngine-Core-Debug-Expression-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/8/18.
//

#import <Foundation/Foundation.h>
#import "BDRECommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDRuleQuickExecutor : NSObject

- (BOOL)evaluateWithEnv:(id<BDREExprEnv>)env error:(NSError *__autoreleasing *)error;

@end

@interface BDRuleQuickExecutorFactory : NSObject

+ (BDRuleQuickExecutor *)createExecutorWithCommands:(NSArray<BDRECommand *> *)commands cel:(NSString *)cel;

@end

NS_ASSUME_NONNULL_END
