//
//  BDPPluginBase.m
//  Timor
//
//  Created by CsoWhy on 2018/10/20.
//

#import "BDPPluginBase.h"
@implementation BDPPluginBase

+ (BOOL)isParamValid:(BDPJSBridgeCallback)callback paramDic:(NSDictionary *)paramDic paramArr:(NSArray *)paramArr
{
    BOOL bRet = YES;
    NSString * __block errParam = nil;
    
    [paramArr enumerateObjectsUsingBlock:^(NSString *param, NSUInteger idx, BOOL * _Nonnull stop) {
        id paramValue = [paramDic objectForKey:param];
        if (paramValue == nil || ([paramValue isKindOfClass:[NSString class]] && [paramValue length] == 0)) {
            errParam = param;
            *stop = YES;
        }
    }];
    
    if (!BDPIsEmptyString(errParam)) {
        bRet = NO;
        NSString *errMsg = [NSString stringWithFormat:@"%@ is illegal", errParam];
        BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeParamError, @{@"errMsg": errMsg});
    }
    
    return bRet;
}

+ (NSString *)isParamValid:(NSDictionary *)paramDic withCheckKeys:(NSArray *)checkKeys
{
    NSString * __block errParamKey = nil;
    
    [checkKeys enumerateObjectsUsingBlock:^(NSString *param, NSUInteger idx, BOOL * _Nonnull stop) {
        id paramValue = [paramDic objectForKey:param];
        if (paramValue == nil || ([paramValue isKindOfClass:[NSString class]] && [paramValue length] == 0)) {
            errParamKey = param;
            *stop = YES;
        }
    }];
    
    if (!BDPIsEmptyString(errParamKey)) {
        NSString *errMsg = [NSString stringWithFormat:@"%@ is empty", errParamKey];
        return errMsg;
    }
    
    return nil;
}

+ (NSString*)resultMsgOfCheckHasKeys:(NSArray<NSString*>*)nameArr inParameters:(NSDictionary*)paramDic
{
    if (nameArr == nil || paramDic == nil || ![paramDic isKindOfClass:[NSDictionary class]]) {
        return @"invalid check params";
    }
    NSString* result = @"";
    for (NSString* k in nameArr) {
        if ([paramDic objectForKey:k] == nil) {
            result = [result stringByAppendingFormat:@" %@",k];
        }
    }
    if ([result length] == 0) {
        return nil;
    }
    else {
        result = [@"param lost:" stringByAppendingString:result];
        return result;
    }
}

@end
