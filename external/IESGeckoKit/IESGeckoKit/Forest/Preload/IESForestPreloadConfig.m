// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestPreloadConfig.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>

static NSString* const kPreloadImageKey = @"image";

@implementation IESForestPreloadConfig

// currently only image type is treated in special way
- (NSArray<IESForestPreloadSubResourceConfig *> *)otherResources
{
    NSMutableArray *resources = [NSMutableArray array];
    [self.subResources enumerateKeysAndObjectsUsingBlock:^(NSString* type, NSArray* resList, BOOL * _Nonnull stop) {
        if (![type isEqualToString:kPreloadImageKey]) {
            for (NSDictionary *configDict in resList) {
                IESForestPreloadSubResourceConfig *config = [IESForestPreloadSubResourceConfig configWithDictionary:configDict];
                if (config) {
                    [resources addObject:config];
                }
            }
        }
    }];
    return resources;
}

- (NSArray<IESForestPreloadSubResourceConfig *> *)imageResources
{
    NSMutableArray *resources = [NSMutableArray array];
    NSArray * images = [self.subResources btd_arrayValueForKey:kPreloadImageKey];
    for (NSDictionary *configDict in images) {
        IESForestPreloadSubResourceConfig *config = [IESForestPreloadSubResourceConfig configWithDictionary:configDict];
        if (config) {
            [resources addObject:config];
        }
    }
    return resources;
}

@end

@implementation IESForestPreloadSubResourceConfig

+ (instancetype)configWithDictionary:(NSDictionary *)dict
{
    if (!([dict isKindOfClass:[NSDictionary class]] && dict.count > 0)) {
        return nil;
    }

    IESForestPreloadSubResourceConfig *config = [[self alloc] init];
    config.url = [dict btd_stringValueForKey:@"url"];
    config.enableMemory = [dict btd_boolValueForKey:@"enableMemory"];
    return config;
}

@end

