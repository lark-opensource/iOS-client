//
//  NSString+HMDJSON.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/15.
//

#import "NSString+HMDJSON.h"

@implementation NSString (HMDJSON)

- (NSDictionary * _Nullable)hmd_jsonDict
{
    id obj = [self hmd_jsonObject];
    if ([obj isKindOfClass:NSDictionary.class]) {
        return obj;
    }
    return nil;
}

- (id)hmd_jsonObject
{
    return [self hmd_jsonObject:nil];
}

- (id)hmd_jsonMutableObject
{
    return [self hmd_jsonMutableObject:nil];
}

- (id _Nullable)hmd_jsonObject:(NSError **)error
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) { //nil data will throw an exception
        if (error) {
            *error = [NSError errorWithDomain:@"HMDJSONParseDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:@"invalid data"}];
        }
        return nil;
    }
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    return obj;
}

- (id _Nullable)hmd_jsonMutableObject:(NSError **)error
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) { //nil data will throw an exception
        if (error) {
            *error = [NSError errorWithDomain:@"HMDJSONParseDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:@"invalid data"}];
        }
        return nil;
    }
    id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:error];
    return obj;
}

@end
