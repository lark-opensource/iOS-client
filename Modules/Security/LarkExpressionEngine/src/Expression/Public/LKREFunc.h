//
//  LKREFunc.h
//  LKRuleEngine
//
//  Created by WangKun on 2022/2/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LKREFunc : NSObject

@property (nonatomic, strong) NSString *symbol;
//NSIntegerMax 代表不固定参数
@property (nonatomic, assign) NSInteger argsLength;

- (id)execute:(NSMutableArray *)params error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
