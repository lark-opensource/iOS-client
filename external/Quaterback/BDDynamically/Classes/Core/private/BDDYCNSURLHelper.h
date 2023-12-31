//
//  BDDYCNSURLHelper.h
//  BDDynamically
//
//  Created by zuopengliu on 22/6/2018.
//

#ifndef BDDYCNSURLHelper_h
#define BDDYCNSURLHelper_h

#import <Foundation/Foundation.h>


#pragma mark - URL encode/decode

__unused
static NSString *BDDYCURLEncodeString(NSString *string)
{
    if (!string) return nil;
    __autoreleasing NSString *encodedString;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    encodedString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                          NULL,
                                                                                          (__bridge CFStringRef)string,
                                                                                          NULL,
                                                                                          (CFStringRef)@":!*();@/&?#[]+$,='%’\"",
                                                                                          kCFStringEncodingUTF8
                                                                                          );
#pragma clang diagnostic pop
    return encodedString;
}

__unused
static NSString *BDDYCURLDecodeString(NSString *string)
{
    if (!string) return nil;
    __autoreleasing NSString *decodedString;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    decodedString = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                                                          NULL,
                                                                                                          (__bridge CFStringRef)string,
                                                                                                          CFSTR(""),
                                                                                                          kCFStringEncodingUTF8
                                                                                                          );
#pragma clang diagnostic pop
    return decodedString;
}


#pragma mark - string

__unused
static id BDDYCDeserializationString(NSString *value, BOOL *valid)
{
    if (!value || ![value isKindOfClass:[NSString class]]) return nil;
    
    id deserializationObject = nil;
    @try {
        if (valid) *valid = YES;
        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            NSError *error;
            deserializationObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) if (valid) *valid = NO;
        } else {
            if (valid) *valid = NO;
        }
    } @catch (NSException *exception) {
        if (valid) *valid = NO;
    } @finally {
    }
    return deserializationObject;
}


#pragma mark - URL query parameters

__unused
static NSString *BDDYCURLAppendQueryParameters(NSString *url, NSDictionary *queryItems)
{
    NSMutableString *queryString = [NSMutableString stringWithCapacity:10];
    __block NSString *separator = @"";
    [queryItems enumerateKeysAndObjectsUsingBlock:^(id key, id  _Nonnull value, BOOL *stop) {
        [queryString appendFormat:@"%@%@=%@", separator, BDDYCURLEncodeString([key description]), BDDYCURLEncodeString([value description])];
        separator = @"&";
    }];
    
    NSMutableString *targetURLString = [[url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] mutableCopy];
    if ([queryString length] > 0) {
        if ([targetURLString rangeOfString:@"?"].location == NSNotFound) {
            [targetURLString appendString:@"?"];
        } else if (![targetURLString hasSuffix:@"?"] && ![targetURLString hasSuffix:@"&"]) {
            [targetURLString appendString:@"&"];
        }
        [targetURLString appendString:queryString];
    }
    return targetURLString;
}

__unused
static NSDictionary *BDDYCParseQueryParametersFromURL(NSURL *url)
{
    if (!url) return nil;
    
    NSMutableDictionary *queryDict = [NSMutableDictionary dictionary];
    NSString *queryString  = url.query ? : url.parameterString;
    NSArray *keyValuePairs = [queryString componentsSeparatedByString:@"&"];
    
    for (NSString *keyValuePair in keyValuePairs) {
        NSArray *element = [keyValuePair componentsSeparatedByString:@"="];
        if (element.count != 2) continue;
        
        NSString *key   = BDDYCURLDecodeString(element[0]);
        NSString *value = BDDYCURLDecodeString(element[1]);
        
        id valueObject = nil;
        if ([value isKindOfClass:[NSString class]]) {
            BOOL valid = YES;
            id newValue = BDDYCDeserializationString(value, &valid);
            if (valid) valueObject = newValue;
        } else {
            valueObject = nil;
        }
        
        if (key.length == 0) continue;
        
        [queryDict setValue:(valueObject ? : value) forKey:key];
    }
    
    return [queryDict copy];
}


#endif /* BDDYCNSURLHelper_h */
