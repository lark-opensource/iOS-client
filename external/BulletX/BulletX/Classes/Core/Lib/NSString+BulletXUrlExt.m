//
//  NSString+BulletUrlCode.m
//  AAWELaunchOptimization
//
//  Created by duanefaith on 2019/10/11.
//

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import "NSString+BulletXUrlExt.h"

NSString *const BulletXParameterURLKey = @"BulletXParameterURLKey";
NSString *const BulletXParameterUserInfoKey = @"BulletXParameterUserInfoKey";

static NSString *const BulletSchemaInfoKey = @"BulletSchemaInfoKey";

@implementation NSString (BulletXUrlExt)

- (NSString *)bullet_urlEncode
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, (CFStringRef) @"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));
}

- (NSString *)bullet_urlDecode
{
    return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)self, CFSTR(""), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
}

- (nullable NSString *)bullet_scheme
{
    NSArray<NSString *> *urlComponents = [self componentsSeparatedByString:@"://"];

    if (BTD_isEmptyArray(urlComponents) || BTD_isEmptyString(urlComponents.firstObject)) {
        return nil;
    }

    return urlComponents.firstObject;
}

- (nullable NSString *)bullet_path
{
    NSArray<NSString *> *urlComponents = [self componentsSeparatedByString:@"://"];
    if (!urlComponents || urlComponents.count < 2 || BTD_isEmptyString(urlComponents[1])) {
        return nil;
    }

    urlComponents = [urlComponents[1] componentsSeparatedByString:@"?"];
    return urlComponents[0];
}

- (nullable NSString *)bullet_queryString
{
    NSArray<NSString *> *urlComponents = [self componentsSeparatedByString:@"?"];
    if (!urlComponents || urlComponents.count < 2 || BTD_isEmptyString(urlComponents[1])) {
        return nil;
    }

    return urlComponents[1];
}

- (nullable NSArray<NSString *> *)bullet_pathComponentArray
{
    NSString *path = [self bullet_path];
    if ([path hasSuffix:@"/"]) {
        path = [path substringToIndex:([path length] - 1)];
    }

    if (BTD_isEmptyString(path)) {
        return nil;
    }

    NSMutableArray<NSString *> *resultPathComponentArray = [NSMutableArray new];
    NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
    for (NSString *pathItem in pathComponents) {
        [resultPathComponentArray btd_addObject:pathItem];
    }

    return resultPathComponentArray;
}

- (nullable NSDictionary<NSString *, NSString *> *)bullet_queryDictWithEscapes:(BOOL)escapes
{
    NSString *queryString = [self bullet_queryString];

    NSMutableDictionary<NSString *, NSString *> *queryDict = [NSMutableDictionary new];
    NSArray<NSString *> *queryArray = [queryString componentsSeparatedByString:@"&"];
    for (NSString *queryItem in queryArray) {
        NSArray<NSString *> *pair = [queryItem componentsSeparatedByString:@"="];
        if (!pair || pair.count < 2 || BTD_isEmptyString(pair[0]) || BTD_isEmptyString(pair[1])) {
            NSRange range = [queryItem rangeOfString:@"=" options:NSLiteralSearch];
            if (range.location != NSNotFound) {
                NSString *keyString = [queryItem substringToIndex:range.location];
                NSString *valueString = [queryItem substringFromIndex:(range.location + range.length)];
                if (!BTD_isEmptyString(keyString) && !BTD_isEmptyString(valueString)) {
                    pair = @[keyString, valueString];
                } else {
                    continue;
                }
            } else {
                continue;
            }
        }

        NSString *keyString = nil, *valueString = nil;
        if (escapes) {
            keyString = [pair[0] bullet_stringByReplacingPercentEscapes];
            valueString = [pair[1] bullet_stringByReplacingPercentEscapes];
        } else {
            keyString = pair[0];
            valueString = pair[1];
        }
        if (!BTD_isEmptyString(keyString) && !BTD_isEmptyString(valueString)) {
            [queryDict btd_setObject:valueString forKey:keyString];
        }
    }

    if (queryDict.count == 0) {
        queryDict = nil;
    }

    return queryDict;
}

- (NSString *)bullet_stringByReplacingPercentEscapes
{
    return [self stringByRemovingPercentEncoding];
}

+ (nullable NSMutableDictionary *)bullet_parseParamsForURL:(NSString *)urlString
{
    NSString *scheme = [urlString bullet_scheme];
    if (BTD_isEmptyString(scheme)) {
        return nil;
    }

    __block NSDictionary *subRoutes = [NSMutableDictionary dictionaryWithObject:[NSMutableDictionary new] forKey:scheme];
    __block NSMutableDictionary *paramDict = [NSMutableDictionary new];
    [paramDict btd_setObject:urlString forKey:BulletXParameterURLKey];
    [paramDict btd_setObject:[NSMutableDictionary new] forKey:BulletXParameterUserInfoKey];

    NSArray<NSString *> *pathComponents = [urlString bullet_pathComponentArray];
    for (NSString *pathItem in pathComponents) {
        __block BOOL found = NO;
        if ([subRoutes objectForKey:pathItem]) {
            found = YES;
            subRoutes = [subRoutes btd_dictionaryValueForKey:pathItem];
        } else {
            [subRoutes.allKeys enumerateObjectsUsingBlock:^(NSString *_Nonnull key, NSUInteger idx, BOOL *_Nonnull stop) {
                if ([key hasPrefix:@":"]) {
                    found = YES;
                    subRoutes = [subRoutes btd_dictionaryValueForKey:key];
                    // 参数解析
                    NSString *paramKey = [key substringFromIndex:1];
                    NSString *paramValue = [pathItem bullet_stringByReplacingPercentEscapes];
                    if (!BTD_isEmptyString(paramKey) && !BTD_isEmptyString(paramValue)) {
                        NSMutableDictionary *userInfoDict = (NSMutableDictionary *)[paramDict btd_dictionaryValueForKey:BulletXParameterUserInfoKey];
                        [userInfoDict btd_setObject:paramValue forKey:paramKey];
                    }

                    *stop = YES;
                }
            }];
        }

        if (!found) {
            return nil;
        }
    }

    if ([subRoutes objectForKey:BulletSchemaInfoKey]) {
        paramDict[BulletSchemaInfoKey] = subRoutes[BulletSchemaInfoKey];
    }
    NSMutableDictionary *userInfoDict = (NSMutableDictionary *)[paramDict btd_dictionaryValueForKey:BulletXParameterUserInfoKey];
    ;
    [userInfoDict addEntriesFromDictionary:[urlString bullet_queryDictWithEscapes:YES]];

    return paramDict;
}

- (NSString *)bullet_stringByAddingQueryDict:(NSDictionary<NSString *, NSString *> *)dict
{
    if (BTD_isEmptyDictionary(dict)) {
        return self;
    }

    NSMutableArray<NSString *> *params = [NSMutableArray array];
    [dict enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        if ([key isKindOfClass:NSString.class]) {
            NSString *stringValue = nil;
            if ([obj isKindOfClass:NSString.class]) {
                stringValue = obj;
            } else if ([obj isKindOfClass:NSNumber.class]) {
                stringValue = [(NSNumber *)obj stringValue];
            }
            if (stringValue) {
                [params btd_addObject:[NSString stringWithFormat:@"%@=%@", [(NSString *)key bullet_stringByAddingPercentEscapes], [stringValue bullet_stringByAddingPercentEscapes]]];
            }
        }
    }];

    NSString *paramString = [params componentsJoinedByString:@"&"];
    if ([self containsString:@"?"]) {
        return [NSString stringWithFormat:@"%@&%@", self, paramString];
    }

    return [NSString stringWithFormat:@"%@?%@", self, paramString];
}

- (NSString *)bullet_stringByReplacingScheme:(NSString *)scheme
{
    if (BTD_isEmptyString(scheme)) {
        return self;
    }

    NSArray<NSString *> *urlComponents = [self componentsSeparatedByString:@"://"];
    if (!urlComponents || urlComponents.count < 2 || BTD_isEmptyString(urlComponents[0]) || BTD_isEmptyString(urlComponents[1])) {
        return self;
    }

    return [NSString stringWithFormat:@"%@://%@", scheme, urlComponents[1]];
}

- (NSString *)bullet_stringByAddingPercentEscapes
{
    static NSMutableCharacterSet *allowSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allowSet = [NSMutableCharacterSet characterSetWithCharactersInString:@""];
        [allowSet formUnionWithCharacterSet:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [allowSet removeCharactersInString:@":!*();@/&?+$,='"];
    });

    return [self stringByAddingPercentEncodingWithAllowedCharacters:allowSet];
}

- (NSString *)bullet_stringByStrippingSandboxPath
{
    NSString *sandboxPath = NSHomeDirectory();
    NSRange range = [self rangeOfString:sandboxPath];
    if (range.location != NSNotFound) {
        NSUInteger index = range.location + range.length;
        if (index < self.length) {
            NSString *path = [self substringFromIndex:index];
            return [path hasPrefix:@"/"] ? path : [@"/" stringByAppendingString:path];
        }
    }
    return self;
}

- (NSString *)bullet_stringByAppendingSandboxPath
{
    NSString *sandboxPath = NSHomeDirectory();
    NSRange range = [self rangeOfString:sandboxPath];
    if (range.location == NSNotFound) {
        return [sandboxPath stringByAppendingPathComponent:self];
    }
    return self;
}

@end
