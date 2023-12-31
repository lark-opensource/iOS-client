//
//  TMAPluginNetworkTools.m
//  Timor
//
//  Created by changrong on 2020/9/17.
//

#import "TMAPluginNetworkTools.h"
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/ECOConfigService.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/BDPUtils.h>

NSString * const kTMAPluginNetworkMultipartCRLF = @"\r\n";

@implementation TMAPluginNetworkTools

+ (NSData *)multipartBodyWithName:(NSString *)name
    boundary:(NSString *)boundary
     fileName:(NSString *)fileName
     fileData:(NSData *)fileData
otherFormData:(NSDictionary *)otherFormData
{
    NSMutableData *data = [NSMutableData data];
    [otherFormData enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        TMAMultipartFormData(data, [NSString stringWithFormat:@"--%@", boundary]);
        TMAMultipartFormData(data, kTMAPluginNetworkMultipartCRLF);
        TMAMultipartFormData(data, [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"", key]);
        TMAMultipartFormData(data, kTMAPluginNetworkMultipartCRLF);
        TMAMultipartFormData(data, kTMAPluginNetworkMultipartCRLF);
        TMAMultipartFormData(data, obj);
        TMAMultipartFormData(data, kTMAPluginNetworkMultipartCRLF);
    }];
    
    TMAMultipartFormData(data, [NSString stringWithFormat:@"--%@", boundary]);
    TMAMultipartFormData(data, kTMAPluginNetworkMultipartCRLF);
    TMAMultipartFormData(data, [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"", name, fileName]);
    TMAMultipartFormData(data, kTMAPluginNetworkMultipartCRLF);
    TMAMultipartFormData(data, [NSString stringWithFormat:@"Content-Type: %@", [self mimeTypeForData:fileData]]);
    TMAMultipartFormData(data, kTMAPluginNetworkMultipartCRLF);
    TMAMultipartFormData(data, kTMAPluginNetworkMultipartCRLF);
    [data appendData:fileData];
    TMAMultipartFormData(data, kTMAPluginNetworkMultipartCRLF);
    TMAMultipartFormData(data, [NSString stringWithFormat:@"--%@--", boundary]);
    return data;
}


static inline void TMAMultipartFormData(NSMutableData *data, NSString *str)
{
    [data appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSString *)mimeTypeForData:(NSData *)data
{
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
            break;
        case 0x89:
            return @"image/png";
            break;
        case 0x47:
            return @"image/gif";
            break;
        case 0x49:
        case 0x4D:
            return @"image/tiff";
            break;
        case 0x25:
            return @"application/pdf";
            break;
        case 0xD0:
            return @"application/vnd";
            break;
        case 0x46:
            return @"text/plain";
            break;
        default:
            return @"application/octet-stream";
    }
    return nil;
}

#pragma mark - tt.request header monitor
+ (NSString *)monitorValueForUniqueID:(nullable OPAppUniqueID *)uniqueID requestHeader:(NSDictionary<NSString *,NSString *> *)header {
    NSArray<NSString *> *targetKeys = [self targetHeaderKeysForUniqueID:uniqueID configKey:@"request_header_keys"];
    if (BDPIsEmptyArray(targetKeys)) {
        return @"";
    }
    return [self monitorValueForHeader:header targetKeys:targetKeys];
}

+ (NSString *)monitorValueForUniqueID:(nullable OPAppUniqueID *)uniqueID responseHeader:(NSDictionary<NSString *,NSString *> *)header {
    NSArray<NSString *> *targetKeys = [self targetHeaderKeysForUniqueID:uniqueID configKey:@"response_header_keys"];
    if (BDPIsEmptyArray(targetKeys)) {
        return @"";
    }
    return [self monitorValueForHeader:header targetKeys:targetKeys];
}

+ (NSString *)monitorValueForHeader:(NSDictionary<NSString *, NSString *> *)header targetKeys:(NSArray<NSString *> *)targetKeys {
    NSMutableDictionary<NSString *, NSString*> *result = [NSMutableDictionary dictionary];
    for (NSString *key in header) {
        if (![targetKeys containsObject:key.lowercaseString]) {
            continue;
        }
        NSString *value = [header bdp_stringValueForKey:key];
        if (!value) {
            BDPLogError(@"tt.reqeust header value is nil for key: %@", key);
            continue;
        }
        NSString *maskValue = [self maskHeaderValue:value withKey:key];
        [result setObject:maskValue forKey:key];
    }
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:result options:0 error:&error];
    if (!data || error) {
        BDPLogError(@"serialize tt.request header failed, error: %@", error);
        return @"";
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

/// 对 header 的 value 做掩码操作，屏蔽敏感信息
+ (NSString *)maskHeaderValue:(NSString *)value withKey:(NSString *)key {
    /// cookie 的我们选择特殊处理
    if ([key.lowercaseString isEqualToString:@"cookie"]) {
        return [self cookieMaskValueForOrigin:value];
    }
    if ([key.lowercaseString isEqualToString:@"set-cookie"]) {
        return [self cookieMaskValueForOrigin:value];
    }

    return [value reuseCacheMask];
}

+ (NSString *)cookieMaskValueForOrigin:(NSString *)origin {
    NSMutableString *result = [NSMutableString string];

    /// 先根据「;」切分成 componment
    NSArray<NSString *> *cookieComponments = [origin componentsSeparatedByString:@";"];
    for (NSString *componment in cookieComponments) {
        /// 再根据「=」切分 key/value
        NSArray<NSString *> *cookiePair = [componment componentsSeparatedByString:@"="];

        /// 每次循环如果非空则补上「;」
        if (!BDPIsEmptyString(result)) {
            [result appendString:@";"];
        }

        /// Cookie https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie
        if (cookiePair.count == 1) {                     /// 「Secure」「HttpOnly」等
            if ([@[@"secure", @"httponly"] containsObject:cookiePair[0].lowercaseString]) {
                [result appendString:cookiePair[0]];
            } else {
                [result appendString:[cookiePair[0] reuseCacheMask]];
            }
        } else if (cookiePair.count == 2) {              /// 「key=value」,「Domain=xxx」,「Expires=xxx」,「Path=xxx」,「SameSite=xxx」等
            if ([@[@"domain", @"expires", @"samesite"] containsObject:cookiePair[0].lowercaseString]) {
                [result appendFormat:@"%@=%@", cookiePair[0], cookiePair[1]];
            } else if ([cookiePair[0].lowercaseString isEqualToString:@"path"]) {
                [result appendFormat:@"%@=%@", cookiePair[0], [cookiePair[1] reuseCacheMaskWithExcept:@"-_/."]];
            } else {
                [result appendFormat:@"%@=%@", [cookiePair[0] reuseCacheMask], [cookiePair[1] reuseCacheMask]];
            }
        } else {                                         /// 其他 case，默认掩码拼接 componment, 不再特殊处理
            [result appendString:[componment reuseCacheMask]];
        }
    }
    return [result copy];
}

/// 通过 uniqueID 和 configKey 从下发配置中过滤出需要上报埋点的 header key
+ (NSArray<NSString *> *)targetHeaderKeysForUniqueID:(nullable OPAppUniqueID *)uniqueID configKey:(NSString *)configKey {
    id<ECOConfigService> service = [ECOConfig service];
    NSDictionary<NSString *, id> *config = [service getDictionaryValueForKey:@"tt_request_header_monitor"];
    if (!config) {
        BDPLogWarn(@"get tt_request_header_monitor config failed.");
        return @[];
    }
    NSMutableArray<NSString *> *targetKeys = [NSMutableArray array];

    /// 默认 header keys 配置
    NSDictionary<NSString *, id> *defaultConfig = [config bdp_dictionaryValueForKey:@"default_header_keys"];
    NSArray<NSString *> *defaultHeaderKeys = [defaultConfig bdp_arrayValueForKey:configKey];
    if (defaultHeaderKeys) {
        [targetKeys addObjectsFromArray:defaultHeaderKeys];
    }

    if (!uniqueID) {
        return [targetKeys copy];
    }

    /// app header keys 配置
    NSDictionary<NSString *, id> *headerConfig = [config bdp_dictionaryValueForKey:@"header_keys"];
    NSDictionary<NSString *, id> *appHeaderConfig = [headerConfig bdp_dictionaryValueForKey:uniqueID.appID];
    NSArray<NSString *> *headerKeys = [appHeaderConfig bdp_arrayValueForKey:configKey];
    if (headerKeys) {
        [targetKeys addObjectsFromArray:headerKeys];
    }

    return [targetKeys copy];
}

@end
