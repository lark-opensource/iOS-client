//
//  NSData+LKJSON.m
//  LarkMonitor
//
//  Created by sniperj on 2020/11/8.
//

#import "NSData+LKJSON.h"

@implementation NSData (LKJSON)

- (id)lk_jsonObject
{
    return [self lk_jsonObject:nil];
}

- (id)lk_jsonMutableObject
{
    return [self lk_jsonMutableObject:nil];
}

- (id)lk_jsonObject:(NSError **)error
{
    id obj = [NSJSONSerialization JSONObjectWithData:self options:0 error:error];
    return obj;
}

- (id)lk_jsonMutableObject:(NSError **)error
{
    id obj = [NSJSONSerialization JSONObjectWithData:self options:NSJSONReadingMutableContainers error:error];
    return obj;
}

@end
