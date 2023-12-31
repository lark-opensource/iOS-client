//
//  EffectPlatformCache.m
//  EffectPlatformSDK
//
//  Created by 琨王 on 2019/2/22.
//

#import "EffectPlatformCache.h"
#import "EffectPlatformJsonCache.h"

@interface EffectPlatformCache()
@property (nonatomic, copy) NSString *accessKey;
@property (nonatomic, strong) id<EffectPlatformCacheService> jsonCache;
@end

@implementation EffectPlatformCache

- (instancetype)initWithAccessKey:(NSString *)accessKey
{
    self = [super init];
    if (self) {
        _accessKey = accessKey;
        _jsonCache = [[EffectPlatformJsonCache alloc] initWithAccessKey:accessKey];
    }
    return self;
}

- (void)setEnableMemoryCache:(BOOL)enable
{
    [_jsonCache setEnableMemoryCache:enable];
}

- (nullable IESEffectPlatformNewResponseModel *)newResponseWithKey:(NSString *)key
{
    return [_jsonCache newResponseWithKey:key];
}

- (void)clearMemory
{
    [_jsonCache clearMemory];
}

- (nullable IESEffectModel *)effectWithKey:(NSString *)key
{
    return [_jsonCache effectWithKey:key];
}

- (IESEffectPlatformResponseModel *)objectWithKey:(NSString *)key
{
    return [_jsonCache objectWithKey:key];
}

- (void)setJson:(NSDictionary *)json effect:(IESEffectModel *)object forKey:(nonnull NSString *)key
{
    [_jsonCache setJson:json effect:object forKey:key];
}

- (void)setJson:(NSDictionary *)json object:(IESEffectPlatformResponseModel *)object forKey:(NSString *)key
{
    [_jsonCache setJson:json object:object forKey:key];
}

- (void)setJson:(NSDictionary *)json newResponse:(IESEffectPlatformNewResponseModel *)object forKey:(NSString *)key
{
    [_jsonCache setJson:json newResponse:object forKey:key];
}

- (NSDictionary *)modelDictWithKey:(NSString *)key {
    return [_jsonCache modelDictWithKey:key];
}

- (void)setJson:(NSDictionary *)json forKey:(NSString *)key {
    [_jsonCache setJson:json forKey:key];
}

- (void)clear
{
    [_jsonCache clear];
}

- (void)clearJsonAndObjectForKey:(NSString *)key
{    
    [_jsonCache clearJsonAndObjectForKey:key];
}

@end
