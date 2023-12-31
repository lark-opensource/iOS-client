//
//  BDPAppPagePrefetchMatchKey.m
//  Timor
//
//  Created by insomnia on 2021/2/24.
//
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/BDPUtils.h>
#import "BDPAppPagePrefetchMatchKey.h"
#import <ECOInfra/NSString+BDPExtension.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPAppPagePrefetchDefines.h"
//#import <ByteDanceKit/ByteDanceKit.h>

@interface NSString(BTDAdditions)
- (NSDictionary<NSString*, NSString*> *)btd_queryParamDict;
@end

@implementation NSString(BTDAdditions)

- (NSDictionary<NSString*, NSString*> *)btd_queryParamDict {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:self];
    if (!urlComponents || urlComponents.queryItems.count <= 0) {
        return @{};
    }
    NSMutableDictionary *queryDict = [NSMutableDictionary new];
    [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.name.length <= 0) {
            return;
        }
        queryDict[obj.name] = obj.value ? : @"";
    }];
    return queryDict;
}
@end

@implementation BDPAppPagePrefetchMissKeyItem

@end

@interface BDPAppPagePrefetchMatchKey()
@property (nonatomic) BOOL newVersion;
@property (nonatomic ,copy) NSArray<NSString*> *requireQueryKeys;
@property (nonatomic ,copy) NSArray<NSString*> *requireHeaderKeys;
@property (nonatomic ,copy) NSArray<NSString*> *requiredStorageKeys;
@property (nonatomic, copy, readwrite) NSString *dateFormatter;
@property (nonatomic, copy) NSArray<BDPAppPagePrefetchMissKeyItem *> *missKeyItems;

@property (nonatomic, copy, readwrite) NSString* url;
@property (nonatomic, copy, readwrite) NSString* method;
@property (nonatomic, copy, readwrite) NSDictionary* header;
@property (nonatomic, copy, readwrite) NSString* data;
@property (nonatomic, copy, readwrite) NSString* responseType;
@property (nonatomic, assign, readwrite) BOOL ignoreHeadersMatching;
@end

@implementation BDPAppPagePrefetchMatchKey

static NSString *kPrefetchShouldDeleteMissKey = @"delete_miss_key";
static NSString *kPrefetchMissKeyDefault = @"default";

- (instancetype)initWithParam:(NSDictionary*)param
{
    self = [super init];
    if (self) {
        self.newVersion = YES;
        self.url = [param bdp_stringValueForKey:@"url"];
        self.method = [param stringValueForKey:@"method" defaultValue:@"GET"].uppercaseString;
        self.header = [param dictionaryValueForKey:@"header" defalutValue:@{@"content-type":@"application/json"}];
        if (![self.header bdp_stringValueForKey:@"content-type"]) {
            NSMutableDictionary *dic = [self.header mutableCopy];
            [dic setObject:@"application/json" forKey:@"content-type"];
            self.header = [dic copy];
        }
        
        if (PrefetchLarkFeatureGatingDependcy.prefetchCrashOpt) {
            NSMutableDictionary *dic = [self.header mutableCopy];
            NSArray *keyArr = [dic allKeys];
            for (NSString *key in keyArr) {
                if (![dic[key] isKindOfClass:[NSString class]]) {
                    NSString *value = [[NSString alloc] initWithFormat:@"%@", dic[key]];
                    if (value) {
                        dic[key] = value;
                    } else {
                        BDPLogTagError(kLogTagPrefetch, @"header failed, because %@ cannot format string", key);
                    }
                }
            }
            self.header = [dic copy];
        }
        
        //对齐ttrequest，get请求忽略string类型的data
        NSString* data = [param bdp_stringValueForKey:@"data"];
        if (!data) {
            //data = [[param bdp_dictionaryValueForKey:@"data"] btd_jsonStringEncoded]; btd_jsonStringEncoded API not found
            data = [[param bdp_dictionaryValueForKey:@"data"] JSONRepresentation];
        }
        if (!data) {
            id temp = [param objectForKey:@"data"];
            if ([temp isKindOfClass:[NSData class]]) {
                data = [(NSData*)temp base64EncodedStringWithOptions:0];
            }
        }
        self.data = data;
        
        if ([self.method isEqual:@"GET"]) {
            self.data = nil;
        }

        self.responseType = [param stringValueForKey:@"responseType" defaultValue:@"text"];
        self.requireQueryKeys = [[param bdp_dictionaryValueForKey:@"hitPrefetchExtraRules"] bdp_arrayValueForKey:@"requiredQueryKeys"];
        self.requireHeaderKeys = [[param bdp_dictionaryValueForKey:@"hitPrefetchExtraRules"] bdp_arrayValueForKey:@"requiredHeaderKeys"];
        self.requiredStorageKeys = [[param bdp_dictionaryValueForKey:@"hitPrefetchExtraRules"] bdp_arrayValueForKey:@"requiredStorageKeys"];
        self.ignoreHeadersMatching = [[param bdp_dictionaryValueForKey:@"hitPrefetchExtraRules"] bdp_boolValueForKey2:@"ignoreHeadersMatching"];
        self.dateFormatter = [[param dictionaryValueForKey:@"hitPrefetchExtraRules" defalutValue:@{}] stringValueForKey:@"dateFormatter" defaultValue:@"yyyy-MM-dd"];
        NSDictionary<NSString *, NSDictionary *> *missKeyConfig = [[param bdp_dictionaryValueForKey:@"hitPrefetchExtraRules"] bdp_dictionaryValueForKey:@"missKeyConfig"];
        [self buildMissKeyItemsWithMissKeyDic:missKeyConfig];
    }
    return self;
}

- (void)buildMissKeyItemsWithMissKeyDic:(NSDictionary<NSString *, NSDictionary *> *)missKeyDic {
    NSMutableArray *items = [NSMutableArray array];
    for (NSString *key in missKeyDic.allKeys) {
        if (![key isKindOfClass:[NSString class]] || key.length <= 0) {
            continue;
        }
        NSDictionary *value = missKeyDic[key];
        if (![value isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        BOOL shouldDelete = [value bdp_boolValueForKey2:kPrefetchShouldDeleteMissKey];
        NSString *defaultValue = [value bdp_stringValueForKey:kPrefetchMissKeyDefault];

        BDPAppPagePrefetchMissKeyItem *item = [[BDPAppPagePrefetchMissKeyItem alloc] init];
        item.key = key;
        item.shouldDelete = shouldDelete;
        item.defaultValue = defaultValue;
        [items addObject:item];
    }
    if (items.count <= 0 ) {
        self.missKeyItems = nil;
    } else {
        self.missKeyItems = items;
    }
}

-(void)updateUrlIfNewVersion:(NSString *) url
{
    if (self.newVersion) {
        self.url = url;
    }
}
-(void)updateHeaderIfNewVersion:(NSDictionary *) header
{
    if (self.newVersion) {
        self.header = header;
    }
}

-(void)updateDataIfNewVersion:(NSString *) data
{
    if (self.newVersion) {
        self.data = data;
    }
}

- (instancetype)initWithUrl:(NSString*)url
{
    self = [super init];
    if (self) {
        self.newVersion = NO;
        self.url = url;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if ([object isKindOfClass:[self class]]) {
        BDPAppPagePrefetchMatchKey *otherKey = (BDPAppPagePrefetchMatchKey*)object;
        if (self.newVersion == otherKey.newVersion) {
            if (self.newVersion) {
                if ([self isUrlEqual:otherKey] && [self.method isEqual:otherKey.method] && [self isHeaderEqual:otherKey] && [self.responseType isEqual:otherKey.responseType] && ([[self.data JSONDictionary] isEqualToDictionary:[otherKey.data JSONDictionary]] || [self.data isEqualToString:otherKey.data] || (BDPIsEmptyString(self.data) && BDPIsEmptyString(otherKey.data)))) {
                    return YES;
                }
            } else {
                if ([self.url isEqual:otherKey.url]) {
                    return YES;
                }
            }
        }
        
    }
    return NO;
}

- (OPPrefetchErrnoWrapper *)isEqualToMatchKey:(BDPAppPagePrefetchMatchKey *)object
{
    if (self == object) {
        return [OPPrefetchErrnoHelper prefetchSuccess];
    }
    if ([object isKindOfClass:[self class]]) {
        BDPAppPagePrefetchMatchKey *otherKey = (BDPAppPagePrefetchMatchKey*)object;
        if (self.newVersion == otherKey.newVersion) {
            if (self.newVersion) {
                if (![self isUrlHostEqual:otherKey]) {
                    return [OPPrefetchErrnoHelper hostMismatchWithUrl:otherKey.url cacheUrlList:[self cacheUrlList]];
                }
                if (![self isUrlPathEqual:otherKey]) {
                    return [OPPrefetchErrnoHelper pathMismatchWithUrl:otherKey.url cacheUrlList:[self cacheUrlList]];
                }
                if (![self isUrlQueryEqual:otherKey]) {
                    return [OPPrefetchErrnoHelper queryMismatchWithUrl:otherKey.url cacheUrlList:[self cacheUrlList]];
                }
                // url不匹配
                if (![self isUrlEqual:otherKey]) {
                    return [OPPrefetchErrnoHelper urlNormalMismatchWithUrl:otherKey.url cacheUrlList:[self cacheUrlList]];
                }
                
                // 请求方式不同
                if (![self.method isEqual:otherKey.method]) {
                    return [OPPrefetchErrnoHelper methodMismatchWithMethod:otherKey.method cacheMethod:self.method];
                }
                
                // head不同
                if (![self isHeaderEqual:otherKey]) {
                    return [OPPrefetchErrnoHelper headerMismatchWithHeader:[otherKey.header JSONRepresentation] cacheHeader:[self.header JSONRepresentation]];
                }
                
                // responseType不同
                if (![self.responseType isEqual:otherKey.responseType]) {
                    return [OPPrefetchErrnoHelper responseTypeMismatchWithResponseType:otherKey.responseType cacheResponseType:self.responseType];
                }
                
                // dataType不同
                if (!([[self.data JSONDictionary] isEqualToDictionary:[otherKey.data JSONDictionary]]
                     || [self.data isEqualToString:otherKey.data]
                     || (self.data == nil && otherKey.data == nil))) {
                    return [OPPrefetchErrnoHelper dataMismatchWithData:otherKey.data cacheData:self.data];
                }
                
                return [OPPrefetchErrnoHelper prefetchSuccess];
            } else {
                // 旧版
                if ([self.url isEqual:otherKey.url]) {
                    return [OPPrefetchErrnoHelper prefetchSuccess];
                } else {
                    //  url不匹配
                    return [OPPrefetchErrnoHelper urlNormalMismatchWithUrl:otherKey.url cacheUrlList:[self cacheUrlList]];
                }
            }
        }
    }
    return [OPPrefetchErrnoHelper prefetchUnknown];
}

- (NSString *)cacheUrlList {
    NSString *result;
    if (self.getCacheUrls) {
        NSArray<NSString *> *url = self.getCacheUrls();
        result = [url componentsJoinedByString:@", "];
    }
    return [NSString stringWithFormat:@"[%@]", result];
}

- (NSUInteger)hash
{
    return [[NSString stringWithFormat:@"%@%@%@",[self.url bdp_urlWithoutParmas],self.method,self.responseType] integerValue];
}

- (BOOL)isUrlHostEqual:(BDPAppPagePrefetchMatchKey*)otherKey {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:self.url];
    NSURLComponents *otherUrlComponents = [NSURLComponents componentsWithString:otherKey.url];
    return [urlComponents.host isEqualToString:otherUrlComponents.host];
}

- (BOOL)isUrlPathEqual:(BDPAppPagePrefetchMatchKey*)otherKey {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:self.url];
    NSURLComponents *otherUrlComponents = [NSURLComponents componentsWithString:otherKey.url];
    return [urlComponents.path isEqualToString:otherUrlComponents.path];
}

- (BOOL)isUrlQueryEqual:(BDPAppPagePrefetchMatchKey*)otherKey {
    NSDictionary *queryDict = [self.url btd_queryParamDict];
    NSDictionary *otherQueryDict = [otherKey.url btd_queryParamDict];
    return [self isDict:queryDict equalToOtherDict:otherQueryDict withRequireKeys:self.requireQueryKeys?:otherKey.requireQueryKeys];
}

- (BOOL)isUrlEqual:(BDPAppPagePrefetchMatchKey*)otherKey
{
    if ([self.url isEqual:otherKey.url]) {
        return YES;
    } else {
        NSString *hostPath = [[self.url componentsSeparatedByString:@"?"] firstObject];
        NSString *otherHostPath = [[otherKey.url componentsSeparatedByString:@"?"] firstObject];
        if ([hostPath isEqual:otherHostPath]) {
            return [self isUrlQueryEqual:otherKey];
        }
    }
    return NO;
}

- (BOOL)isHeaderEqual:(BDPAppPagePrefetchMatchKey*)otherKey
{
    return self.ignoreHeadersMatching|| otherKey.ignoreHeadersMatching ||[self isDict:self.header equalToOtherDict:otherKey.header withRequireKeys:self.requireHeaderKeys?:otherKey.requireHeaderKeys];
}

- (BOOL)isDict:(NSDictionary*)dict equalToOtherDict:(NSDictionary*)otherDict withRequireKeys:(NSArray*)array
{
    if ([array count] <= 0) {
        return [dict isEqualToDictionary:otherDict];
    }
    
    __block BOOL isEqual = YES;
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![[dict objectForKey:obj] isEqual:[otherDict objectForKey:obj]]) {
            isEqual = NO;
            *stop = YES;
        }
    }];
    
    return isEqual;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    BDPAppPagePrefetchMatchKey *key = [[BDPAppPagePrefetchMatchKey alloc] init];
    key.newVersion = self.newVersion;
    key.url = self.url;
    key.header = self.header;
    key.data = self.data;
    key.responseType = self.responseType;
    key.method = self.method;
    key.requireQueryKeys = self.requireQueryKeys;
    key.requireHeaderKeys = self.requireHeaderKeys;
    key.ignoreHeadersMatching = self.ignoreHeadersMatching;
    key.requiredStorageKeys = self.requiredStorageKeys;
    return key;
}
@end
