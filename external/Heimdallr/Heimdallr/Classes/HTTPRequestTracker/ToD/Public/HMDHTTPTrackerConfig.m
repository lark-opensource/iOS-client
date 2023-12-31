//
//  HMDHTTPTrackerConfig.m
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDHTTPTrackerConfig.h"
#import "HMDHTTPRequestTracker.h"
#import "NSObject+HMDAttributes.h"
#import "NSDictionary+HMDSafe.h"
#import "NSArray+HMDSafe.h"
#import "hmd_section_data_utility.h"
#import "HMDInjectedInfo+NetMonitorConfig.h"

NSString *const kHMDModuleNetworkTracker = @"network";
NSString *const kHMDTraceParentKeyStr = @"traceparent";

#define kHMDNetworkConfigAllowedRuleString @"rule"
#define kHMDNetworkConfigAllowedRuleExpr @"expression"

HMD_MODULE_CONFIG(HMDHTTPTrackerConfig)

@interface HMDHTTPTrackerConfig ()

@property (nonatomic, strong) NSCache *allowListCache;
@property (nonatomic, strong) NSCache *blockListCache;

@property (nonatomic, assign) BOOL allowedListOptEnabled;
@property (nonatomic, strong) NSArray<NSString *> *stringAllowedRuleList;
@property (nonatomic, strong) NSArray<NSDictionary *> *regularAllowedRuleList;

@end

@implementation HMDHTTPTrackerConfig

// 在这里初始化不会执行
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupURLCache];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)data {
    self = [super initWithDictionary:data];
    if(self) {
        if(HMDInjectedInfo.defaultInfo.allowedURLRegularOptEnabled) {
            [self setupURLCache];
            [self groupApiAllowedListRule];
        }
    }
    return self;
}

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP(apiAllowList, api_allow_list)
        HMD_ATTR_MAP(apiBlockList, api_block_list)
        HMD_ATTR_MAP(enableAPIAllUpload, enable_api_all_upload)
        HMD_ATTR_MAP_DEFAULT(enableAPIErrorUpload, enable_api_error_upload, @(YES), @(YES)) //网络错误默认上报
        HMD_ATTR_MAP(enableNSURLProtocolAndChromium, enable_nsurlprotocol_and_chromium)
        HMD_ATTR_MAP(ignoreCancelError, ignore_cancel_error)
        HMD_ATTR_MAP(responseBodyEnabled, enable_record_response_body)
        HMD_ATTR_MAP(responseBodyThreshold, response_body_threshold)
        HMD_ATTR_MAP(enableTTNetCDNSample, enable_ttnet_cdn_sample)
        HMD_ATTR_MAP(apiAllowHeaderList, api_allow_header_list)
        HMD_ATTR_MAP(requestAllowHeader, request_allow_header)
        HMD_ATTR_MAP(responseAllowHeader, response_allow_header)
        HMD_ATTR_MAP(baseApiAll, enable_base_api_all)
        HMD_ATTR_MAP(enableCustomURLCache, enable_custom_url_cache)
        HMD_ATTR_MAP(enableWebViewMonitor, enable_webview_monitor)
    };
}

- (void)hmd_setAttributes:(NSDictionary *)dataDic {
    [super hmd_setAttributes:dataDic];
    NSDictionary *apiWhiteList = [dataDic hmd_dictForKey:@"api_allow_list"];
    if (apiWhiteList.count) { //由于后端支持了采样，变成了字典，这里转换一下
        NSMutableArray *mArray = [NSMutableArray array];
        [apiWhiteList enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(intValue)] && [obj intValue] == 1) {
                [mArray addObject:key];
            }
        }];
        self.apiAllowList = mArray;
    }else{
        self.apiAllowList = nil;
    }
}

+ (NSString *)configKey
{
    return kHMDModuleNetworkTracker;
}

- (id<HeimdallrModule>)getModule
{
    return [HMDHTTPRequestTracker sharedTracker];
}

- (NSDictionary *)requestAllowHeaderWithHeader:(NSDictionary *)requesHeader {
    NSDictionary *dict = [self requestAllowHeaderWithHeader:requesHeader isMovingLine:NO];
    return dict;
}

- (NSDictionary *)requestAllowHeaderWithHeader:(NSDictionary *)requesHeader isMovingLine:(BOOL)isMovingLine {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    BOOL isTraceParentHit = NO;
    
    if (self.requestAllowHeader && self.requestAllowHeader.count > 0) {
        for (NSString *allowKey in self.requestAllowHeader.allKeys) {
            BOOL isSampled = [[self.requestAllowHeader valueForKey:allowKey] boolValue];
            if (isSampled) {
                id value = [requesHeader valueForKey:allowKey];
                if (value) {
                    [dict setValue:value forKey:allowKey];
                }
                if ([allowKey isEqualToString:kHMDTraceParentKeyStr]) {
                    isTraceParentHit = YES;
                }
            }
        }
    }
    
    if (isMovingLine && !isTraceParentHit) {
        id value = [requesHeader objectForKey:kHMDTraceParentKeyStr];
        if (value) {
            [dict setValue:value forKey:@"traceparent"];
        }
    }
    
    return [dict copy];
}

- (NSDictionary *)responseAllowHeaderWitHeader:(NSDictionary *)reponseHeader {
    NSDictionary *dict = [self responseAllowHeaderWitHeader:reponseHeader isMovingLine:NO];
    return dict;
}

- (NSDictionary *)responseAllowHeaderWitHeader:(NSDictionary *)responseHeader isMovingLine:(BOOL)isMovingLine {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    BOOL isLogIDHit = NO;
    if (self.responseAllowHeader && self.responseAllowHeader.count > 0) {
        for (NSString *allowKey in self.responseAllowHeader.allKeys) {
            BOOL isSampled = [[self.responseAllowHeader valueForKey:allowKey] boolValue];
            if (isSampled) {
                id value = [responseHeader valueForKey:allowKey];
                if (value) {
                    [dict setValue:value forKey:allowKey];
                }
                if ([allowKey isEqualToString:@"x-tt-logid"]) {
                    isLogIDHit = YES;
                }
            }
        }
    }
    
    if (isMovingLine && !isLogIDHit) {
        id value = [responseHeader objectForKey:@"x-tt-logid"];
        if (value) {
            [dict setValue:value forKey:@"x-tt-logid"];
        }
        
    }
    return [dict copy];
}

#pragma mark judge
- (void)setupURLCache {
    self.allowListCache = [[NSCache alloc] init];
    self.allowListCache.countLimit = 100;

    self.blockListCache = [[NSCache alloc] init];
    self.blockListCache.countLimit = 100;
}

- (void)groupApiAllowedListRule {
    NSArray<NSString *> *apiAllowedList = self.apiAllowList;
    
    NSMutableArray<NSString *> *stringList = [NSMutableArray array];
    NSMutableArray<NSDictionary *> *regularList = [NSMutableArray array];
    
    NSCharacterSet *regularSet = [NSCharacterSet characterSetWithCharactersInString:@"\\^$*+?.[]|{}-,()"];
    
    for (NSString *allowedRule in apiAllowedList) {
        if (![allowedRule isKindOfClass:[NSString class]]) {
            return;
        }
        if([allowedRule rangeOfCharacterFromSet:regularSet].location != NSNotFound) {
            NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:allowedRule options:0 error:nil];
            if (expression) {
                [regularList hmd_addObject: @{
                    kHMDNetworkConfigAllowedRuleExpr: expression,
                    kHMDNetworkConfigAllowedRuleString: allowedRule ?: @""
                }];
                continue;
            }
        }
        
        [stringList hmd_addObject:allowedRule];
    }
    
    self.stringAllowedRuleList = [stringList copy];
    self.regularAllowedRuleList = [regularList copy];
    
    self.allowedListOptEnabled = YES;
}

#pragma mark block url judge
- (BOOL)isURLInBlockList:(NSString *)urlString
{
    NSArray *blockList = [self apiBlockList];
    if (![blockList isKindOfClass:[NSArray class]]) {
        return NO;
    }
    if (!blockList || blockList.count<=0) {
        return NO;
    }
    if (urlString) {
        if (![urlString isKindOfClass:[NSString class]]) {
            return NO;
        }
        for(NSString *blockUrl in blockList){
            if ([blockUrl isKindOfClass:[NSString class]]) {
                if ([urlString rangeOfString:blockUrl].location != NSNotFound) {
                    
                    if ([self isURLInAllowList:urlString]) { //When hitting both blockList and allowList, allowList shall prevail.
                        return NO;
                    }
                    
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (BOOL)isURLInBlockListWithMainURL:(NSString *)mainURL {
    NSArray *blockList = [self apiBlockList];
    if (![blockList isKindOfClass:[NSArray class]]) {
        return NO;
    }
    if (!blockList || blockList.count<=0) {
        return NO;
    }

    if (![mainURL isKindOfClass:[NSString class]]) {
        return NO;
    }

    if (!mainURL || mainURL.length == 0) {
        return NO;
    }

    NSNumber *res = [self pathCachedBlockListResWithPath:mainURL];
    if (res) {
        return [res boolValue];
    }

    BOOL isBlock = NO;
    for(NSString *blockUrl in blockList){
        if ([blockUrl isKindOfClass:[NSString class]]) {
            if ([mainURL rangeOfString:blockUrl].location != NSNotFound) {
                isBlock = ![self isURLInAllowListWithMainURL:mainURL];
                break;
            }
        }
    }
    [self cachedBlockListResWithPath:mainURL res:@(isBlock)];
    return isBlock;
}

- (BOOL)isURLInBlockListWithSchme:(NSString *)scheme
                             host:(NSString *)host
                             path:(NSString *)path {
    path = [path hasSuffix:@"/"] ? path : [path stringByAppendingString:@"/"];
    NSString *mainURL = [NSString stringWithFormat:@"%@://%@%@", scheme?:@"", host?:@"", path?:@""];
    return [self isURLInBlockListWithMainURL:mainURL];
}

#pragma mark allowed url judge
- (BOOL)isURLInAllowList:(NSString *)urlString
{
    NSArray *allowList = [self apiAllowList];
    if (![allowList isKindOfClass:[NSArray class]]) {
        return NO;
    }
    if (!allowList || allowList.count<=0) {
        return NO;
    }
    if (urlString) {
        if (![urlString isKindOfClass:[NSString class]]) {
            return NO;
        }
        for(NSString *allowURL in allowList){
            if ([allowURL isKindOfClass:[NSString class]]) {
                if ([urlString rangeOfString:allowURL].location != NSNotFound) {
                    return YES;
                }
                // check if match with regular expression
                @autoreleasepool {
                    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:allowURL
                                                                                                options:0
                                                                                                  error:nil];
                    NSArray *matches = [expression matchesInString:urlString
                                                           options:0
                                                             range:NSMakeRange(0, urlString.length)];
                    if (matches.count > 0) {
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

- (BOOL)isURLInAllowListWithMainURL:(NSString *)mainURL {
    NSArray *allowList = [self apiAllowList];
    if (![allowList isKindOfClass:[NSArray class]]) {
        return NO;
    }
    if (!allowList || allowList.count<=0) {
        return NO;
    }
    if (![mainURL isKindOfClass:[NSString class]]) {
        return NO;
    }

    if (!mainURL || mainURL.length == 0) {
        return NO;
    }

    NSNumber *res = [self pathCachedAllowListResWithPath:mainURL];
    if (res) {
        return [res boolValue];
    }

    BOOL isAllow = NO;
    
    if(self.allowedListOptEnabled) {
        isAllow = [self isAllowedURLUseRegularOptWithURL:mainURL];
        [self cachedAllowListResWithPath:mainURL res:@(isAllow)];
        return isAllow;
    }
    
    for(NSString *allowURL in allowList){
        if ([allowURL isKindOfClass:[NSString class]]) {
            @autoreleasepool {
                if ([mainURL rangeOfString:allowURL].location != NSNotFound) {
                    isAllow = YES;
                    break;
                }

                if ([mainURL rangeOfString:allowURL options:NSRegularExpressionSearch].location != NSNotFound) {
                    isAllow = YES;
                    break;
                }
            }
        }
    }
    [self cachedAllowListResWithPath:mainURL res:@(isAllow)];
    return isAllow;
}

- (BOOL)isAllowedURLUseRegularOptWithURL:(NSString *)url {
    NSArray<NSString *> *stringRuleList = self.stringAllowedRuleList;
    for(NSString *stringRule in stringRuleList) {
        @autoreleasepool {
            if ([url containsString:stringRule]) {
                return YES;
            }
        }
    }
    
    NSArray<NSDictionary *> *regularRuleList = self.regularAllowedRuleList;
    for(NSDictionary *regularRuleDict in regularRuleList) {
        @autoreleasepool {
            NSString *ruleString = [regularRuleDict hmd_stringForKey:kHMDNetworkConfigAllowedRuleString];
            if ([url containsString:ruleString]) {
                return YES;
            }
            NSRegularExpression *ruleExpression = [regularRuleDict hmd_objectForKey:kHMDNetworkConfigAllowedRuleExpr
                                                                              class:[NSRegularExpression class]];
            NSArray *matches = [ruleExpression matchesInString:url
                                                    options:0
                                                      range:NSMakeRange(0, url.length)];
            if(matches.count > 0) {
                return YES;
            }
        }
    }

    return NO;
}

- (BOOL)isURLInAllowListWithScheme:(NSString *)scheme
                              host:(NSString *)host
                              path:(NSString *)path {
    path = [path hasSuffix:@"/"] ? path : [path stringByAppendingString:@"/"];
    NSString *mainURL = [NSString stringWithFormat:@"%@://%@%@", scheme?:@"", host?:@"", path?:@""];
    return [self isURLInAllowListWithMainURL:mainURL];
}

- (void)cachedAllowListResWithPath:(NSString *)path res:(NSNumber *)res{
    [self.allowListCache setObject:res?:@(NO) forKey:path?:@""];
}

- (NSNumber *)pathCachedAllowListResWithPath:(NSString *)path {
    NSNumber *cached = [self.allowListCache objectForKey:path?:@""];
    return cached;
}

- (void)cachedBlockListResWithPath:(NSString *)path res:(NSNumber *)res{
    [self.blockListCache setObject:res?:@(NO) forKey:path?:@""];
}

- (NSNumber *)pathCachedBlockListResWithPath:(NSString *)path {
    NSNumber *cached = [self.blockListCache objectForKey:path?:@""];
    return cached;
}

- (BOOL)isHeaderInAllowHeaderList:(NSDictionary *)requestHeader {
    BOOL inAllowHeader = NO;
    // 如果 request header 为空,或者不是 NSDictionary 直接返回
    if (!requestHeader || ![requestHeader isKindOfClass:[NSDictionary class]]) {
        return inAllowHeader;
    }
    // 遍历 apiAllowHeaderList 中的期望类型
    for (NSDictionary *typeInfo in self.apiAllowHeaderList) {
        if (![typeInfo isKindOfClass:[NSDictionary class]]) { continue; }
        NSString *type = [typeInfo hmd_objectForKey:@"type" class:[NSString class]];
        if (!type) { continue;}
        if ([type isEqualToString:@"regex"]) { // 全匹配类型的, header 中的 value 要和配置的一样
            NSString *key = [typeInfo hmd_objectForKey:@"key" class:[NSString class]];
            NSString *value = [typeInfo hmd_objectForKey:@"value" class:[NSString class]];
            if (!key || !value) { continue; }
            NSString *headerValue = [requestHeader hmd_objectForKey:key class:[NSString class]];
            if (headerValue && [headerValue isEqualToString:value]) {
                inAllowHeader = YES;
                break;
            }
        } else if ([type isEqualToString:@"exist"]) { // 只要 header 中有这个 key 就上报
            NSString *key = [typeInfo hmd_objectForKey:@"key" class:[NSString class]];
            if (!key) { continue; }
            NSString *headerValue = [requestHeader hmd_objectForKey:key class:[NSString class]];
            if (headerValue && headerValue.length > 0) {
                inAllowHeader = YES;
                break;
            }
        } else if ([type isEqualToString:@"not_exist"]) { // 只要 header 中没有这个 key 就上报
            NSString *key = [typeInfo hmd_objectForKey:@"key" class:[NSString class]];
            if (!key) { continue; }
            NSString *headerValue = [requestHeader hmd_objectForKey:key class:[NSString class]];
            if (!headerValue || headerValue.length == 0) {
                inAllowHeader = YES;
                break;
            }
        }
    }

    return inAllowHeader;
};

@end
