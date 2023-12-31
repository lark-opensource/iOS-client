//
//  TTRouteDefine.m
//  Pods
//
//  Created by 冯靖君 on 17/3/20.
//
//

#import "TTRouteDefine.h"

@implementation TTRouteUserInfo

- (instancetype)initWithInfo:(NSDictionary *)info
{
    self = [super init];
    if (self) {
        _allInfo = info;
        if ([info.allKeys containsObject:@"refer"]) {
            self.refer = [self _stringValueForKey:@"refer" inDict:info];
        }
        if ([info.allKeys containsObject:@"animated"]) {
            self.animated = [info objectForKey:@"animated"];
        }
        NSMutableDictionary *mDict = [info mutableCopy];
        [mDict removeObjectForKey:@"refer"];
        [mDict removeObjectForKey:@"animated"];
        if (mDict.allKeys.count) {
            self.extra = [mDict copy];
        }
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@\nrefer:%@\nanimated:%d\nextra:\n%@\n", [super description], self.refer, self.animated.boolValue, self.extra];
}

- (NSString *)_stringValueForKey:(NSString *)key inDict:(NSDictionary *)dict {
    id value = [dict objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return value;
    }else if(value && [value isKindOfClass:[NSNumber class]]){
        return [value stringValue];
    }else{
        return nil;
    }
}

@end

@interface TTRouteParamObj ()

@property (nonatomic, strong, readwrite) NSDictionary *allParams;

@end

@implementation TTRouteParamObj

- (instancetype)initWithAllParams:(NSDictionary *)params
{
    self = [super init];
    if (self) {
        _allParams = params;
    }
    return self;
}

- (NSDictionary *)allParams
{
    if (!_allParams) {
        [self _updateAllParams];
    }
    return _allParams;
}

- (void)_updateAllParams
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:_queryParams];
    NSString *actionValue = [params objectForKey:TTRouteReservedActionKey];
    if (_userInfo.refer && _userInfo.refer.length > 0) {
        [params setValue:_userInfo.refer forKey:@"refer"];
    }
    if (_userInfo.animated) {
        [params setValue:_userInfo.animated forKey:@"animated"];
    }
    
    if (_userInfo.extra.count > 0) {
        [params addEntriesFromDictionary:_userInfo.extra];
    }
    
    // 确保route action的identifier不会被userInfo中的同名key覆盖
    if ([params.allKeys containsObject:TTRouteReservedActionKey]) {
        [params setValue:actionValue forKey:TTRouteReservedActionKey];
    }
    
    _allParams = [params copy];
}

- (void)setUserInfo:(TTRouteUserInfo *)userInfo
{
    _userInfo = userInfo;
    [self _updateAllParams];
}

- (BOOL)hasRouteAction
{
    return [self.host isEqualToString:TTRouteReservedActionEntry];
}

- (NSString *)routeActionIdentifier
{
    return [self.allParams objectForKey:TTRouteReservedActionKey];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@\nsourceURL:%@\nscheme:%@\nhost:%@\nsegment:%@\nqueryParams:\n%@\nrouteUserInfo:\n%@\nallparams:\n%@", [super description], self.sourceURL, self.scheme, self.host, self.segment, self.queryParams, [self.userInfo description], [self.allParams description]];
}

@end
