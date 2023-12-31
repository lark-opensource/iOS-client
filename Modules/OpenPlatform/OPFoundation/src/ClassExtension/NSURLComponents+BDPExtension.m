//
//  NSURLComponents+BDPExtension.m
//  Timor
//
//  Created by tujinqiu on 2020/4/7.
//

#import "NSURLComponents+BDPExtension.h"
#import <ECOInfra/BDPUtils.h>

@implementation NSURLComponents (BDPExtension)

- (void)bdp_setQueryItemWithKey:(NSString * _Nonnull)key value:(NSString * _Nullable)value {
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
