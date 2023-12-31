//
//  NSDictionary+HMDJSON.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/15.
//

#import "NSDictionary+HMDJSON.h"

@implementation NSDictionary (HMDJSON)

- (BOOL)hmd_isValidJSONObject
{
    return [NSJSONSerialization isValidJSONObject:self];
}

- (NSString *)hmd_jsonString
{
    return [self hmd_jsonString:nil];
}

- (NSString * _Nullable)hmd_jsonString:(NSError * _Nullable __autoreleasing *)error
{
    NSData *data = [self hmd_jsonData:error];
    if (data == nil) {
        return nil;
    }
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return string;
}

- (NSData *)hmd_jsonData
{
    return [self hmd_jsonData:nil];
}

- (NSData *)hmd_jsonData:(NSError * _Nullable __autoreleasing *)error
{
    if (![self hmd_isValidJSONObject]) {
        return nil;
    }
    
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:self options:0 error:error];
    } @catch (NSException *exception) {
        
    }
    return data;
}

@end
