//
//  SSCommon+JSON.m
//  Article
//
//  Created by SunJiangting on 14-6-16.
//
//

#import <ECOInfra/JSONValue+BDPExtension.h>
#import "BDPJSONKit.h"
#import "NSDictionary+BDPExtension.h"
#import "EMAFeatureGating.h"
#import "BDPLog.h"

@implementation NSString (JSONValue)

- (id)JSONValue
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
        NSError *error = nil;
        id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        if (error && self.length > 0) {
            BOOL shouldSkipJsonDecoder = [EMAFeatureGating boolValueForKey:@"openplatform.infra.ignorejsondecoder.enable" defaultValue:false];
            BDPLogInfo(@"shouldSkipJsonDecoder:%@,error:%@,string:%@",@(shouldSkipJsonDecoder),error.description,self);
            if (shouldSkipJsonDecoder){
                object = nil;
            }else{
                error = nil;
                object = [[BDPJSONDecoder decoderWithParseOptions:BDPParseOptionLooseUnicode] objectWithData:data error:&error];
            }
        }
        return object;
    }
    return nil;
}

- (NSDictionary * _Nullable)JSONDictionary {
    NSDictionary *result = [self JSONValue];
    if (![result isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    return result;
}

-(NSDictionary * _Nullable)stringToDic{
    NSDictionary *dict = nil;
    id paramDict = [self JSONValue];
    if ([paramDict isKindOfClass:[NSString class]]) {
        dict = [(NSString *)paramDict JSONValue];
    } else if ([paramDict isKindOfClass:[NSDictionary class]]) {
        dict = [paramDict decodeNativeBuffersIfNeed];
    }
    if ([dict isKindOfClass:[NSDictionary class]]) {
        return dict;
    }
    return nil;
}


@end


@implementation NSArray (JSONValue)

- (NSString *)JSONRepresentation
{
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSData * data = [NSJSONSerialization dataWithJSONObject:self options:0 error:nil];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];        
    }
    return nil;
}

@end


@implementation NSDictionary (JSONValue)

- (NSString *)JSONRepresentation
{
    return [self JSONRepresentationWithOptions:0];
}

- (NSString *)JSONRepresentationWithOptions:(NSJSONWritingOptions)options
{
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSData * data = [NSJSONSerialization dataWithJSONObject:self options:options error:nil];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

@end


@implementation NSData (JSONValue)

- (id)JSONValue
{
    id object = [NSJSONSerialization JSONObjectWithData:self options:NSJSONReadingAllowFragments error:nil];
    return object;
}

- (NSDictionary * _Nullable)JSONDictionary {
    NSDictionary *result = [self JSONValue];
    if (![result isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    return result;
}

- (nullable id)JSONValueWithOptions:(NSJSONReadingOptions)opt error:(NSError **)error {
    return [NSJSONSerialization JSONObjectWithData:self options:opt error:error];
}

@end

