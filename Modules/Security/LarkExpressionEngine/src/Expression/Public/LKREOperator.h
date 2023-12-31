//
//  LKREOperator.h
//  LKRuleEngine
//
//  Created by WangKun on 2022/2/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LKREOperator : NSObject

@property (nonatomic, strong) NSString *symbol;
@property (nonatomic, assign) int priority;
@property (nonatomic, assign) int argsLength;

- (id)execute:(NSMutableArray *)params error:(NSError **)error;

@end
NS_ASSUME_NONNULL_END
