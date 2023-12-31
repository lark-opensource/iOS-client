//
//  BytedCertParameter.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/22.
//

#import "BytedCertParameter.h"
#import "BytedCertDefine.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <BDModel/BDModel.h>
#import <BDModel/BDMappingStrategy.h>


@implementation BytedCertResult


@end


@implementation BytedCertParameter

- (instancetype)init {
    return [self initWithBaseParams:@{} identityParams:nil];
}

- (instancetype)initWithBaseParams:(NSDictionary *)params identityParams:(NSDictionary *)identityParams {
    self = [super init];
    if (self) {
        _youthCertScene = -1;
        _livenessType = BytedCertLiveTypeAction;
        _showAuthError = YES;

        NSMutableDictionary *mutableCombinedParams = [NSMutableDictionary dictionary];

        if (!BTD_isEmptyDictionary(params)) {
            [mutableCombinedParams addEntriesFromDictionary:params];
            [self bd_modelSetWithDictionary:params];
            [self bd_modelSetWithJSON:[BDMappingStrategy mapJSONKeyWithDictionary:params options:BDModelMappingOptionsSnakeCaseToCamelCase]];
        }

        if (!BTD_isEmptyDictionary(identityParams)) {
            [mutableCombinedParams addEntriesFromDictionary:identityParams];
            [self bd_modelSetWithDictionary:identityParams];
            [self bd_modelSetWithJSON:[BDMappingStrategy mapJSONKeyWithDictionary:identityParams options:BDModelMappingOptionsSnakeCaseToCamelCase]];
        }

        NSMutableDictionary *mutableExtraParams = [NSMutableDictionary dictionary];
        [mutableExtraParams addEntriesFromDictionary:[mutableCombinedParams btd_dictionaryValueForKey:@"extra_params"]];
        [mutableExtraParams addEntriesFromDictionary:[mutableCombinedParams btd_dictionaryValueForKey:@"extraParams"]];
        NSArray<NSString *> *existedKeys = [[[self bd_modelToJSONObject] allKeys] btd_map:^id _Nullable(id _Nonnull obj) {
            return [BDMappingStrategy mapCamelToSnakeCase:obj];
        }];
        [mutableExtraParams addEntriesFromDictionary:[mutableCombinedParams btd_filter:^BOOL(id _Nonnull key, id _Nonnull obj) {
                                return ![existedKeys containsObject:key] && ![mutableExtraParams.allKeys containsObject:key];
                            }]];
        self.extraParams = mutableExtraParams.copy;
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [self bd_modelCopy];
}

@end
