//
//  NSData+HMDJSON.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/15.
//

#import "NSData+HMDJSON.h"

@implementation NSData (HMDJSON)

- (id)hmd_jsonObject
{
    return [self hmd_jsonObject:nil];
}

- (id)hmd_jsonMutableObject
{
    return [self hmd_jsonMutableObject:nil];
}

- (id)hmd_jsonObject:(NSError **)error
{
    id obj = [NSJSONSerialization JSONObjectWithData:self options:0 error:error];
    return obj;
}

- (id)hmd_jsonMutableObject:(NSError **)error
{
    id obj = [NSJSONSerialization JSONObjectWithData:self options:NSJSONReadingMutableContainers error:error];
    return obj;
}

@end
