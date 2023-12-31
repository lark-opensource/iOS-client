//
//  BDPSchemaCodec.m
//  Timor
//
//  Created by liubo on 2019/4/11.
//

#import "BDPSchemaCodec.h"
#import "BDPUtils.h"
#import "BDPTimorClient.h"
#import "EEFeatureGating.h"

#import "BDPSchema+Private.h"
#import <ECOInfra/NSString+BDPExtension.h>
#import "BDPSchemaCodec+Private.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>

#import "OPAppVersionType.h"

#define kBDPSchemaCodecDefaultProtocol  @"sslocal"

#define kBDPSchemaKeySchemaVersion  @"version"
#define kBDPSchemaKeyBDPSum         @"bdpsum"

#define kBDPSchemaKeyAppID          @"app_id"
#define kBDPSchemaKeyIdentifier     @"identifier"
#define kBDPSchemaKeyInstanceID     @"instance_id"
#define kBDPSchemaKeyVersionType    @"version_type"
#define kBDPSchemaKeyToken          @"token"

#define kBDPSchemaKeyMeta           @"meta"

#define kBDPSchemaKeyStartPage      @"start_page"
#define kBDPSchemaKeyQuery          @"query"        // 极少量被用到

#define kBDPSchemaKeyScene          @"scene"
#define kBDPSchemaKeyBDPLog         @"bdp_log"    // 没有用到
#define kBDPSchemaKeyGdExt          @"gd_ext_json"  // 没有用到

#define kBDPSchemaKeyRefererInfo    @"refererInfo"

#define kBDPSchemaKeyLaunchMode     @"launch_mode" // 没有用到
#define kBDPSchemaKeyInspect        @"inspect" // 没有用到

#define kBDPSchemaKeyPath           @"path" //该key并未被使用,暂时作为保留key

#define kBDPSchemaKeyXScreenMode    @"mode"
#define kBDPSchemaKeyXScreenPresentationStyle    @"panel_style"
#define kBDPSchemaKeyXScreenCharID    @"chat_id"

NSString * const kBDPSchemaKeyWSForDebug = @"ws_for_debug";  // 真机调试 web socket 地址

#define kBDPIdeDisableDomainCheck   @"ide_disable_domain_check"  // web-view安全域名调试

#define kBDPSchemaAllKeysArray      @[kBDPSchemaKeySchemaVersion, kBDPSchemaKeyBDPSum, kBDPSchemaKeyAppID, kBDPSchemaKeyIdentifier, \
                                    kBDPSchemaKeyInstanceID, kBDPSchemaKeyVersionType, \
                                    kBDPSchemaKeyToken, kBDPSchemaKeyMeta, kBDPSchemaKeyStartPage, kBDPSchemaKeyQuery, \
                                    kBDPSchemaKeyScene, kBDPSchemaKeyBDPLog, kBDPSchemaKeyRefererInfo, \
                                    kBDPSchemaKeyLaunchMode, kBDPSchemaKeyInspect, kBDPSchemaKeyPath, kBDPSchemaKeyWSForDebug, kBDPIdeDisableDomainCheck, \
                                    kBDPSchemaKeyXScreenMode, kBDPSchemaKeyXScreenPresentationStyle]

#pragma mark - BDPSchemaCodecError

NSString * const BDPSchemaCodecErrorDomain = @"BDPSchemaCodecErrorDomain";

//#pragma mark - BDPSchemaBDPLogKey

NSString * const BDPSchemaBDPLogKeyLaunchFrom = @"launch_from";
NSString * const BDPSchemaBDPLogKeyTtid = @"ttid";
NSString * const BDPSchemaBDPLogKeyLocation = @"location";
NSString * const BDPSchemaBDPLogKeyBizLocation = @"biz_location";
NSString * const BDPSchemaBDPLogKeyOriginEntrance = @"origin_entrance";

#pragma mark - BDPSchemaCodecOptions

@interface BDPSchemaCodecOptions ()
@property (nonatomic, copy) NSString *schemaVersion;
@end

@implementation BDPSchemaCodecOptions

- (instancetype)init {
    if (self = [super init]) {
        [self buildSchemaCodecOptions];
    }
    return self;
}

- (void)buildSchemaCodecOptions {
    self.schemaVersion = BDPSchemaVersionV02;
    self.protocol = kBDPSchemaCodecDefaultProtocol;
    self.host = SCHEMA_APP;
    self.versionType = OPAppVersionTypeCurrent;
}

- (NSMutableDictionary<NSString *,id> *)meta {
    if (_meta == nil) {
        _meta = [[NSMutableDictionary alloc] init];
    }
    return _meta;
}

- (NSMutableDictionary<NSString *,id> *)bdpLog {
    if (_bdpLog == nil) {
        _bdpLog = [[NSMutableDictionary alloc] init];
    }
    return _bdpLog;
}

- (NSMutableDictionary<NSString *,id> *)query {
    if (_query == nil) {
        _query = [[NSMutableDictionary alloc] init];
    }
    return _query;
}

- (NSMutableDictionary<NSString *,id> *)inspect {
    if (_inspect == nil) {
        _inspect = [[NSMutableDictionary alloc] init];
    }
    return _inspect;
}

- (NSMutableDictionary<NSString *,id> *)customFields {
    if (_customFields == nil) {
        _customFields = [[NSMutableDictionary alloc] init];
    }
    return _customFields;
}

- (NSMutableDictionary<NSString *,id> *)refererInfoDictionary {
    if (_refererInfoDictionary == nil) {
        _refererInfoDictionary = [[NSMutableDictionary alloc] init];
    }
    return _refererInfoDictionary;
}

- (BOOL)compareString:(NSString *)stringA withString:(NSString *)stringB {

    if (BDPIsEmptyString(stringA) && BDPIsEmptyString(stringB)) return YES;
    else if (BDPIsEmptyString(stringA) && !BDPIsEmptyString(stringB)) return NO;
    else if (!BDPIsEmptyString(stringA) && BDPIsEmptyString(stringB)) return NO;
    else return [stringA isEqualToString:stringB];

}

- (BOOL)compareDictionary:(NSDictionary *)dicA withDictionary:(NSDictionary *)dicB {
    if (dicA == nil && dicB == nil) return YES;
    else if (dicA == nil && dicB != nil) return NO;
    else if (dicA != nil && dicB == nil) return NO;
    else return [dicA isEqualToDictionary:dicB];
}

- (BOOL)isEqualToOption:(BDPSchemaCodecOptions *)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    if (![self compareString:self.schemaVersion withString:object.schemaVersion]) return NO;
    
    if (![self compareString:self.protocol withString:object.protocol]) return NO;
    if (![self compareString:self.host withString:object.host]) return NO;
    
    if (![self compareString:self.appID withString:object.appID]) return NO;
    

    if (![self compareString:self.identifier withString:object.identifier]) {
        if (BDPIsEmptyString(self.identifier) && [object.identifier isEqualToString:object.appID]) {
            // 这种算作 identifier 缺省等于 appID
        } else if (BDPIsEmptyString(object.identifier) && [self.identifier isEqualToString:self.appID]) {
            // 这种算作 identifier 缺省等于 appID
        } else {
            return NO;
        }
    }

    if (![self compareString:self.instanceID withString:object.instanceID]) return NO;
    if (self.versionType != object.versionType) return NO;
    if (![self compareString:self.token withString:object.token]) return NO;
    
    if (![self compareDictionary:self.meta withDictionary:object.meta]) return NO;
    
    if (![self compareString:self.scene withString:object.scene]) return NO;
    if (![self compareDictionary:self.bdpLog withDictionary:object.bdpLog]) return NO;
    
    if (![self compareString:self.path withString:object.path]) return NO;
    if (![self compareDictionary:self.query withDictionary:object.query]) return NO;
    
    if (![self compareString:self.launchMode withString:object.launchMode]) return NO;
    if (![self compareDictionary:self.inspect withDictionary:object.inspect]) return NO;
    
    if (![self compareDictionary:self.customFields withDictionary:object.customFields]) return NO;
    
    if (![self compareDictionary:self.refererInfoDictionary withDictionary:object.refererInfoDictionary]) return NO;
    
    if (![self compareString:self.fullquery withString:object.fullquery]) return NO;
    if (![self compareString:self.fullStartPage withString:object.fullStartPage]) return NO;
    
    return YES;
}

@end

#pragma mark - BDPSchemaCodec

@implementation BDPSchemaCodec

#pragma mark - Public Interface

+ (BDPSchemaCodecOptions *)schemaCodecOptionsFromURL:(NSURL *)url error:(NSError **)error {
    //创建空白 BDPSchemaCodecOptions
    BDPSchemaCodecOptions *resultCodecOption = [[BDPSchemaCodecOptions alloc] init];
    
    //URL 无效
    if (url == nil || [url isKindOfClass:[NSURL class]] == NO) {
        NSError *err = [BDPSchemaCodec errorWithErrorCode:BDPSchemaCodecErrorInvalidURL invalidValue:nil];
        [resultCodecOption setError:err];
        if (error) {
            *error = err;
        }
        return resultCodecOption;
    }
    
    //URL 为空
    NSString *urlString = [url absoluteString];
    if (BDPIsEmptyString(urlString)) {
        NSError *err = [BDPSchemaCodec errorWithErrorCode:BDPSchemaCodecErrorInvalidURL invalidValue:nil];
        [resultCodecOption setError:err];
        if (error) {
            *error = err;
        }
        return resultCodecOption;
    }
    
    //拆分schema字符串,会将query中所有的value进行一次decode
    __block NSDictionary *queryParams = nil;
    [BDPSchemaCodec separateProtocolHostAndParams:urlString syncResultBlock:^(NSString *protocol, NSString *host, NSString *fullHost, NSDictionary *params) {
        [resultCodecOption setProtocol:protocol];
        [resultCodecOption setHost:host];
        queryParams = params;
    }];
    
    if (!BDPIsEmptyDictionary(queryParams)) {
        //2019.10.30 对齐Android编解码类不校验bdpsum
//        NSString *schemaVersionString = [queryParams bdp_stringValueForKey:kBDPSchemaKeySchemaVersion];
//        if ([schemaVersionString isEqualToString:BDPSchemaVersionV02]) {
//            NSString *sumString = [queryParams bdp_stringValueForKey:kBDPSchemaKeyBDPSum];
//            if (BDPIsEmptyString(sumString)) {
//                if (error) {
//                    *error = [BDPSchemaCodec errorWithErrorCode:BDPSchemaCodecErrorEmptyCheck invalidValue:nil];
//                }
//                return nil;
//            }
//
//            BOOL checkResult = [BDPSchemaCodec checkSumForSchemaString:urlString sumString:sumString version:schemaVersionString];
//            if (!checkResult) {
//                if (error) {
//                    *error = [BDPSchemaCodec errorWithErrorCode:BDPSchemaCodecErrorIllegalCheck invalidValue:sumString];
//                }
//                return nil;
//            }
//        }
        
        //1.appid & versionType & token
        [resultCodecOption setAppID:[queryParams bdp_stringValueForKey:kBDPSchemaKeyAppID]];
        [resultCodecOption setIdentifier:[queryParams bdp_stringValueForKey:kBDPSchemaKeyIdentifier]];
        [resultCodecOption setInstanceID:[queryParams bdp_stringValueForKey:kBDPSchemaKeyInstanceID]];
        [resultCodecOption setVersionType:OPAppVersionTypeFromString([queryParams bdp_stringValueForKey:kBDPSchemaKeyVersionType])];
        [resultCodecOption setToken:[queryParams bdp_stringValueForKey:kBDPSchemaKeyToken]];
        
        //2.meta
        NSDictionary *metaDic = [[queryParams bdp_stringValueForKey:kBDPSchemaKeyMeta] JSONValue];
        if (!BDPIsEmptyDictionary(metaDic)) {
            [resultCodecOption.meta addEntriesFromDictionary:metaDic];
        }
        
        //3.scene & bdpLog
        [resultCodecOption setScene:[queryParams bdp_stringValueForKey:kBDPSchemaKeyScene]];
        NSDictionary *bdpLogDic = [[queryParams bdp_stringValueForKey:kBDPSchemaKeyBDPLog] JSONValue];
        if (!BDPIsEmptyDictionary(bdpLogDic)) {
            [resultCodecOption.bdpLog addEntriesFromDictionary:bdpLogDic];
        }
        
        /*
         FG: openplatform.gadget.relaunch 支持relaunch参数
         relaunch参数和path参数需要配套使用
         在执行热启动时，执行relaunch，relaunch的url为path的参数
         
         iOS在容器启动过程中，进行relaunch操作存在潜在风险，所以增加了降级能力
         FG: openplatform.gadget.relaunchdowngrade 对 上面功能的降级
         将热启动转变成冷启动
         
         备注: 两个开关理论上需要互斥，不过开启降级之后就不会进入热启动流程，相当于只开启降级
         */
        // 如果存在relaunch且为true,那么由path(kBDPSchemaKeyRelaunchWhileLaunchingPath)参数替代start_page(kBDPSchemaKeyStartPage)
        NSString *pathParamKey = kBDPSchemaKeyStartPage;
        if ([EEFeatureGating boolValueForKey:@"openplatform.gadget.relaunch"] || [EEFeatureGating boolValueForKey:@"openplatform.gadget.relaunchdowngrade"]) {
            // 解析强制冷启动参数
            BOOL relaunchWhileLaunching= [queryParams bdp_boolValueForKey2:kBDPSchemaKeyRelaunchWhileLaunching];
            [resultCodecOption setRelaunchWhileLaunching:relaunchWhileLaunching];
            if (relaunchWhileLaunching) {
                pathParamKey = kBDPSchemaKeyRelaunchWhileLaunchingPath;
            }
        }
        
        //4.startPage & query
        /// sslocal://microapp?app_id=aaa&start_page=encode({path}?{k1=encode(v1)&k2=encode(v2)})
        NSString *startPage = [queryParams bdp_stringValueForKey:pathParamKey];
        [BDPSchemaCodec separatePathAndQuery:startPage syncResultBlock:^(NSString *path, NSString *query, NSDictionary *queryDictionary) {
            [resultCodecOption setPath:path];
            NSMutableDictionary *decodeQueryDic = [[NSMutableDictionary alloc] init];
            [queryDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSString * value, BOOL * _Nonnull stop) {
                id resultObj = [BDPSchemaCodec objForJSONRepresentation:[value URLDecodedString]];
                if (resultObj != nil) {
                    [decodeQueryDic setValue:resultObj forKey:key];
                }
            }];
            if (!BDPIsEmptyDictionary(decodeQueryDic)) {
                [resultCodecOption.query addEntriesFromDictionary:decodeQueryDic];
            }
        }];
        resultCodecOption.fullStartPageDecoded = startPage;
        
        //5.referreInfo
        [resultCodecOption setRefererInfoDictionary:[[queryParams bdp_stringValueForKey:kBDPSchemaKeyRefererInfo] JSONValue]];
        
        //6.launch_mode & inspect
        [resultCodecOption setLaunchMode:[queryParams bdp_stringValueForKey:kBDPSchemaKeyLaunchMode]];
        NSDictionary *inspectDic = [[queryParams bdp_stringValueForKey:kBDPSchemaKeyInspect] JSONValue];
        if (!BDPIsEmptyDictionary(inspectDic)) {
            [resultCodecOption.inspect addEntriesFromDictionary:inspectDic];
        }
        
        //7.Xscreen mode &presetation height
        [resultCodecOption setXScreenMode:[queryParams bdp_stringValueForKey:kBDPSchemaKeyXScreenMode]];
        [resultCodecOption setXScreenPresentationStyle:[queryParams bdp_stringValueForKey:kBDPSchemaKeyXScreenPresentationStyle]];
        [resultCodecOption setChatID:[queryParams bdp_stringValueForKey:kBDPSchemaKeyXScreenCharID]];
        
        //8.customDic(重复的key将忽略)
        NSArray<NSString *> *allKeys = kBDPSchemaAllKeysArray;
        __block NSMutableDictionary<NSString *, NSString *> *customDic = [[NSMutableDictionary alloc] init];
        [queryParams enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
            if (![allKeys containsObject:key]) {
                id resultObj = [BDPSchemaCodec objForJSONRepresentation:value];
                if (resultObj != nil) {
                    [customDic setValue:resultObj forKey:key];
                }
            }
        }];
        if ([queryParams bdp_stringValueForKey:kBDPSchemaKeyLeastVersion]) {
            customDic[kBDPSchemaKeyLeastVersion] = [queryParams bdp_stringValueForKey:kBDPSchemaKeyLeastVersion];
        }
        if (!BDPIsEmptyDictionary(customDic)) {
            [resultCodecOption.customFields addEntriesFromDictionary:[customDic copy]];
        }
        
        // 8. 真机调试
        [resultCodecOption setWsForDebug:[queryParams bdp_stringValueForKey:kBDPSchemaKeyWSForDebug]];
        [resultCodecOption setIdeDisableDomainCheck:[queryParams bdp_stringValueForKey:kBDPIdeDisableDomainCheck]];
    }
    
    return resultCodecOption;
}

+ (NSString *)schemaStringFromCodecOptions:(BDPSchemaCodecOptions *)options error:(NSError **)error {
    if (options == nil) {
        if (error) {
            *error = [BDPSchemaCodec errorWithErrorCode:BDPSchemaCodecErrorInvalidOption invalidValue:nil];
        }
        return nil;
    }
    
    // host规则:{nil:microapp; 不设置:microapp; 空字符串：报错; 非二者之一：报错;}
    NSString *host = options.host;
    if (host == nil) {
        host = SCHEMA_APP;
    } else {
        if ([host length] <= 0 || ([host isEqualToString:SCHEMA_APP] == NO)) {
            if (error) {
                *error = [BDPSchemaCodec errorWithErrorCode:BDPSchemaCodecErrorHost invalidValue:options.host];
            }
            return nil;
        }
    }
    
    if (BDPIsEmptyString(options.appID)) {
        if (error) {
            *error = [BDPSchemaCodec errorWithErrorCode:BDPSchemaCodecErrorAppID invalidValue:options.appID];
        }
        return nil;
    }
    
    //小程序不能只传query不传path
    if ([options.host isEqualToString:SCHEMA_APP] && BDPIsEmptyString(options.path) && !BDPIsEmptyDictionary(options.query)) {
        if (error) {
            *error = [BDPSchemaCodec errorWithErrorCode:BDPSchemaCodecErrorPath invalidValue:options.path];
        }
        return nil;
    }
    
    //launchMode只能传入@"hostStack"
    if (!BDPIsEmptyString(options.launchMode) && ![options.launchMode isEqualToString:@"hostStack"]) {
        if (error) {
            *error = [BDPSchemaCodec errorWithErrorCode:BDPSchemaCodecErrorLaunchMode invalidValue:options.launchMode];
        }
        return nil;
    }
    
    //拼接Schema
    NSMutableString *schemaString = [[NSMutableString alloc] init];
    
    //0.protocol & host & version
    NSString *protocol = BDPIsEmptyString(options.protocol) ? kBDPSchemaCodecDefaultProtocol : options.protocol;
    [schemaString appendFormat:@"%@://%@?%@=%@", protocol, host, kBDPSchemaKeySchemaVersion, options.schemaVersion];
    
    NSMutableDictionary<NSString *, id> *queryKVDictionary = [[NSMutableDictionary alloc] init];
    
    //1.appid & versionType & token
    [queryKVDictionary setValue:options.appID forKey:kBDPSchemaKeyAppID];
    [queryKVDictionary setValue:options.identifier forKey:kBDPSchemaKeyIdentifier];
    [queryKVDictionary setValue:options.instanceID forKey:kBDPSchemaKeyInstanceID];
    [queryKVDictionary setValue:OPAppVersionTypeToString(options.versionType) forKey:kBDPSchemaKeyVersionType];
    [queryKVDictionary setValue:options.token forKey:kBDPSchemaKeyToken];
    
    //2.meta
    if (!BDPIsEmptyDictionary(options.meta)) [queryKVDictionary setValue:options.meta forKey:kBDPSchemaKeyMeta];
    
    //3.scene & bdpLog
    [queryKVDictionary setValue:options.scene forKey:kBDPSchemaKeyScene];
    if (!BDPIsEmptyDictionary(options.bdpLog)) [queryKVDictionary setValue:options.bdpLog forKey:kBDPSchemaKeyBDPLog];
    
    //4.startPage & query
    BOOL needJoinStartPage = NO, needJoinQuery = NO;
    ///兼容逻辑: "分享"和"小程序转跳", 前端会返回拼接完整的"start_page"和"query", 对于这种直接拼接到schema.
    if (!BDPIsEmptyString(options.fullStartPage)) {
        needJoinStartPage = YES;
    } else {
        /// sslocal://microapp?app_id=aaa&start_page=encode({path}?{k1=encode(v1)&k2=encode(v2)})
        if (!BDPIsEmptyString(options.path)) {
            NSMutableString *startPage = [options.path mutableCopy];

            if (!BDPIsEmptyDictionary(options.query)) {
                NSMutableArray<NSString *> *startPageQueryArray = [[NSMutableArray alloc] init];
                [options.query enumerateKeysAndObjectsUsingBlock:^(NSString * key, id value, BOOL * _Nonnull stop) {
                    NSString *valueString = [BDPSchemaCodec urlEncodeJSONRepresentationForObj:value];
                    if (!BDPIsEmptyString(valueString)) {
                        [startPageQueryArray addObject:[NSString stringWithFormat:@"%@=%@", key, valueString]];
                    }
                }];
                if (!BDPIsEmptyArray(startPageQueryArray)) {
                    [startPage appendFormat:@"?%@", [startPageQueryArray componentsJoinedByString:@"&"]];
                }
            }

            [queryKVDictionary setValue:[startPage copy] forKey:kBDPSchemaKeyStartPage];
        }//(!BDPIsEmptyString(options.path))
    }//(!BDPIsEmptyString(options.fullStartPage))
    
    //5.refererInfo
    if (!BDPIsEmptyDictionary(options.refererInfoDictionary)) [queryKVDictionary setValue:options.refererInfoDictionary forKey:kBDPSchemaKeyRefererInfo];
    
    //6.Android专用: launch_mode & inspect
    if (!BDPIsEmptyString(options.launchMode)) [queryKVDictionary setValue:options.launchMode forKey:kBDPSchemaKeyLaunchMode];
    if (!BDPIsEmptyDictionary(options.inspect)) [queryKVDictionary setValue:options.inspect forKey:kBDPSchemaKeyInspect];
    
    //7. add XScreen parameters
    if (!BDPIsEmptyString(options.XScreenMode)) [queryKVDictionary setValue:options.XScreenMode forKey:kBDPSchemaKeyXScreenMode];
    if (!BDPIsEmptyString(options.XScreenPresentationStyle)) [queryKVDictionary setValue:options.XScreenPresentationStyle forKey:kBDPSchemaKeyXScreenPresentationStyle];
    if (!BDPIsEmptyString(options.chatID)) [queryKVDictionary setValue:options.chatID forKey:kBDPSchemaKeyXScreenCharID];
    
    //7.customFields(重复的key将忽略)
    if (!BDPIsEmptyDictionary(options.customFields)) {
        NSArray *allKeys = kBDPSchemaAllKeysArray;
        [options.customFields enumerateKeysAndObjectsUsingBlock:^(NSString * key, id value, BOOL * _Nonnull stop) {
            if (![allKeys containsObject:key]) {
                [queryKVDictionary setValue:value forKey:key];
            }
        }];
    }
    
    // 8. 真机调试
    if (!BDPIsEmptyDictionary(options.wsForDebug)) [queryKVDictionary setValue:options.wsForDebug forKey:kBDPSchemaKeyWSForDebug];
    if (!BDPIsEmptyString(options.ideDisableDomainCheck)) [queryKVDictionary setValue:options.ideDisableDomainCheck forKey:kBDPIdeDisableDomainCheck];
    
    //拼接所有参数(key升序排列)
    NSArray *allKeys = [[queryKVDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in allKeys) {
        id value = [queryKVDictionary objectForKey:key];
        NSString *valueString = [BDPSchemaCodec urlEncodeJSONRepresentationForObj:value];
        if (!BDPIsEmptyString(valueString)) {
            [schemaString appendString:[NSString stringWithFormat:@"&%@=%@", key, valueString]];
        }
    }
    
    ///兼容逻辑: "分享"和"小程序转跳", 前端会返回拼接完整的"start_page"和"query", 对于这种直接拼接到schema.
    if (needJoinStartPage) {
        [schemaString appendString:[NSString stringWithFormat:@"&%@=%@", kBDPSchemaKeyStartPage, options.fullStartPage]];
    }
    if (needJoinQuery) {
        // TODO: 永远都不会被运行到的逻辑，请确认删除
        [schemaString appendString:[NSString stringWithFormat:@"&%@=%@", kBDPSchemaKeyQuery, options.fullquery]];
    }
    
    //增加校验和bdpsum
    NSString *sumString = [BDPSchemaCodec calcSumForSchemaString:schemaString];
    if (BDPIsEmptyString(sumString)) {
        if (error) {
            *error = [BDPSchemaCodec errorWithErrorCode:BDPSchemaCodecErrorCheck invalidValue:schemaString];
        }
        return nil;
    }
    [schemaString appendString:[NSString stringWithFormat:@"&%@=%@", kBDPSchemaKeyBDPSum, sumString]];
    
    return [schemaString copy];
}

+ (NSURL *)schemaURLFromCodecOptions:(BDPSchemaCodecOptions *)options error:(NSError **)error {
    return [NSURL URLWithString:[BDPSchemaCodec schemaStringFromCodecOptions:options error:error]];
}

#pragma mark - Protect Interface

+ (BDPSchema *)schemaFromURL:(NSURL *)url appType:(OPAppType)appType error:(NSError **)error; {
    //创建空白 BDPSchema
    BDPSchema *resultSchema = [[BDPSchema alloc] initWithURL:url appType:appType];
    
    //URL 无效
    if (url == nil || [url isKindOfClass:[NSURL class]] == NO) {
        NSError *err = [BDPSchemaCodec errorWithErrorCode:BDPSchemaCodecErrorInvalidURL invalidValue:nil];
        [resultSchema setError:err];
        if (error) {
            *error = err;
        }
        return resultSchema;
    }
    
    //URL 为空
    NSString *urlString = [url absoluteString];
    if (BDPIsEmptyString(urlString)) {
        NSError *err = [BDPSchemaCodec errorWithErrorCode:BDPSchemaCodecErrorInvalidURL invalidValue:nil];
        [resultSchema setError:err];
        if (error) {
            *error = err;
        }
        return resultSchema;
    }

    //拆分schema字符串
    __block NSDictionary *queryParams = nil;
    [BDPSchemaCodec separateProtocolHostAndParams:urlString syncResultBlock:^(NSString *protocol, NSString *host, NSString *fullHost, NSDictionary *params) {
        [resultSchema setProtocol:protocol];
        [resultSchema setHost:host];
        [resultSchema setFullHost:fullHost];
        [resultSchema setOriginQueryParams:params];
        queryParams = params;
    }];
    
    //根据version字段差异化解析
    NSString *schemaVersionString = [queryParams bdp_stringValueForKey:kBDPSchemaKeySchemaVersion];
     if ([schemaVersionString isEqualToString:BDPSchemaVersionV02]) {
        
        //用于收集埋点信息,以便上层进行埋点统计
        NSMutableDictionary *schemaCodecTrackInfo = [[NSMutableDictionary alloc] init];
        
        //@"v2"按照V02版本处理
        [resultSchema setSchemaVersion:BDPSchemaVersionV02];
        
        //1.appid & version & token
        [resultSchema setAppID:[queryParams bdp_stringValueForKey:kBDPSchemaKeyAppID]];
        [resultSchema setIdentifier:[queryParams bdp_stringValueForKey:kBDPSchemaKeyIdentifier]];
        [resultSchema setInstanceID:[queryParams bdp_stringValueForKey:kBDPSchemaKeyInstanceID]];
        [resultSchema setVersionType:OPAppVersionTypeFromString([queryParams bdp_stringValueForKey:kBDPSchemaKeyVersionType])];
        [resultSchema setToken:[queryParams bdp_stringValueForKey:kBDPSchemaKeyToken]];
        
        OPAppUniqueID *uiniqueID = resultSchema.uniqueID;
        
        //2.meta
        [resultSchema setMeta:([[queryParams bdp_stringValueForKey:kBDPSchemaKeyMeta] JSONValue] ?: @{})];
        
        //3.url
        [resultSchema setUrl:nil];
        [[self class] constructUrlForSchema:resultSchema];
        
        //4.start_page
        [resultSchema setStartPage:[queryParams bdp_stringValueForKey:kBDPSchemaKeyStartPage]];
        [[self class] constructStartPageForSchema:resultSchema];
        
        //5.query
        [resultSchema setQuery:[queryParams bdp_stringValueForKey:kBDPSchemaKeyQuery]];
        [[self class] constructQueryForSchema:resultSchema];
        
        //6.extra
        [resultSchema setExtra:[queryParams bdp_stringValueForKey:@"extra"]];
        [[self class] constructExtraForSchema:resultSchema];
        
        //7.bdp_log
        [resultSchema setBdpLog:[queryParams bdp_stringValueForKey:kBDPSchemaKeyBDPLog]];
        [[self class] constructBdpLogForSchema:resultSchema];
        
        //8.scene&subScene
        [resultSchema setScene:[queryParams bdp_stringValueForKey:kBDPSchemaKeyScene] ?: @"0"];
        [resultSchema setSubScene:nil];
        
        if (!BDPIsEmptyString([queryParams bdp_stringValueForKey:kBDPSchemaKeyScene])) {
            if ([[queryParams bdp_stringValueForKey:kBDPSchemaKeyScene] isEqualToString:@"0"]) {
                [schemaCodecTrackInfo setValue:@"0" forKey:@"scene_check"];
            } else {
                [schemaCodecTrackInfo setValue:@"normal" forKey:@"scene_check"];
            }
        } else {
            [schemaCodecTrackInfo setValue:@"none" forKey:@"scene_check"];
        }
        
        //9.referInfo
        [resultSchema setRefererInfoDictionary:[[queryParams bdp_stringValueForKey:kBDPSchemaKeyRefererInfo] JSONValue]];
        
        //10.shareTicket
        [resultSchema setShareTicket:[queryParams bdp_stringValueForKey:@"shareTicket"]];
        
        //11.gd_ext_json
        [resultSchema setGdExt:[queryParams bdp_stringValueForKey:kBDPSchemaKeyGdExt]];
        [[self class] constructGdExtForSchema:resultSchema];
        
        //ttid
        NSString *ttid = nil;
        if (!BDPIsEmptyDictionary(resultSchema.bdpLogDictionary)) {
            ttid = [resultSchema.bdpLogDictionary bdp_stringValueForKey:BDPSchemaBDPLogKeyTtid];
        }
        if (BDPIsEmptyString(ttid)) {
            ttid = [queryParams bdp_stringValueForKey:BDPSchemaBDPLogKeyTtid];
        }
        [resultSchema setTtid:ttid];
        
        NSString *innerTtid = [resultSchema.bdpLogDictionary bdp_stringValueForKey:BDPSchemaBDPLogKeyTtid];
        NSString *outerTtid = [queryParams bdp_stringValueForKey:BDPSchemaBDPLogKeyTtid];
        if (!BDPIsEmptyString(innerTtid) && !BDPIsEmptyString(outerTtid)) {
            [schemaCodecTrackInfo setValue:@"both" forKey:@"ttid_check"];
        } else if (!BDPIsEmptyString(innerTtid) && BDPIsEmptyString(outerTtid)) {
            [schemaCodecTrackInfo setValue:@"inner" forKey:@"ttid_check"];
        } else if (BDPIsEmptyString(innerTtid) && !BDPIsEmptyString(outerTtid)) {
            [schemaCodecTrackInfo setValue:@"outer" forKey:@"ttid_check"];
        } else {
            [schemaCodecTrackInfo setValue:@"neither" forKey:@"ttid_check"];
        }
        
        // launch_from
        NSString *launch_from = nil;
        if (!BDPIsEmptyDictionary(resultSchema.bdpLogDictionary)) {
            launch_from = [resultSchema.bdpLogDictionary bdp_stringValueForKey:BDPSchemaBDPLogKeyLaunchFrom];
        }
        if (BDPIsEmptyString(launch_from)) {
            launch_from = [queryParams bdp_stringValueForKey:BDPSchemaBDPLogKeyLaunchFrom];
        }
        [resultSchema setLaunchFrom:launch_from];
        
        // origin_entrance
        NSString *origin_entrance = nil;
        if (!BDPIsEmptyDictionary(resultSchema.bdpLogDictionary)) {
            origin_entrance = [resultSchema.bdpLogDictionary bdp_stringValueForKey:BDPSchemaBDPLogKeyOriginEntrance];
        }
        if (BDPIsEmptyString(origin_entrance)) {
            origin_entrance = [queryParams bdp_stringValueForKey:BDPSchemaBDPLogKeyOriginEntrance];
        }
        if (BDPIsEmptyString(origin_entrance) && launch_from) {
            NSString *location = [resultSchema location];
            origin_entrance = [NSString stringWithFormat:@"{\"oe_launch_from\":\"%@\", \"oe_location\":\"%@\"}", launch_from, BDPSafeString(location)];
        }
        [resultSchema setOriginEntrance:origin_entrance];
        
        NSString *innerLaunchFrom = [resultSchema.bdpLogDictionary bdp_stringValueForKey:BDPSchemaBDPLogKeyLaunchFrom];
        NSString *outerLaunchFrom = [queryParams bdp_stringValueForKey:BDPSchemaBDPLogKeyLaunchFrom];
        if (!BDPIsEmptyString(innerLaunchFrom) && !BDPIsEmptyString(outerLaunchFrom)) {
            [schemaCodecTrackInfo setValue:@"both" forKey:@"launch_from_check"];
        } else if (!BDPIsEmptyString(innerLaunchFrom) && BDPIsEmptyString(outerLaunchFrom)) {
            [schemaCodecTrackInfo setValue:@"inner" forKey:@"launch_from_check"];
        } else if (BDPIsEmptyString(innerLaunchFrom) && !BDPIsEmptyString(outerLaunchFrom)) {
            [schemaCodecTrackInfo setValue:@"outer" forKey:@"launch_from_check"];
        } else {
            [schemaCodecTrackInfo setValue:@"neither" forKey:@"launch_from_check"];
        }
        
        //schema编解码埋点统计信息
//        [resultSchema setSchemaCodecTrackInfo:schemaCodecTrackInfo];
        
        // schema vdom 调试参数
        [resultSchema setSnapshotUrl:[[queryParams bdp_stringValueForKey:@"snapshot_url"] URLDecodedString]];
        
        // 真机调试参数
        [resultSchema setWsForDebug:[[queryParams bdp_stringValueForKey:kBDPSchemaKeyWSForDebug] URLDecodedString]];
        [resultSchema setIdeDisableDomainCheck:[[queryParams bdp_stringValueForKey:kBDPIdeDisableDomainCheck] URLDecodedString]];
         
         // 半屏参数
         NSString *mode = [queryParams bdp_stringValueForKey:kBDPSchemaKeyXScreenMode];
         NSString *XScreenPresentationStyle = [queryParams bdp_stringValueForKey:kBDPSchemaKeyXScreenPresentationStyle];
         [resultSchema setXScreenPresentationStyle:XScreenPresentationStyle];
         [resultSchema setMode:mode];
         
         // 半屏chatid参数
         NSString *chatID = [queryParams bdp_stringValueForKey:kBDPSchemaKeyXScreenCharID];
         [resultSchema setChatID:chatID];
    } else {
        
        //不带version字段 or @"v1" or @"v2"按照V01版本处理 || 不支持的版本按照V01解析
        [resultSchema setSchemaVersion:BDPSchemaVersionV01];
        
        //1.appid & version & token
        [resultSchema setAppID:[queryParams bdp_stringValueForKey:kBDPSchemaKeyAppID]];
        [resultSchema setIdentifier:[queryParams bdp_stringValueForKey:kBDPSchemaKeyIdentifier]];
        [resultSchema setInstanceID:[queryParams bdp_stringValueForKey:kBDPSchemaKeyInstanceID]];
        [resultSchema setVersionType:OPAppVersionTypeFromString([queryParams bdp_stringValueForKey:kBDPSchemaKeyVersionType])];
        [resultSchema setToken:[queryParams bdp_stringValueForKey:kBDPSchemaKeyToken]];
        
        //2.meta
        [resultSchema setMeta:([[queryParams bdp_stringValueForKey:kBDPSchemaKeyMeta] JSONValue] ?: @{})];
        
        //3.url
        [resultSchema setUrl:nil];
        [[self class] constructUrlForSchema:resultSchema];
        
        //4.start_page
        [resultSchema setStartPage:[queryParams bdp_stringValueForKey:kBDPSchemaKeyStartPage]];
        [[self class] constructStartPageForSchema:resultSchema];
        
        //5.query
        [resultSchema setQuery:[queryParams bdp_stringValueForKey:kBDPSchemaKeyQuery]];
        [[self class] constructQueryForSchema:resultSchema];
        
        //6.extra
        [resultSchema setExtra:[queryParams bdp_stringValueForKey:@"extra"]];
        [[self class] constructExtraForSchema:resultSchema];
        
        //7.bdp_log
        [resultSchema setBdpLog:[queryParams bdp_stringValueForKey:kBDPSchemaKeyBDPLog]];
        [[self class] constructBdpLogForSchema:resultSchema];
        
        //8.scene&subScene
        [resultSchema setScene:[queryParams bdp_stringValueForKey:kBDPSchemaKeyScene]];
        [resultSchema setSubScene:[queryParams bdp_stringValueForKey:@"sub_scene"]];
        
        //9.referInfo
        [resultSchema setRefererInfoDictionary:[[queryParams bdp_stringValueForKey:kBDPSchemaKeyRefererInfo] JSONValue]];
        
        //10.shareTicket
        [resultSchema setShareTicket:[queryParams bdp_stringValueForKey:@"shareTicket"]];
        
        //11.gd_ext_json
        [resultSchema setGdExt:[queryParams bdp_stringValueForKey:kBDPSchemaKeyGdExt]];
        [[self class] constructGdExtForSchema:resultSchema];
        
        //ttid
        NSString *ttid = nil;
        if (!BDPIsEmptyDictionary(resultSchema.bdpLogDictionary)) {
            ttid = [resultSchema.bdpLogDictionary bdp_stringValueForKey:BDPSchemaBDPLogKeyTtid];
        }
        if (BDPIsEmptyString(ttid)) {
            ttid = [queryParams bdp_stringValueForKey:BDPSchemaBDPLogKeyTtid];
        }
        [resultSchema setTtid:ttid];
        
        //launch_from
        NSString *launch_from = nil;
        if (!BDPIsEmptyDictionary(resultSchema.bdpLogDictionary)) {
            launch_from = [resultSchema.bdpLogDictionary bdp_stringValueForKey:BDPSchemaBDPLogKeyLaunchFrom];
        }
        if (BDPIsEmptyString(launch_from)) {
            launch_from = [queryParams bdp_stringValueForKey:BDPSchemaBDPLogKeyLaunchFrom];
        }
        [resultSchema setLaunchFrom:launch_from];
//
//        // origin_entrance
        NSString *origin_entrance = nil;
        if (!BDPIsEmptyDictionary(resultSchema.bdpLogDictionary)) {
            origin_entrance = [resultSchema.bdpLogDictionary bdp_stringValueForKey:BDPSchemaBDPLogKeyOriginEntrance];
        }
        if (BDPIsEmptyString(origin_entrance)) {
            origin_entrance = [queryParams bdp_stringValueForKey:BDPSchemaBDPLogKeyOriginEntrance];
        }
        if (BDPIsEmptyString(origin_entrance) && launch_from) {
            NSString *location = [resultSchema location];
            origin_entrance = [NSString stringWithFormat:@"{\"oe_launch_from\":\"%@\", \"oe_location\":\"%@\"}", launch_from, BDPSafeString(location)];
        }
        [resultSchema setOriginEntrance:origin_entrance];
        
        // 真机调试参数
        [resultSchema setWsForDebug:[[queryParams bdp_stringValueForKey:kBDPSchemaKeyWSForDebug] URLDecodedString]];
        [resultSchema setIdeDisableDomainCheck:[[queryParams bdp_stringValueForKey:kBDPIdeDisableDomainCheck] URLDecodedString]];
        
        // 半屏参数
        NSString *mode = [queryParams bdp_stringValueForKey:kBDPSchemaKeyXScreenMode];
        NSString *XScreenPresentationStyle = [queryParams bdp_stringValueForKey:kBDPSchemaKeyXScreenPresentationStyle];
        [resultSchema setXScreenPresentationStyle:XScreenPresentationStyle];
        [resultSchema setMode:mode];
        
        // 半屏chatid参数
        NSString *chatID = [queryParams bdp_stringValueForKey:kBDPSchemaKeyXScreenCharID];
        [resultSchema setChatID:chatID];
    }
    
    return resultSchema;
}

#pragma mark - Private Interface

+ (void)separateProtocolHostAndParams:(NSString *)urlString syncResultBlock:(void (^)(NSString *protocol, NSString *host, NSString *fullHost, NSDictionary *params))resultBlock {
    if (resultBlock == nil) {
        return;
    }
    
    if (BDPIsEmptyString(urlString)) {
        resultBlock(nil, nil, nil, @{});
        return;
    }
    
    //Schema结构: protocol://host/segment?queryParams
    //参考: https://docs.bytedance.net/doc/9HNNxnEMIik9S73zRdGNMb
    //参考: TTRoute实现
    
    //1.拆分protocol://host/segment和params
    NSRange questionMarkRange = [urlString rangeOfString:@"?"];
    NSString *protocolAndHost = nil;
    NSString *params = nil;
    if (questionMarkRange.location == NSNotFound) {
        protocolAndHost = [urlString copy];
        params = nil;
    } else {
        protocolAndHost = [urlString substringToIndex:questionMarkRange.location];
        params = [urlString substringFromIndex:NSMaxRange(questionMarkRange)];
    }
    
    //2.拆分protocol和host和segment
    NSRange colonMarkRange = [protocolAndHost rangeOfString:@"://"];
    NSString *protocol = nil;
    NSString *hostAndSegment = nil;
    if (colonMarkRange.location == NSNotFound) {
        protocol = nil;
        hostAndSegment = [protocolAndHost copy];
    } else {
        protocol = [protocolAndHost substringToIndex:colonMarkRange.location];
        hostAndSegment = [protocolAndHost substringFromIndex:NSMaxRange(colonMarkRange)];
    }
    
    NSString *host = [[hostAndSegment componentsSeparatedByString:@"/"] firstObject];
    
    //3.拆分params
    NSArray *allParams = [params componentsSeparatedByString:@"&"];
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    [allParams enumerateObjectsUsingBlock:^(NSString *param, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *keyAndValue = [param componentsSeparatedByString:@"="];
        if ([keyAndValue count] > 1) {
            NSString *paramKey = [keyAndValue objectAtIndex:0];
            NSString *paramValue = [keyAndValue objectAtIndex:1] ?: @"";
            if (!BDPIsEmptyString(paramKey)) {
                NSString *decodeValue = [paramValue URLDecodedString];
                [queryParams setValue:decodeValue forKey:paramKey];
            }
        } else if ([keyAndValue count] == 1) {
            NSString *paramKey = [keyAndValue objectAtIndex:0];
            NSString *paramValue = @"";
            if (!BDPIsEmptyString(paramKey)) {
                NSString *decodeValue = [paramValue URLDecodedString];
                [queryParams setValue:decodeValue forKey:paramKey];
            }
        }
    }];
    
    resultBlock(protocol, host, hostAndSegment, [queryParams copy]);
}

+ (void)separatePathAndQuery:(NSString *)urlString syncResultBlock:(void (^)(NSString *path, NSString *query, NSDictionary *queryDictionary))resultBlock {
    if (resultBlock == nil) {
        return;
    }
    
    if (BDPIsEmptyString(urlString)) {
        resultBlock(nil, nil, @{});//这里返回空字典是为了和旧有逻辑对应
        return;
    }
    
    //1.拆分{startPagePath}和{startPageQuery}
    NSRange questionMarkRange = [urlString rangeOfString:@"?"];
    NSString *pathString;
    NSString *queryString;
    if (questionMarkRange.location == NSNotFound) {
        pathString = urlString;
        queryString = nil;
    } else {
        pathString = [urlString substringToIndex:questionMarkRange.location];
        queryString = [urlString substringFromIndex:NSMaxRange(questionMarkRange)];
    }
    
    //2.去除多余@".html"
    pathString = [[pathString componentsSeparatedByString:@".html"] firstObject];
    
    //3.拆分startPageQuery
    NSArray *allParams = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    [allParams enumerateObjectsUsingBlock:^(NSString *param, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *keyAndValue = [param componentsSeparatedByString:@"="];
        if ([keyAndValue count] > 1) {
            NSString *paramKey = [keyAndValue objectAtIndex:0];
            NSString *paramValue = [keyAndValue objectAtIndex:1] ?: @"";
            if (!BDPIsEmptyString(paramKey)) {
                [queryParams setValue:paramValue forKey:paramKey];
            }
        } else if ([keyAndValue count] == 1) {
            NSString *paramKey = [keyAndValue objectAtIndex:0];
            NSString *paramValue = @"";
            if (!BDPIsEmptyString(paramKey)) {
                [queryParams setValue:paramValue forKey:paramKey];
            }
        }
    }];
    
    if (resultBlock != nil) {
        resultBlock(pathString, queryString, [queryParams copy]);
    }
}

#pragma mark - BDPSchema Helper

+ (void)constructStartPageForSchema:(BDPSchema *)schema {
    if (schema == nil || BDPIsEmptyString(schema.startPage)) {
        return;
    }
    
    NSString *startPage = schema.startPage;
    [[self class] separatePathAndQuery:startPage syncResultBlock:^(NSString *path, NSString *query, NSDictionary *queryDictionary) {
        [schema setStartPagePath:path];
        [schema setStartPageQuery:query];
        [schema setStartPageQueryDictionary:queryDictionary];///注意这里dictinary中的value是经过一次encode的结果
    }];
}

+ (void)constructQueryForSchema:(BDPSchema *)schema {
    if (schema == nil || BDPIsEmptyString(schema.query)) {
        return;
    }
    
    NSString *query = schema.query;
    NSDictionary *quertDic = [query JSONValue];
    [schema setQueryDictionary:quertDic];
}

+ (void)constructUrlForSchema:(BDPSchema *)schema {
    if (schema == nil || BDPIsEmptyString(schema.url)) {
        return;
    }
    
    NSString *url = schema.url;
    NSDictionary *urlDic = [url JSONValue];
    [schema setUrlDictionary:urlDic];
}

+ (void)constructExtraForSchema:(BDPSchema *)schema {
    if (schema == nil || BDPIsEmptyString(schema.extra)) {
        return;
    }
    
    NSString *extra = schema.extra;
    NSDictionary *extraDic = [extra JSONValue];
    [schema setExtraDictionary:extraDic];
}

+ (void)constructBdpLogForSchema:(BDPSchema *)schema {
    if (schema == nil || BDPIsEmptyString(schema.bdpLog)) {
        return;
    }

    NSString *bdpLog = schema.bdpLog;
    NSDictionary *bdpLogDic = [bdpLog JSONValue];
    [schema setBdpLogDictionary:bdpLogDic];
}

+ (void)constructGdExtForSchema:(BDPSchema *)schema {
    if (schema == nil || BDPIsEmptyString(schema.gdExt)) {
        return;
    }
    
    NSString *gdExt = schema.gdExt;
    NSDictionary *gdExtDic = [gdExt JSONValue];
    [schema setGdExtDictionary:gdExtDic];
}

#pragma mark - Sum Helper

+ (NSString *)calcSumForSchemaString:(NSString *)schemaString {
    if (BDPIsEmptyString(schemaString)) {
        return nil;
    }

    // 2019-6-24: 没有@"://"按整个字符串计算; 出现一个@"://"只计算@"://"后面的部分; 出现多个@"://"直接返回错误
    NSString *validSchemaString = nil;
    NSArray *components = [schemaString componentsSeparatedByString:@"://"];
    if ([components count] > 2) {
        return nil;
    } else if ([components count] < 2) {
        validSchemaString = [schemaString copy];
    } else  {
        NSRange colonMarkRange = [schemaString rangeOfString:@"://"];
        validSchemaString = [schemaString substringFromIndex:NSMaxRange(colonMarkRange)];
    }

    NSString *sum = nil;
    @try {
        if ([validSchemaString length] < 10) {
            return nil;
        }
        NSString *checkString = [NSString stringWithFormat:@"%@bytetimordance%@", [validSchemaString substringWithRange:NSMakeRange(0, 10)], [validSchemaString substringFromIndex:10]];
        NSString *md5 = [checkString bdp_md5String];

        if ([md5 length] < 32) {
            return nil;
        }
        sum = [NSString stringWithFormat:@"%@%@", [md5 substringWithRange:NSMakeRange(2, 4)], [md5 substringWithRange:NSMakeRange(20, 3)]];
    } @catch (NSException *exception) {
        sum = nil;
    }
    return sum;
}

+ (BOOL)checkSumForSchemaString:(NSString *)schemaString sumString:(NSString *)sumString version:(NSString *)version {
    if (BDPIsEmptyString(schemaString)) {
        return NO;
    }

    if (BDPIsEmptyString(version) || [version isEqualToString:BDPSchemaVersionV00] || [version isEqualToString:BDPSchemaVersionV01]) {
        return YES;
    } else if ([version isEqualToString:BDPSchemaVersionV02]) {
        if (BDPIsEmptyString(sumString)) {
            return NO;
        }

        //去除bdpsum字段后再验证
        NSString *sumParam = [NSString stringWithFormat:@"&%@=%@", kBDPSchemaKeyBDPSum, sumString];
        NSString *absoluteSchemaString = [schemaString stringByReplacingOccurrencesOfString:sumParam withString:@""];

        NSString *calcSumString = [BDPSchemaCodec calcSumForSchemaString:absoluteSchemaString];
        return [calcSumString isEqualToString:sumString];
    } else {
        return NO;
    }
}

#pragma mark - Error Helper

+ (NSError *)errorWithErrorCode:(BDPSchemaCodecError)errorCode invalidValue:(NSString *)invalidValue {
    NSDictionary *userInfo = nil;
    if (!BDPIsEmptyString(invalidValue)) {
        userInfo = @{@"InvalidValue" : invalidValue};
    }
    NSError *error = [NSError errorWithDomain:BDPSchemaCodecErrorDomain code:errorCode userInfo:userInfo];
    return error;
}

#pragma mark - Encode Helper

+ (NSString *)urlEncodeJSONRepresentationForObj:(id)object {
    if (object == nil) {
        return nil;
    }
    
    //NSString直接返回encode的字符串
    if ([object isKindOfClass:[NSString class]]) {
        return [(NSString *)object URLEncodedString];
    }
    
    //NSNumber改为字符串去处理
    if ([object isKindOfClass:[NSNumber class]]) {
        return [[(NSNumber *)object stringValue] URLEncodedString];
    }
    
    //不是有效的
    if (![NSJSONSerialization isValidJSONObject:object]) {
        return nil;
    }
    
    NSString *JSONString = nil;
    @try {
        NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
        JSONString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } @catch (NSException *exception) {
        BDPLogInfo(@"BDP Schema Codec JSONSerialization Error:%@", exception);
    }
    
    if (BDPIsEmptyString(JSONString)) {
        return nil;
    }
    
    NSString *formattedString = [JSONString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    NSString *encodeString = [formattedString URLEncodedString];
    return encodeString;
}

+ (id)objForJSONRepresentation:(NSString *)jsonString
{
    if (BDPIsEmptyString(jsonString)) {
        return jsonString;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData == nil) {
        return jsonString;//无法生成data直接返回原字符串
    }
    
    NSError *error = nil;
    id resultObj = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error != nil) {
        return jsonString;//无法解析成object直接返回原字符串
    }
    return resultObj;
}

+ (NSString *)urlEncodeJSONStringForDic:(NSDictionary *)dic {
    if (![dic isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSString *jsonString = [dic JSONRepresentation];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];

    NSString *encodeString = [jsonString URLEncodedString];
    return encodeString;
}

+ (NSString *)urlEncodeJSONStringForArray:(NSArray *)array {
    if (![array isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSString *jsonString = [array JSONRepresentation];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];

    NSString *encodeString = [jsonString URLEncodedString];
    return encodeString;
}

+ (NSString *)urlEncodeStringForString:(NSString *)str {
    if (BDPIsEmptyString(str)) {
        return nil;
    }
    NSString *encodeString = [str URLEncodedString];
    return encodeString;
}

@end
