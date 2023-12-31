//
//  BDREOperator.m
//  BDRuleEngine
//
//  Created by WangKun on 2022/2/15.
//

#import "BDREOperator.h"
#import "BDREExprConst.h"

@implementation BDREOperator

- (id)execute:(NSMutableArray *)params
{
    return nil;
}

- (id)execute:(NSMutableArray *)params error:(NSError *__autoreleasing  _Nullable *)error
{
    // Adapt to old version
    return [self execute:params];
}

- (NSError *)paramsInvalidateErrorWithSelectorName:(NSString *)selectorName
{
    return [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRINVALID_PARAMS userInfo:@{
        NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ | params invalid of %@ operator", selectorName, self.symbol] ?: @""
    }];
}

@end
