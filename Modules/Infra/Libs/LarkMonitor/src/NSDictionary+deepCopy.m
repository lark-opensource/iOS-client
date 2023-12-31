//
//  NSDictionary+deepCopy.m
//  LarkApp
//
//  Created by sniperj on 2019/12/1.
//

#import "NSDictionary+deepCopy.h"
#import "NSData+LKJSON.h"
#import "NSDictionary+LKJSON.h"

@implementation NSDictionary (deepCopy)

-(NSDictionary *)deepCopy
{
    NSError *error = nil;
    NSData *serializedData = [self lk_jsonData:&error];
    if (serializedData && !error) {
        NSError *jsonError = nil;
        NSDictionary *jsonDict = [serializedData lk_jsonObject:&jsonError];
        if ([jsonDict isKindOfClass:[NSDictionary class]] && !jsonError) {
            return jsonDict;
        }
    }
    return self;
}

@end
