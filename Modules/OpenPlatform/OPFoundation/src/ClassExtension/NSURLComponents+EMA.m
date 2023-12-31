//
//  NSURLComponents+EMA.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/8/1.
//

#import "NSURLComponents+EMA.h"
#import "BDPUtils.h"

@implementation NSURLComponents (EMA)

- (NSDictionary<NSString *,NSString *> *)ema_queryItems {
    NSArray<NSURLQueryItem *> *queryItems = self.queryItems;
    NSMutableDictionary *ema_queryItems = NSMutableDictionary.dictionary;
    for (NSURLQueryItem *item in queryItems) {
        if (BDPIsEmptyString(item.name) || BDPIsEmptyString(item.value)) {
            continue;
        }
        ema_queryItems[item.name] = item.value;
    }
    return ema_queryItems.copy;
}

- (void)setQueryItemWithKey:(NSString * _Nonnull)key value:(NSString * _Nullable)value {
    if (BDPIsEmptyString(key)) {
        return;
    }
    NSMutableArray *queryItems = NSMutableArray.array;
    BOOL added = NO;
    for (NSURLQueryItem * queryItem in self.queryItems) {
        if (![key isEqualToString:queryItem.name]) {
            [queryItems addObject:queryItem];
        } else {
            if (!BDPIsEmptyString(value)) {
                [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
                added = YES;
            }
        }
    }
    if (!added && !BDPIsEmptyString(value)) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
    }
    self.queryItems = queryItems.copy;
}

@end
