//
//  BDREFunc.h
//  BDRuleEngine
//
//  Created by WangKun on 2022/2/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDREFunc : NSObject

@property (nonatomic, strong) NSString *symbol;

/// function's execution, recommend to use [execute:error:] interface
- (id)execute:(NSMutableArray *)params;

/// function's execution with error
- (id)execute:(NSMutableArray *)params error:(NSError **)error;

- (NSError *)paramsInvalidateErrorWithSelectorName:(NSString *)selectorName;

@end

NS_ASSUME_NONNULL_END
