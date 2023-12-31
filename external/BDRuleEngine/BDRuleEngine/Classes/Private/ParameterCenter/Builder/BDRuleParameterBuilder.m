//
//  BDRuleParameterFetcher.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/29.
//

#import "BDRuleParameterBuilder.h"
#import "BDRuleParameterService.h"
#import "BDRuleParameterRegistry.h"
#import "BDRuleEngineErrorConstant.h"

@implementation BDRuleParameterBuilder

#pragma mark - Public
- (id)generateValueFor:(NSString *)key
                 extra:(NSDictionary *)extra
                 error:(NSError **)error
{
    BDRuleParameterBuilderModel *builderModel = [BDRuleParameterRegistry builderForKey:key];
    if (!builderModel) {
        return nil;
    }
    if (builderModel.builder) {
        id result = builderModel.builder(self);
        if (!result) {
            if (error) {
                *error = [NSError errorWithDomain:BDRuleParameterErrorDomain code:BDRuleParameterErrorKeyBuilderParameterMiss userInfo:nil];
            }
            return nil;
        }
        BOOL checkType = [self __checkValueType:result type:builderModel.type];
        if (!checkType) {
            if (error) {
                *error = [NSError errorWithDomain:BDRuleParameterErrorDomain code:BDRuleParameterErrorKeyBuilderTypeNotMatch userInfo:nil];
            }
            NSAssert(NO, @"type not matching the result");
            return nil;
        }
        return result;
    } else {
        if (error) {
            *error = [NSError errorWithDomain:BDRuleParameterErrorDomain code:BDRuleParameterErrorKeyNotRegistered userInfo:nil];
        }
        NSAssert(NO, @"builder can not be nil");
    }
    return nil;
}

#pragma mark - Private
- (BOOL)__checkValueType:(id)value
                   type:(BDRuleParameterType)type
{
    switch (type) {
        case BDRuleParameterTypeNumberOrBool:
            if ([value isKindOfClass:[NSNumber class]]) {
                return YES;
            }
            break;
        case BDRuleParameterTypeString:
            if ([value isKindOfClass:[NSString class]]) {
                return YES;
            }
            break;
        case BDRuleParameterTypeArray:
            if ([value isKindOfClass:[NSArray class]]) {
                return YES;
            }
            break;
        case BDRuleParameterTypeDictionary:
            if ([value isKindOfClass:[NSDictionary class]]) {
                return YES;
            }
            break;
        default:
            break;
    }
    return NO;
}
    

@end
