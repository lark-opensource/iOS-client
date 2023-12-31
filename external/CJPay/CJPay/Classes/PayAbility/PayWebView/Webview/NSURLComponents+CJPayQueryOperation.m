//
//  NSURLComponents+CJPayQueryOperation.m
//  CJPay
//
//  Created by liyu on 2020/6/1.
//

#import "NSURLComponents+CJPayQueryOperation.h"

@implementation NSURLComponents (CJPayQueryOperation)

- (void)cjpay_setQueryValue:(NSString *)value ifNotExistKey:(NSString *)key
{
    if ([key length] == 0 || [value length] == 0) {
        return;
    }
    
    BOOL keyExists = [self.queryItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURLQueryItem * _Nullable queryItem, NSDictionary<NSString *,id> * _Nullable bindings) {
           return [queryItem.name isEqualToString:key];
    }]];
    if (keyExists) {
        return;
    }
    
    NSMutableArray *newQueryItems = [NSMutableArray arrayWithArray:self.queryItems];
    [newQueryItems addObject:[NSURLQueryItem queryItemWithName:key
                                                         value:value]];
    self.queryItems = [newQueryItems copy];
}

- (void)cjpay_overrideQueryByDict:(NSDictionary *)dict
{
    if ([dict count] == 0) {
        return;
    }
    
    if ([self.queryItems count] == 0) {
        NSMutableArray *queries = [[NSMutableArray alloc] init];
        [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            [queries addObject:[NSURLQueryItem queryItemWithName:key value:value]];
        }];
        self.queryItems = [queries copy];
        return;
    }
    
    NSMutableArray *newQueryItems = [NSMutableArray arrayWithArray:self.queryItems];
    NSMutableDictionary *queryMap = [NSMutableDictionary dictionary];
    [newQueryItems enumerateObjectsUsingBlock:^(NSURLQueryItem *  _Nonnull query, NSUInteger idx, BOOL * _Nonnull stop) {
        queryMap[query.name] = query;
    }];
    
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSString *  _Nonnull value, BOOL * _Nonnull stop) {
        queryMap[key] = [NSURLQueryItem queryItemWithName:key value:value];
    }];

    self.queryItems = [queryMap.allValues copy];
}

@end
