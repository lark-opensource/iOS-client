//
//  BDMappingStrategy.m
//  BDModel
//
//  Created by 马钰峰 on 2019/3/28.
//

#import "BDMappingStrategy.h"

@implementation BDMappingStrategy

+ (NSDictionary *)mapJSONKeyWithDictionary:(NSDictionary *)dic options:(BDModelMappingOptions)options
{
    if (!dic) {
        return dic;
    }
    
    if (BDModelMappingOptionsNone == options) {
        return dic;
    }
    
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        id nestedObj = obj;
        if ([nestedObj isKindOfClass:[NSDictionary class]]) {
            nestedObj = [self mapJSONKeyWithDictionary:nestedObj options:options];
        } else if ([nestedObj isKindOfClass:[NSArray class]]) {
            nestedObj = [self mapJSONKeyWithArray:nestedObj options:options];
        }
        
        if (options & BDModelMappingOptionsSnakeCaseToCamelCase) {
            id modifyKey = [self mapSnakeCaseToCamel:key];
            if (modifyKey) {
                res[modifyKey] = nestedObj;
            } else {
                res[key] = nestedObj;
            }
        } else if (options & BDModelMappingOptionsCamelCaseToSnakeCase) {
            id modifyKey = [self mapCamelToSnakeCase:key];
            if (modifyKey) {
                res[modifyKey] = nestedObj;
            } else {
                res[key] = nestedObj;
            }
        } else {
            res[key] = nestedObj;
        }
    }];
    
    return [res copy];
}

+ (NSArray *)mapJSONKeyWithArray:(NSArray *)arr options:(BDModelMappingOptions)options
{
    if (!arr) {
        return arr;
    }
    
    if (BDModelMappingOptionsNone == options) {
        return arr;
    }
    
    NSMutableArray *res = [NSMutableArray array];
    [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id nestedObj = obj;
        if ([nestedObj isKindOfClass:[NSDictionary class]]) {
            nestedObj = [self mapJSONKeyWithDictionary:nestedObj options:options];
        } else if ([nestedObj isKindOfClass:[NSArray class]]) {
            nestedObj = [self mapJSONKeyWithArray:nestedObj options:options];
        }
        
        [res addObject:nestedObj];
    }];
    
    return [res copy];
}

+ (NSString *)mapCamelToSnakeCase:(NSString *)keyName
{
    if (keyName.length <= 0) {
        return keyName;
    }
    
    NSMutableString *result = [NSMutableString stringWithString:keyName];
    NSRange range;
    
    // handle upper case chars
    range = [result rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]];
    while (range.location != NSNotFound)
    {
        NSString *lower = [result substringWithRange:range].lowercaseString;
        [result replaceCharactersInRange:range withString:[NSString stringWithFormat:@"_%@", lower]];
        range = [result rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]];
    }
    
    return [result copy];
}

+ (NSString *)mapSnakeCaseToCamel:(NSString *)keyName
{
    if (keyName.length <= 0) {
        return keyName;
    }
    
    NSMutableString *result = [NSMutableString stringWithString:keyName];
    NSRange range;
    
    while ([result hasSuffix:@"_"]) {
        [result deleteCharactersInRange:NSMakeRange(result.length - 1, 1)];
    }
    
    while ([result hasPrefix:@"_"]) {
        [result deleteCharactersInRange:NSMakeRange(0, 1)];
    }
    
    // handle snake case chars
    range = [result rangeOfString:@"_" options:NSLiteralSearch];
    while (range.location != NSNotFound)
    {
        NSRange replaceRange = NSMakeRange(range.location + range.length, 1);
        NSString *upper = [result substringWithRange:replaceRange].uppercaseString;
        [result replaceCharactersInRange:replaceRange withString:upper];
        [result deleteCharactersInRange:range];
        range = [result rangeOfString:@"_" options:NSLiteralSearch];
    }
    return [result copy];
}

@end
