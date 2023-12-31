//
// BDXSchema.m
// Bullet-BulletXResource
//
// Created by bytedance on 2021/3/5.
//

#import <BDXServiceCenter/BDXContextKeyDefines.h>
#import <BDXServiceCenter/BDXMonitorProtocol.h>
#import <BDXServiceCenter/BDXResourceLoaderProtocol.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <BDXServiceCenter/BDXServiceRegister.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <IESPrefetch/IESPrefetchManager.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>

#import "BDXSchema.h"

#define BDXHttpScheme @"http"
#define BDXHttpsScheme @"https"

@BDXSERVICE_REGISTER(BDXSchema)

    @implementation BDXSchema

+ (BDXServiceScope)serviceScope
{
    return BDXServiceScopeGlobalDefault;
}

+ (BDXServiceType)serviceType
{
    return BDXServiceTypeSchema;
}

+ (NSString *)serviceBizID
{
    return DEFAULT_SERVICE_BIZ_ID;
}

+ (nullable BDXSchemaParam *)resolverWithSchema:(NSURL *)originURL contextInfo:(BDXContext *)contextInfo;
{
    return [BDXSchema resolverWithSchema:originURL contextInfo:contextInfo paramClass:BDXSchemaParam.class];
}

+ (nullable BDXSchemaParam *)resolverWithSchema:(NSURL *)originURL contextInfo:(nullable BDXContext *)contextInfo paramClass:(Class)cls
{
    if (![cls isSubclassOfClass:BDXSchemaParam.class]) {
        return nil;
    }

    [self trackLifeCycleEvent:@"xschema_will_resolve_url" withParam:contextInfo];

    if ([self __shouldInterceptSchema:originURL]) {
        BDXSchema *resolver = [BDXSchema new];
        NSMutableDictionary *extra = [[originURL btd_queryItemsWithDecoding] mutableCopy];
        BDXSchemaParam *param = (BDXSchemaParam *)[cls paramWithDictionary:extra];

        param.resolvedURL = [resolver __resolveToBulletSchema:originURL extra:extra];
        param.originURL = originURL;

        extra[@"resolvedURL"] = param.resolvedURL;
        extra[@"originURL"] = param.originURL;

        BDXSchemaParam *oldParam = [contextInfo getObjForKey:kBDXContextKeySchemaParams];
        if (oldParam) {
            // params inherit
            [oldParam updateWithParam:param];
        } else {
            oldParam = param;
        }

        [contextInfo registerStrongObj:oldParam forKey:kBDXContextKeySchemaParams];

        [self trackLifeCycleEvent:@"xschema_did_resolve_url" withParam:contextInfo];
        
        [self triggerPrefetchIfNeeded:oldParam contextInfo:contextInfo];
        
        return oldParam;
    }

    return nil;
}

+ (void)triggerPrefetchIfNeeded:(BDXSchemaParam *)param contextInfo:(nullable BDXContext *)contextInfo
{
    NSString *businessString = [contextInfo getObjForKey:kBDXContextKeyPrefetchBusiness];
    NSString *prefetchSchema = [self prefetchUrlWithSchema:param.originURL];
    if (!BTD_isEmptyString(businessString) && !BTD_isEmptyString(prefetchSchema)) {
        [[[IESPrefetchManager sharedInstance] loaderForBusiness:businessString] prefetchForSchema:prefetchSchema withVariable:nil];
        [self registerPrefetchInitDataIfNeeded:businessString prefetchSchema:prefetchSchema contextInfo:contextInfo];
    }
}

+ (void)registerPrefetchInitDataIfNeeded:(NSString *)business prefetchSchema:(NSString *)prefetchSchema contextInfo:(nullable BDXContext *)contextInfo
{
    NSDictionary<NSString *, IESPrefetchCacheModel *> *cachedDatas = [[[IESPrefetchManager sharedInstance] loaderForBusiness:business] currentCachedDatasByUrl:prefetchSchema];
    if (cachedDatas.count == 0) {
        return;
    }
    NSMutableDictionary *tempData = [NSMutableDictionary new];
    NSMutableArray *tempArray = [NSMutableArray new];
    [cachedDatas enumerateKeysAndObjectsUsingBlock:^(NSString *key, IESPrefetchCacheModel *obj, BOOL *stop) {
        if (key.length > 0 && ![obj hasExpired] && [obj.data isKindOfClass:NSDictionary.class]) {
            tempData[key] = obj.data;
            [tempArray addObject:key];
        }
    }];
    if (tempData.count > 0) {
        [contextInfo registerStrongObj:@{@"prefetchInitData":[tempData copy]?:@{}} forKey:kBDXContextKeyPrefetchInitData];
        [self prefetchMonitor:prefetchSchema apis:[tempArray componentsJoinedByString:@","]];
    }
}

+ (void)prefetchMonitor:(NSString *)prefetchSchema apis:(NSString *)apis
{
    NSURLComponents *tempComponents = [NSURLComponents componentsWithString:prefetchSchema];
    tempComponents.query = nil;
    NSString *url = tempComponents.URL.absoluteString;
    if (url.length == 0) {
        return;
    }
    id<BDXMonitorProtocol> monitor = BDXSERVICE(BDXMonitorProtocol, nil);
    [monitor reportWithEventName:@"bdx_monitor_prefetch_data" bizTag:nil commonParams:@{
        @"url": url ?: @""
    } metric:nil category:@{
        @"prefetch_state": @"success",
        @"prefetch_cached": @"3",/// 3: 启动插入
        @"prefetch_init_data_apis" : apis ?: @"unknown",
    } extra:nil platform:BDXMonitorReportPlatformLynx aid:@"" maySample:YES];
}

+ (NSString *)prefetchUrlWithSchema:(NSURL *)schema
{
    /// 规则见 https://bytedance.feishu.cn/docs/doccnu2bmUNcZtaYiZ7BgaDsQXc
    if ([schema isKindOfClass:NSURL.class]) {
        NSMutableDictionary *extra = [[schema btd_queryItemsWithDecoding] mutableCopy];
        if ([schema.host containsString:@"lynx"]) {
            NSString *channelTmp = extra[@"channel"];
            NSString *bundleTmp = extra[@"bundle"];
            if (!BTD_isEmptyString(channelTmp) && !BTD_isEmptyString(bundleTmp)) {
                NSURL *tempUrl = [NSURL URLWithString:[NSString stringWithFormat:@"lynxview://prefetch/%@/%@", channelTmp, bundleTmp]];
                [extra removeObjectForKey:@"channel"];
                [extra removeObjectForKey:@"bundle"];
                tempUrl = [tempUrl btd_URLByMergingQueries:extra];
                return tempUrl.absoluteString;
            } else {
                NSString *tempString = extra[@"surl"];
                if (!BTD_isEmptyString(tempString)) {
                    [extra removeObjectForKey:@"surl"];
                }
                if (BTD_isEmptyString(tempString)) {
                    /// surl为空 再尝试取下url
                    tempString = extra[@"url"];
                    if (!BTD_isEmptyString(tempString)) {
                        [extra removeObjectForKey:@"url"];
                    }
                }
                if (!BTD_isEmptyString(tempString)) {
                    NSURL *tempUrl = [NSURL URLWithString:tempString];
                    if (tempUrl) {
                        tempUrl = [tempUrl btd_URLByMergingQueries:extra];
                        return tempUrl.absoluteString;
                    }
                }
            }
        } else {
            NSString *tempString = extra[@"url"];
            if (!BTD_isEmptyString(tempString)) {
                [extra removeObjectForKey:@"url"];
            }
            if (!BTD_isEmptyString(tempString)) {
                NSURL *tempUrl = [NSURL URLWithString:tempString];
                if (tempUrl) {
                    tempUrl = [tempUrl btd_URLByMergingQueries:extra];
                    return tempUrl.absoluteString;
                }
            }
        }
        return nil;
    }
    return nil;
}

+ (NSDictionary *)extractURLDetail:(NSString *)urlString withPrefix:(NSString *)prefix
{
    NSString *urlPath = [[NSURL URLWithString:urlString] path];
    NSError *error;
    NSString *pattern = [NSString stringWithFormat:@"%@/((\\w+)/(.*))", prefix];
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:kNilOptions error:&error];
    if (error || BTD_isEmptyString(urlPath)) {
        return nil;
    }
    NSTextCheckingResult *result = [regexp firstMatchInString:urlPath options:kNilOptions range:NSMakeRange(0, urlPath.length)];
    NSString *channel = nil;
    NSString *bundlePathString = nil;

    if (result) {
        if (result.numberOfRanges > 3) {
            channel = [urlPath substringWithRange:[result rangeAtIndex:2]];
            bundlePathString = [urlPath substringWithRange:[result rangeAtIndex:3]];
        }
    }
    if (BTD_isEmptyString(channel) || BTD_isEmptyString(bundlePathString)) {
        return nil;
    }

    return @{@"channel": channel, @"bundle": bundlePathString};
}

#pragma mark - private

+ (BOOL)__shouldInterceptSchema:(NSURL *)originURL
{
    if (!originURL) {
        return NO;
    }

    NSURL *url = originURL;
    NSString *localScheme = @"aweme";
    NSString *outerScheme = @"snssdk";
    NSString *generalScheme = @"sslocal";

    NSArray *supportedHosts = @[@"lynxview", @"lynx_page", @"lynxview_popup", @"lynx_popup", @"webview", @"webview_popup"];
    // schema host check
    if (([url.scheme isEqualToString:localScheme] || [url.scheme hasPrefix:outerScheme] || [url.scheme hasPrefix:generalScheme]) && ([supportedHosts containsObject:url.host])) {
        NSDictionary *queries = [url btd_queryItemsWithDecoding];
        return [self __schemaQueryWithUrlStyle:queries] || [self __schemaQueryWithChannelStyle:queries];
    }

    // webview
    if ([url.scheme isEqualToString:BDXHttpScheme] || [url.scheme isEqualToString:BDXHttpsScheme]) {
        return YES;
    }

    return NO;
}

/// e.g.: aweme://lynxview?url=encoded(`https://xxxxx`)
+ (BOOL)__schemaQueryWithUrlStyle:(NSDictionary *)queries
{
    return [queries btd_stringValueForKey:@"url"].length > 0 || [queries btd_stringValueForKey:@"surl"].length > 0 || [queries btd_stringValueForKey:@"fallback_url"].length > 0;
}

/// e.g.: aweme://lynxview?channel=xxx&bundle=yyy.js
+ (BOOL)__schemaQueryWithChannelStyle:(NSDictionary *)queries
{
    return [queries btd_stringValueForKey:@"channel"].length > 0 && [queries btd_stringValueForKey:@"bundle"].length > 0;
}

/// e.g.:
/// aweme://lynxview?url=encoded(`https://snssdk.com/obj/tc2021/channel/bundle.js`)&key1=value1
/// ->bullet://bullet
/// encoded(`https://snssdk.com/obj/tc2021/channel/bundle.js`)&key1=value1
- (NSURL *)__resolveToBulletSchema:(NSURL *)originURL extra:(NSMutableDictionary *)extra
{
    NSDictionary *queries = [originURL btd_queryItemsWithDecoding];
    NSURL *result;
    if ([originURL.scheme isEqualToString:BDXHttpScheme] || [originURL.scheme isEqualToString:BDXHttpsScheme]) {
        result = [self __resolveHttpStyleToBulletSchema:originURL withQueries:queries];
    }

    if ([[self class] __schemaQueryWithUrlStyle:queries]) {
        result = [self __resolveURLStyleToBulletSchema:originURL withQueries:queries];
    } else if ([[self class] __schemaQueryWithChannelStyle:queries]) {
        result = [self __resolveChannelStyleToBulletSchema:originURL withQueries:queries];
        extra[@"surl"] = result.absoluteString;
    }

    NSString *schema = @"bullet://bullet";
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"url"] = result.absoluteString;

    NSString *bulletSchema = [self bullet_stringByAddingQueryDict:schema withDict:[dict copy]];
    return [NSURL URLWithString:bulletSchema];
}

- (NSURL *)__resolveHttpStyleToBulletSchema:(NSURL *)originURL withQueries:(NSDictionary *)queries
{
    NSString *httpUrl = originURL.absoluteString;

    NSMutableDictionary *schemaQuery = [NSMutableDictionary new];

    [schemaQuery addEntriesFromDictionary:queries];
    if (![schemaQuery objectForKey:@"url"]) {
        // add url
        schemaQuery[@"url"] = httpUrl;
    }

    NSURL *resolved = originURL;
    return resolved;
}

- (NSURL *)__resolveChannelStyleToBulletSchema:(NSURL *)originURL withQueries:(NSDictionary *)queries
{
    NSString *channel = [queries btd_stringValueForKey:@"channel"];
    NSString *bundle = [queries btd_stringValueForKey:@"bundle"];

    NSString *baseURL = [NSString stringWithFormat:@"lynxview://xxx?channel=%@&bundle=%@", channel, bundle];

    NSMutableDictionary *lynxQuery = [NSMutableDictionary new];
    [lynxQuery addEntriesFromDictionary:queries];
    [lynxQuery removeObjectForKey:@"channel"];
    [lynxQuery removeObjectForKey:@"bundle"];
    NSURL *resolved = [NSURL btd_URLWithString:baseURL queryItems:[lynxQuery copy]];
    return resolved;
}

- (NSURL *)__resolveURLStyleToBulletSchema:(NSURL *)originURL withQueries:(NSDictionary *)queries
{
    // lynx
    if ([originURL.host containsString:@"lynx"]) {
        NSString *lynxUrl = [queries btd_stringValueForKey:@"surl"];
        if (!lynxUrl) {
            lynxUrl = [queries btd_stringValueForKey:@"url"];
        }
        
        if(!lynxUrl) {
            lynxUrl = [queries btd_stringValueForKey:@"fallback_url"];
        }

        NSMutableDictionary *lynxQuery = [NSMutableDictionary new];
        //// 没有对应的gecko资源才拼接surl
        lynxQuery[@"surl"] = lynxUrl;
        [lynxQuery addEntriesFromDictionary:queries];
        [lynxQuery removeObjectForKey:@"url"];
        NSString *baseUrl = @"lynxview://channel/bundle.js";
        NSURL *resolved = [NSURL btd_URLWithString:baseUrl queryItems:[lynxQuery copy]];
        return resolved;
    }
    // webview
    else if ([originURL.host containsString:@"webview"]) {
        NSString *baseUrl = @"webview://";
        NSURL *resolved = [NSURL btd_URLWithString:baseUrl queryItems:queries];
        return resolved;
    }

    // not match
    return originURL;
}

// TODO : bytedance kit
- (NSString *)bullet_stringByAddingQueryDict:(NSString *)str withDict:(NSDictionary<NSString *, NSString *> *)dict
{
    if (!dict) {
        return str;
    }

    NSMutableArray<NSString *> *params = [NSMutableArray array];
    [dict enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        if ([key isKindOfClass:NSString.class]) {
            NSString *stringValue = nil;
            if ([obj isKindOfClass:NSString.class]) {
                stringValue = obj;
            } else if ([obj isKindOfClass:NSNumber.class]) {
                stringValue = [(NSNumber *)obj stringValue];
            }

            if (stringValue) {
                [params btd_addObject:[NSString stringWithFormat:@"%@=%@", [self bullet_stringByAddingPercentEscapes:key], [self bullet_stringByAddingPercentEscapes:stringValue]]];
            }
        }
    }];

    NSString *paramString = [params componentsJoinedByString:@"&"];
    if ([str containsString:@"?"]) {
        return [NSString stringWithFormat:@"%@&%@", str, paramString];
    }

    return [NSString stringWithFormat:@"%@?%@", str, paramString];
}

// TODO : bytedance kit
- (NSString *)bullet_stringByAddingPercentEscapes:(NSString *)str
{
    static NSMutableCharacterSet *allowSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allowSet = [NSMutableCharacterSet characterSetWithCharactersInString:@""];
        [allowSet formUnionWithCharacterSet:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [allowSet removeCharactersInString:@":!*();@/&?+$,='"];
    });

    return [str stringByAddingPercentEncodingWithAllowedCharacters:allowSet];
}

#pragma mark - life cycle monitor

+ (void)trackLifeCycleEvent:(NSString *)event withParam:(BDXContext *)context
{
    id<BDXMonitorProtocol> tracker = [context getObjForKey:@"lifeCycleTracker"];
    [tracker trackLifeCycleWithEvent:event];
}

@end
