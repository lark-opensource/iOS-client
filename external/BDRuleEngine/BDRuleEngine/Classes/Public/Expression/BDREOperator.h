//
//  BDREOperator.h
//  BDRuleEngine
//
//  Created by WangKun on 2022/2/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDREOperator : NSObject

@property (nonatomic, strong) NSString *symbol;
@property (nonatomic, assign) int priority;
@property (nonatomic, assign) int argsLength;

/// operator's execution, recommend to use [execute:error:] interface
- (id)execute:(NSMutableArray *)params;

/// operator's execution with error
- (id)execute:(NSMutableArray *)params error:(NSError **)error;

- (NSError *)paramsInvalidateErrorWithSelectorName:(NSString *)selectorName;

@end
NS_ASSUME_NONNULL_END
