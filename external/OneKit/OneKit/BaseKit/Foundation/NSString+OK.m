//
//  NSString+OK.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "NSString+OK.h"
#import "NSData+OK.h"
#import "NSDictionary+OK.h"

#import <CommonCrypto/CommonDigest.h>


@implementation NSString (OK)

- (NSString *)ok_trimmed {
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    return [self stringByTrimmingCharactersInSet:set];
}

- (NSString *)ok_md5String {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] ok_md5String];
}

- (NSString *)ok_sha256String {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] ok_sha256String];
}

- (NSString *)ok_base64EncodedString {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length > 0) {
        return [data base64EncodedStringWithOptions:0];
    }
    
    return nil;
}

- (NSString *)ok_base64DecodedString {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self options:0];
    if (data.length > 0) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (id)ok_jsonValueDecoded {
    NSError *error = nil;
    return [self ok_jsonValueDecoded:&error];
}

- (id)ok_jsonValueDecoded:(NSError *__autoreleasing *)error {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data ok_jsonValueDecoded:error];
}

+ (NSString *)ok_UUIDString {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef fullStr = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    
    return (__bridge_transfer NSString *)fullStr;
}

- (NSString *)ok_stringByAppendingQueryDictionary:(NSDictionary *)params {
    NSString *query = [params ok_queryString];
    if (query.length > 0) {
        if ([self containsString:@"?"]) {
            return [self stringByAppendingFormat:@"&%@",query];
        } else {
            return [self stringByAppendingFormat:@"?%@",query];
        }
    }
    
    return self;
}

- (NSDictionary *)ok_queryDictionary {
    if (self.length < 1) {
        return @{};
    }
    
    NSMutableDictionary * result = [NSMutableDictionary new];
    NSArray<NSString *> *items = [self componentsSeparatedByString:@"&"];
    
    for (NSString *item in items) {
        NSArray *pairComponents = [item componentsSeparatedByString:@"="];
        NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        [result setValue:value forKey:key];
    }

    return result;
}

- (id)ok_safeJsonObject {
    return [self copy];
}

- (NSString *)ok_safeJsonObjectKey {
    return [self copy];
}

@end
