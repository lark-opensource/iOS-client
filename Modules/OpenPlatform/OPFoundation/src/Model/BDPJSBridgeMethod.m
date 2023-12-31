//
//  BDPJSBridgeMethod.m
//  Timor
//
//  Created by 王浩宇 on 2019/8/28.
//

#import "BDPJSBridgeMethod.h"

#define SafeString(string) [string isKindOfClass:[NSString class]] ? string : @""
#define SafeDictionary(dict) [dict isKindOfClass:[NSDictionary class]] ? dict : @{}

@implementation BDPJSBridgeMethod

+ (instancetype)methodWithName:(NSString *)name params:(NSDictionary *)params
{
    BDPJSBridgeMethod *method = [[self alloc] init];
    method.name = SafeString(name);
    method.params = SafeDictionary(params);
    return method;
}

- (id)copyWithZone:(NSZone *)zone
{
    BDPJSBridgeMethod *method = [[BDPJSBridgeMethod allocWithZone:zone] init];
    method.name = self.name;
    method.params = self.params;
    return method;
}

@end
