//
//  NSArray+HMDJSON.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/15.
//

#import "NSArray+HMDJSON.h"

@implementation NSArray (HMDJSON)

- (NSString *)hmd_jsonString {
    return [self hmd_jsonString:nil];
}

- (NSString *)hmd_jsonString:(NSError * _Nullable __autoreleasing *)error {
    NSData *data = [self hmd_jsonData:error];
    if (data == nil) {
        return nil;
    }
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return string;
}

- (NSData *)hmd_jsonData {
    return [self hmd_jsonData:nil];
}

- (NSData *)hmd_jsonData:(NSError * _Nullable __autoreleasing *)error {
    return [self hmd_jsonDataWithOptions:kNilOptions error:error];
}

#pragma mark - HMDJSONObjectProtocol

- (BOOL)hmd_isValidJSONObject {
    return [NSJSONSerialization isValidJSONObject:self];
}

- (NSData *)hmd_jsonDataWithOptions:(NSJSONWritingOptions)opt error:(NSError * _Nullable __autoreleasing *)error {
    if (![self hmd_isValidJSONObject]) {
        return nil;
    }
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:self options:opt error:error];
    } @catch (NSException *exception) {
        // Do nothing
    }
    return data;
}

@end
