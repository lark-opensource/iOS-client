//
//  NSDictionary+LKJSON.m
//  LarkMonitor
//
//  Created by sniperj on 2020/11/8.
//

#import "NSDictionary+LKJSON.h"

@implementation NSDictionary (LKJSON)

- (BOOL)lk_isValidJSONObject
{
    return [NSJSONSerialization isValidJSONObject:self];
}

- (NSString *)lk_jsonString
{
    return [self lk_jsonString:nil];
}

- (NSString * _Nullable)lk_jsonString:(NSError * _Nullable __autoreleasing *)error
{
    NSData *data = [self lk_jsonData:error];
    if (data == nil) {
        return nil;
    }
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return string;
}

- (NSData *)lk_jsonData
{
    return [self lk_jsonData:nil];
}

- (NSData *)lk_jsonData:(NSError * _Nullable __autoreleasing *)error
{
    if (![self lk_isValidJSONObject]) {
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
