//
//  NSURL+EMA.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/4.
//

#import "NSURL+EMA.h"

@implementation NSURL (EMA)

- (NSDictionary *)ema_queryItems
{
    NSString * query = [self query];
    if ([query length] == 0) {
        return nil;
    }

    NSMutableDictionary * result = [NSMutableDictionary dictionaryWithCapacity:10];
    NSArray *paramsList = [query componentsSeparatedByString:@"&"];
    [paramsList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *keyAndValue = [obj componentsSeparatedByString:@"="];
        if ([keyAndValue count] > 1) {
            NSString *paramKey = [keyAndValue objectAtIndex:0];
            NSString *paramValue = [keyAndValue objectAtIndex:1];
            if ([paramValue rangeOfString:@"%"].length > 0) {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                CFStringRef decodedString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                                                    kCFAllocatorDefault,
                                                                                                    (__bridge CFStringRef)paramValue,
                                                                                                    CFSTR(""),
                                                                                                    kCFStringEncodingUTF8);
#pragma clang diagnostic pop
                paramValue = (__bridge_transfer NSString *)decodedString;
            }

            [result setValue:paramValue forKey:paramKey];
        }
    }];

    return result;
}

-(NSString *)ema_paramForKey:(NSString *)key {
    NSString * query = [self query];
    if (query.length == 0 || key.length <= 0) {
        return nil;
    }
    
    NSArray *paramsList = [query componentsSeparatedByString:@"&"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", [key stringByAppendingString:@"="]];
    NSArray *filterArray = [paramsList filteredArrayUsingPredicate:predicate];
    if (filterArray.count <= 0) {
        return nil;
    }
    return [[filterArray.firstObject componentsSeparatedByString:@"="] lastObject];
}

@end
