//
//  BDStrategyCenterUtil.m
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2022/1/4.
//

#import "BDStrategyCenterUtil.h"

@implementation BDStrategyCenterUtil

+ (NSString *)formatToJsonString:(id)input
{
    return [self formatToJsonString:input option:kNilOptions];
}

+ (NSString *)formatToJsonString:(id)input option:(NSJSONWritingOptions)opt
{
    if (![NSJSONSerialization isValidJSONObject:input]) {
        return nil;
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:input options:opt error:&error];
    if (!error && jsonData) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return nil;
}

@end
