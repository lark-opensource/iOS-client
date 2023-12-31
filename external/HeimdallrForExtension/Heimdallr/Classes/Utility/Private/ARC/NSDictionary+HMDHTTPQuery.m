//
//  NSDictionary+HMDHTTPQuery.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/12.
//

#import "NSDictionary+HMDHTTPQuery.h"

@implementation NSDictionary (HMDHTTPQuery)
- (NSString *)hmd_queryString
{
    NSMutableArray *keyValuePairs = [NSMutableArray array];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        //避免一些嵌套结构拼接到query里
        if(![obj isKindOfClass:[NSDictionary class]]) {
            NSString *value = [[obj description] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [keyValuePairs addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
        } else {
            
        }
    }];
    return [keyValuePairs componentsJoinedByString:@"&"];
}

- (id)hmd_objectForInsensitiveKey:(NSString *)key {
    __block id object = nil;
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull objKey, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([objKey isKindOfClass:NSString.class]) {
            if ([key caseInsensitiveCompare:objKey] == NSOrderedSame) {
                object = obj;
                *stop = YES;
            }
        }
    }];
    
    return object;
}
@end
