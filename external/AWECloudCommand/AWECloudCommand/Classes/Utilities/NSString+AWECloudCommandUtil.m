//
//  NSString+AWECloudCommandUtil.m
//  AWECloudCommand
//
//  Created by wangdi on 2018/4/24.
//

#import "NSString+AWECloudCommandUtil.h"

@implementation NSString (AWECloudCommandUtil)

- (NSString *)awe_urlStringByAddingComponentString:(NSString *)componentString
{
    NSArray *array = nil;
    if (componentString && [componentString length] > 0) {
        array = @[componentString];
    }
    return [self awe_urlStringByAddingComponentArray:array];
}

- (NSString *)awe_urlStringByAddingComponentArray:(NSArray<NSString *> *)componentArray
{
    // trim
    NSMutableCharacterSet *trimCharacterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"/?&"];
    [trimCharacterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *trimedString = [self stringByTrimmingCharactersInSet:trimCharacterSet];
    if (!trimedString || [trimedString length] == 0) {
        return nil;
    }
    
    if (!componentArray || componentArray.count == 0) {
        return trimedString;
    }
    // 组合？、&
    NSString *componentString = [componentArray componentsJoinedByString:@"&"];
    if ([trimedString rangeOfString:@"?"].location == NSNotFound) {
        return [trimedString stringByAppendingFormat:@"/?%@", componentString];
    } else {
        return [trimedString stringByAppendingFormat:@"&%@", componentString];
    }
}

+ (NSString *)awe_queryStringWithParamDictionary:(NSDictionary *)param
{
    NSMutableString *paramStr = [NSMutableString string];
    [param enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [paramStr appendFormat:@"%@=%@&", key, obj];
    }];
    if (paramStr.length > 0) {
        [paramStr substringFromIndex:paramStr.length - 1];
    }
    return paramStr;
}

- (NSString *)cloudcommand_base64Decode {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self options:0];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}
@end

