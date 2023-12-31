//
//  TTNetworkUtil.m
//  Pods
//
//  Created by ZhangLeonardo on 15/9/6.
//
//

#import "TTNetworkUtil.h"
#import "TTNetworkManagerLog.h"
#import "TTNetworkDefine.h"

#import <CommonCrypto/CommonDigest.h>
#import <BDDataDecorator/NSData+DataDecorator.h>

int g_request_timeout = 15;
int g_request_count_network_changed = 0;
double g_concurrent_request_connect_interval = 4.0;
double g_concurrent_request_delta_timeout = 1.0;


NSString * base64EncodedString(NSData *data) {
    
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

static NSString * URLEncodedString(NSString *input)
{
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                             (CFStringRef)input,
                                                                                             NULL,
                                                                                             CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                             kCFStringEncodingUTF8));
    return result;
}

NSString *combineQueryNameAndValue(NSString *input, NSString *name, NSString *value, BOOL isValidQuery) {
    if (!input) {
        if (isValidQuery) {
            input = [NSString stringWithFormat:@"%@=%@", name, value ];
        } else {
            input = [NSString stringWithFormat:@"%@", name ];
        }
    } else {
        if (isValidQuery) {
            input = [NSString stringWithFormat:@"%@&%@=%@", input, name, value ];
        } else {
            input = [NSString stringWithFormat:@"%@&%@", input, name ];
        }
    }
    return input;
}

static const char *kSensitiveParams[] = {"device_id", "device_type", "openudid", "idfa", "idfv"};

NSString* filterSensitiveParams(NSString *inputUrl, NSString **outputUrl, BOOL onlyInHeader, BOOL keepPlainQuery) {
    static NSMutableSet<NSString *> *filterSet = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        filterSet = [[NSMutableSet alloc] init];
        for (int i = 0; i < 5; ++i) {
            [filterSet addObject:@(kSensitiveParams[i])];
        }
    });
    
    NSURL *url = [NSURL URLWithString:inputUrl];
    if (!url) {
        if (outputUrl) {
            *outputUrl = inputUrl;
        }
        return nil;
    }
    
    NSString *needEncryptedString = nil;
    NSString *rawString = nil;
    
    NSURLComponents *components = [NSURLComponents componentsWithString:inputUrl];
    
    NSString *query = url.query;
    
    NSArray<NSString *> *queryItems = [query componentsSeparatedByString:@"&"];
    //LOGI(@"query items = %@", queryItems);
    for (NSString *item in queryItems) {
        if ([item isEqualToString:@""]) {
            //get rid of blank character between &&(like xxx&&yyy)
            continue;
        }
        
        NSString *name = nil;
        NSString *value = nil;
        BOOL isValidQuery = YES;
        NSRange queryRange = [item rangeOfString:@"="];
        if (queryRange.location == NSNotFound) {
            isValidQuery = NO;
            name = item;
        } else {
            //separate name and value by the first '='
            name = [item substringToIndex:queryRange.location];
            value = [item substringFromIndex:queryRange.location + 1];
        }
        
        if ([filterSet containsObject:name]) {
//            LOGI(@"Found sensitive param: %@=%@", name, value);
            needEncryptedString = combineQueryNameAndValue(needEncryptedString, name, value, isValidQuery);
        } else {
//            LOGI(@"Found none sensitive param: %@=%@", name, value);
            rawString = combineQueryNameAndValue(rawString, name, value, isValidQuery);
        }
    }
    
    //TODO: NSURLQueryItem is iOS 8 only, how about iOS 7 ????
    //    for (NSURLQueryItem *item in components.queryItems) {
    //
    //        if ([filterSet containsObject:item.name]) {
    //            LOGI(@"Found sensitive param: %@=%@", item.name, item.value);
    //            if (!needEncryptedString) {
    //                needEncryptedString = [NSString stringWithFormat:@"%@=%@", item.name, item.value ];
    //            } else {
    //                needEncryptedString = [NSString stringWithFormat:@"%@&%@=%@", needEncryptedString, item.name, item.value ];
    //            }
    //        } else {
    //            LOGI(@"Found none sensitive param: %@=%@", item.name, item.value);
    //            if (!rawString) {
    //                rawString = [NSString stringWithFormat:@"%@=%@", item.name, item.value ];
    //            } else {
    //                rawString = [NSString stringWithFormat:@"%@&%@=%@", rawString, item.name, item.value ];
    //            }
    //        }
    //    }
    
    if (needEncryptedString) {
//        LOGI(@"Need Encrypted param: %@", needEncryptedString);
        NSData *data = [needEncryptedString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSData *resultData = [data bd_dataByDecorated];
        if (resultData != nil) {
            NSString *base64Encoded = base64EncodedString(resultData);
            NSString *urlEncoded = URLEncodedString(base64Encoded);
            
            if (keepPlainQuery) {
                rawString = query;
            }
            
//            LOGI(@"Original base64Encoded = %@ \n urlEncoded url = %@", base64Encoded, urlEncoded);
            if (!onlyInHeader) {
                NSString *queryString = nil;
                if (rawString) {
                    queryString = [NSString stringWithFormat:@"ss_queries=%@&%@", urlEncoded, rawString];
                } else {
                    queryString = [NSString stringWithFormat:@"ss_queries=%@", urlEncoded];
                }
                
//                LOGI(@"query string = %@", queryString);
                components.percentEncodedQuery = queryString;
            } else {
                components.percentEncodedQuery = rawString;
            }
            
            
            NSString *finalURL = components.URL.absoluteString;
            
//            LOGI(@"Original url = %@ \n encrypted url = %@", inputUrl, finalURL);
            
            if (outputUrl) {
                *outputUrl = finalURL;
            }
            return urlEncoded;
            
        } else {
            if (outputUrl) {
                *outputUrl = inputUrl;
            }
            return nil;
        }
        
    } else {
        if (outputUrl) {
            *outputUrl = inputUrl;
        }
        return nil;
    }
}


@implementation QueryPairObject

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value {
    if (self = [super init]) {
        self.key = key;
        self.value = value;
    }
    
    return self;
}

@end



@implementation TaskDetailInfo

- (instancetype)init {
    if (self = [super init]) {
        _host = @"";
        _start = 0;
        _end = 0;
        _netError = 0;
        _httpCode = 0;

        _dispatchedHost = @"";
        _dispatchTime = -1;
    }
    return self;
}

@end


@implementation TTNetworkUtil


+ (NSURL *)URLWithURLString:(NSString *)str
{
    if (isEmptyStringForNetworkUtil(str)) {
        return nil;
    }
    NSString * fixStr = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSURL * u = [NSURL URLWithString:fixStr];
    if (!u) {
        u = [NSURL URLWithString:[fixStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    return u;
}

+ (NSURL *)URLWithURLString:(NSString *)str baseURL:(NSURL *)baseURL
{
    NSURL * url = nil;
    NSString * fixStr = nil;
    fixStr = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    url = [NSURL URLWithString:fixStr relativeToURL:baseURL];
    if (!url) {
        url = [NSURL URLWithString:[fixStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] relativeToURL:baseURL];
    }
    return url;
}

+ (NSString*)URLString:(NSString *)URLStr appendCommonParams:(NSDictionary *)commonParams
{
    if ([commonParams count] == 0 || isEmptyStringForNetworkUtil(URLStr)) {
        return URLStr;
    }
    URLStr = [URLStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString *sep = @"?";
    if ([URLStr rangeOfString:@"?"].location != NSNotFound) {
        sep = @"&";
    }
    
    NSMutableString *query = [NSMutableString new];
    for (NSString *key in [commonParams allKeys]) {
        [query appendFormat:@"%@%@=%@", sep, key, commonParams[key]];
        sep = @"&";
    }
    
    NSString *result = [NSString stringWithFormat:@"%@%@", URLStr, query];
    if ([NSURL URLWithString:result]) {
        return result;
    }
    
    if ([NSURL URLWithString:URLStr]) {
        NSString *escapted_query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if (escapted_query) {
            // if the query contains 'non-escape' character, the query is invalid and returns nil.
            NSString *result = [NSString stringWithFormat:@"%@%@", URLStr, escapted_query];
            if ([NSURL URLWithString:result]) {
                return result;
            }
        }
    }

    // The URLStr is invalid. It may contain space, or 'non-escape' character.
    return [result stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)webviewURLString:(NSString *)URLStr appendCommonParams:(NSDictionary *)commonParams {
    if ([commonParams count] == 0 || isEmptyStringForNetworkUtil(URLStr)) {
        return URLStr;
    }
    
    URLStr = [URLStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *urlStrWithoutFragment = [URLStr componentsSeparatedByString:@"#"].firstObject;
    NSString *urlStrAfterAppendParams = [TTNetworkUtil URLString:urlStrWithoutFragment appendCommonParams:commonParams];
    
    NSString *fragment = [NSURL URLWithString:URLStr].fragment;
    if (!isEmptyStringForNetworkUtil(fragment)) {
        urlStrAfterAppendParams = [NSString stringWithFormat:@"%@#%@", urlStrAfterAppendParams, fragment];
    }
    return urlStrAfterAppendParams;
}

+ (NSString *)filterSensitiveParams:(NSString *)inputUrl outputUrl:(NSString **)outputUrl onlyInHeader:(BOOL)onlyInHeader keepPlainQuery:(BOOL)keepPlainQuery {
    return filterSensitiveParams(inputUrl, outputUrl, onlyInHeader, keepPlainQuery);
}

+ (NSString *)md5Hex:(NSData *)data {
    unsigned char digist[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, digist);
    NSMutableString* outPutStr = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i =0; i < CC_MD5_DIGEST_LENGTH; ++i){
        [outPutStr appendFormat:@"%02X", digist[i]];
    }
    return outPutStr;
}


+ (TTDelayedBlockHandle)dispatchBlockAfterDelay:(int64_t)delta
                                          block:(dispatch_block_t)block {
    __block dispatch_block_t blockToExecute = [block copy];
    __block TTDelayedBlockHandle delayHandleCopy = nil;

    TTDelayedBlockHandle delayHandle = ^(BOOL delay) {
        if (blockToExecute) {
            blockToExecute();
            blockToExecute = nil;
            delayHandleCopy = nil;
        }
    };

    delayHandleCopy = [delayHandle copy];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delta), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (nil != delayHandleCopy) {
            delayHandleCopy(YES);
        }
    });

    return delayHandle;
}

+ (void)dispatchDelayedBlockImmediately:(TTDelayedBlockHandle)delayedHandle {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        delayedHandle(NO);
    });
}

+ (NSString *)calculateFileMd5WithFilePath:(NSString *)filePath {
    // generated and verified the MD5 value of download file.
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if( handle == nil ) {
        LOGD(@"file error");
        return nil;
    }
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    BOOL done = NO;
    while(!done)
    {
        @autoreleasepool {
            NSData* fileData = [handle readDataOfLength: 256 ];
            CC_MD5_Update(&md5, [fileData bytes], (CC_LONG)[fileData length]);
            if( [fileData length] == 0 ) done = YES;
        }
    }
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
    NSString *fileMD5 = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                         digest[0], digest[1],
                         digest[2], digest[3],
                         digest[4], digest[5],
                         digest[6], digest[7],
                         digest[8], digest[9],
                         digest[10], digest[11],
                         digest[12], digest[13],
                         digest[14], digest[15]];
    LOGD(@"dlLog:the generated MD5:%@",fileMD5);
    //completion(fileMD5);
    [handle closeFile];
    return fileMD5;
}

+ (NSString *)getNONEmptyString:(NSString*)str {
    if (str == nil) {
        return @"";
    } else {
        return str;
    }
}

+ (NSString *)getRealPath:(NSURL *)URL {
    NSString *urlStr = URL.absoluteString;
    NSString *path = URL.path;
    NSString *query = URL.query;
    NSString *fragment = URL.fragment;
    if (!query) {
        if (!fragment) {
            if (path.length > 0  && ![path isEqualToString:@"/"] && [urlStr hasSuffix:@"/"]) {
                path = [NSString stringWithFormat:@"%@/",path];
            }
        } else {
            NSString *subUrlString = [urlStr substringToIndex:[urlStr rangeOfString:@"#"].location];
            if (![path isEqualToString:@"/"] && [subUrlString hasSuffix:@"/"]) {
                path = [NSString stringWithFormat:@"%@/",path];
            }
        }
    } else {
        NSString *subUrlString = [urlStr substringToIndex:[urlStr rangeOfString:@"?"].location];
        if (![path isEqualToString:@"/"] && [subUrlString hasSuffix:@"/"]) {
            path = [NSString stringWithFormat:@"%@/",path];
        }
    }
    return path;
}

+ (BOOL)isMatching:(NSString *)target pattern:(TTNetworkManagerPathMatchingType)pattern source:(NSArray<NSString *> *)source {
    NSPredicate *predicate = nil;
    for (NSString *item in source) {
        TTNetAutoReleasePoolBegin
        @try {
            if (pattern == kCommonMatch) {
                predicate = [NSPredicate predicateWithFormat:@" SELF LIKE %@",item];
            } else if (pattern == kPathEqualMatch) {
                predicate = [NSPredicate predicateWithFormat:@" SELF == %@",item];
            } else if (pattern == kPathPrefixMatch) {
                predicate = [NSPredicate predicateWithFormat:@" SELF BEGINSWITH %@",item];
            } else if (pattern == kPathPatternMatch) {
                NSError *error = nil;
                [NSRegularExpression regularExpressionWithPattern:item options:0 error:&error];
                if (error) {
                    LOGE(@"not regex pattern:%@", item);
                } else {
                    predicate = [NSPredicate predicateWithFormat:@" SELF MATCHES %@",item];
                }
            }
            
            if ([predicate evaluateWithObject:target]) {
                return YES;
            }
            predicate = nil;
        } @catch (NSException *e) {
            LOGE(@"target:%@, item:%@, pattern:%@, exception name:%@, reason:%@", target, item, pattern, e.name, e.reason);
            return NO;
        }
        TTNetAutoReleasePoolEnd
    }
    return NO;
}

+ (BOOL)isPathMatching:(NSString *)path pathFilterDictionary:(NSDictionary<TTNetworkManagerPathMatchingType, NSArray<NSString *> *> *)pathFilterDictionary {
    if (!path) {
        return NO;
    }
    NSArray<NSString *> *equalMatchArray = nil;
    NSArray<NSString *> *prefixMatchArray = nil;
    NSArray<NSString *> *patternMatchArray = nil;
    
    for (NSString *pattern in pathFilterDictionary) {
        if (pattern == kPathEqualMatch) {
            equalMatchArray = [pathFilterDictionary objectForKey:kPathEqualMatch];
        } else if (pattern == kPathPrefixMatch) {
            prefixMatchArray = [pathFilterDictionary objectForKey:kPathPrefixMatch];
        } else if (pattern == kPathPatternMatch) {
            patternMatchArray = [pathFilterDictionary objectForKey:kPathPatternMatch];
        }
    }
    
    if (equalMatchArray && [self.class isMatching:path pattern:kPathEqualMatch source:equalMatchArray]) {
        return YES;
    }
    if (prefixMatchArray && [self.class isMatching:path pattern:kPathPrefixMatch source:prefixMatchArray]) {
        return YES;
    }
    if (patternMatchArray && [self.class isMatching:path pattern:kPathPatternMatch source:patternMatchArray]) {
        return YES;
    }
    
    return NO;
}

+ (NSURL *)isValidURL:(NSString *)url callback:(TTNetworkJSONFinishBlock)callback callbackWithResponse:(TTNetworkJSONFinishBlockWithResponse)callbackWithResponse {
    NSURL *nsurl = [NSURL URLWithString:url];
    if (!nsurl) {
        LOGE(@"NSURL is nil");
        NSString *reason = @"url string is invalid";
        NSInteger specificErrorCode = TTNetworkErrorCodeBadURLRequest;
        NSDictionary *userInfo = nil;
        if (url) {
            userInfo = @{kTTNetSubErrorCode : @(NSURLErrorBadURL), NSLocalizedDescriptionKey : reason, NSURLErrorFailingURLErrorKey : url};
        }
        NSError *resultError = [NSError errorWithDomain:kTTNetworkErrorDomain code:specificErrorCode userInfo:userInfo];
        if (callback) {
            callback(resultError, nil);
        }
        if (callbackWithResponse) {
            callbackWithResponse(resultError ,nil ,nil);
        }
    }
    return nsurl;
}

+ (void)parseCommonParamsConfig:(NSDictionary *)data {
    id hostGroup = [data objectForKey:kTNCHostGroup];
    if (hostGroup && [hostGroup isKindOfClass:NSArray.class]) {
        [TTNetworkManager shareInstance].domainFilterArray = [self.class mergeOneNSArray:[[TTNetworkManager shareInstance].domainFilterArray copy] withAnother:hostGroup];
    }
    
    id minExcludingParams = [data objectForKey:kTNCMinParamsExclude];
    if (minExcludingParams && [minExcludingParams isKindOfClass:NSArray.class]) {
        [TTNetworkManager shareInstance].minExcludingParams = [self.class mergeOneNSArray:[[TTNetworkManager shareInstance].minExcludingParams copy] withAnother:minExcludingParams];
    }
    
    NSArray *pathLevelArray = @[kTNCL0Path, kTNCL1Path];
    for (NSString *pathLevel in pathLevelArray) {
        [self.class parseAndMergeCommonParams:data pathLevel:pathLevel];
    }
}

+ (void)parseAndMergeCommonParams:(NSDictionary *)data pathLevel:(NSString *)pathLevel {
    NSMutableDictionary *mergeResultDict = [NSMutableDictionary dictionary];
    id tncPathConfig = [data objectForKey:pathLevel];
    if (tncPathConfig && [tncPathConfig isKindOfClass:NSDictionary.class]) {
        [self.class mergeTNCAndUserPathMatchGroup:tncPathConfig pathLevel:pathLevel result:mergeResultDict];
    }
    
    if ([pathLevel isEqualToString:kTNCL0Path]) {
        [TTNetworkManager shareInstance].maxParamsPathFilterDict = [mergeResultDict copy];
    } else if ([pathLevel isEqualToString:kTNCL1Path]) {
        [TTNetworkManager shareInstance].minParamsPathFilterDict = [mergeResultDict copy];
    }
}

+ (void)mergeTNCAndUserPathMatchGroup:(NSDictionary *)tncConfigDict pathLevel:(NSString *)pathLevel result:(NSMutableDictionary *)mergeDict {
    NSArray *tncMatchGroup = @[kTNCEqualGroup, kTNCPrefixGroup, kTNCPatternGroup];
    for (NSString *matchGroup in tncMatchGroup) {
        [self.class doMerge:tncConfigDict matchGroup:matchGroup pathLevel:pathLevel result:mergeDict];
    }
}

+ (void)doMerge:(NSDictionary *)tncConfigDict matchGroup:(NSString *)tncMatchGroup pathLevel:(NSString *)pathLevel result:(NSMutableDictionary *)mergeDict {
    id configGroup = [tncConfigDict objectForKey:tncMatchGroup];
    NSString *pathMatchGroup = [self.class mapTNCMatchGroupToPath:tncMatchGroup];
    
    if ([pathLevel isEqualToString:kTNCL0Path]) {
        NSArray *maxParamsGroup = [[TTNetworkManager shareInstance].maxParamsPathFilterDict objectForKey:pathMatchGroup];
        [self.class mergeNSArrayAndResetDictValue:mergeDict oneNSArray:configGroup another:maxParamsGroup matchGroup:pathMatchGroup];
    } else if ([pathLevel isEqualToString:kTNCL1Path]) {
        NSArray *minParamsGroup = [[TTNetworkManager shareInstance].minParamsPathFilterDict objectForKey:pathMatchGroup];
        [self.class mergeNSArrayAndResetDictValue:mergeDict oneNSArray:configGroup another:minParamsGroup matchGroup:pathMatchGroup];
    }
}

+ (void)mergeNSArrayAndResetDictValue:(NSMutableDictionary *)mdict oneNSArray:(id)arrayFirst another:(NSArray *)arraySecond matchGroup:(NSString *)pathMatchGroup {
    NSArray *mergeResult;
    if (arrayFirst && [arrayFirst isKindOfClass:NSArray.class]) {
        //only if config of kTNCEqualGroup is NSArray that we will merge
        mergeResult = [self.class mergeOneNSArray:arrayFirst withAnother:arraySecond];
    } else {
        mergeResult = arraySecond;
    }
    if (mergeResult) {
        [mdict setObject:mergeResult forKey:pathMatchGroup];
    }
}

+ (NSString *)mapTNCMatchGroupToPath:(NSString *)tncMatchGroup {
    if ([tncMatchGroup isEqualToString:kTNCEqualGroup]) {
        return kPathEqualMatch;
    } else if ([tncMatchGroup isEqualToString:kTNCPrefixGroup]) {
        return kPathPrefixMatch;
    } else if ([tncMatchGroup isEqualToString:kTNCPatternGroup]) {
        return kPathPatternMatch;
    }
    return nil;
}

+ (NSArray *)mergeOneNSArray:(NSArray *)arrayFirst withAnother:(NSArray *)arraySecond {
    if (!arrayFirst) {
        return arraySecond;
    }
    
    if (!arraySecond) {
        return arrayFirst;
    }
    
    arrayFirst = [arrayFirst arrayByAddingObjectsFromArray:arraySecond];
    return [arrayFirst valueForKeyPath:@"@distinctUnionOfObjects.self"];
}

+ (NSDictionary *)getMinExcludingCommonParams:(NSDictionary *)appLogCommonParams {
    NSArray *minExcludingParams = [TTNetworkManager shareInstance].minExcludingParams;
    if (minExcludingParams && minExcludingParams.count > 0) {
        NSMutableDictionary *mCommonParams = [NSMutableDictionary dictionaryWithDictionary:appLogCommonParams];
        for (NSString *excludingKey in minExcludingParams) {
            [mCommonParams removeObjectForKey:excludingKey];
        }
        
        return [mCommonParams copy];
    } else {
        return appLogCommonParams;
    }
}

+ (NSString *)loadTTNetOCVersionFromPlist {
    //static lib
    NSString *ttnetOCVersion = nil;
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"TTNetVersion" ofType:@"plist"];
    NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    ttnetOCVersion = [data objectForKey:@"ttnetversion"];
    
    //dynamic lib
    if (!ttnetOCVersion) {
        NSURL* bundleURL = [[NSBundle mainBundle] URLForResource:@"Frameworks" withExtension:nil];
        bundleURL = [bundleURL URLByAppendingPathComponent:@"TTNetworkManager"];
        bundleURL = [bundleURL URLByAppendingPathExtension:@"framework"];
        NSBundle *associateBunle = [NSBundle bundleWithURL:bundleURL];
        bundleURL = [associateBunle URLForResource:@"TTNetVersion" withExtension:@"plist"];
        
        NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:bundleURL.path];
        ttnetOCVersion = [data objectForKey:@"ttnetversion"];
    }
    
    if (!ttnetOCVersion) {
        LOGE(@"TTNet OC version is nil!");
    }
    return ttnetOCVersion ?: @"";
}


+ (NSString *)addComponentVersionToRequestLog:(NSString *)originalRequestLog {
    if (!originalRequestLog) {
        LOGI(@"original request log is null");
        return nil;
    }
    if ([originalRequestLog containsString:@"component_version"]) {
        return originalRequestLog;
    }
    
    NSString *ttnetOcVersion = [TTNetworkManager shareInstance].componentVersion;
    NSString *insertVersion = [NSString stringWithFormat:@"\"component_version\":\"%@\",", ttnetOcVersion];
    NSMutableString *revisionRequestLog = [NSMutableString stringWithString:originalRequestLog];
#pragma mark - TODO: if "ttnet_version" changed in C++ requestLog, do the same here
    NSRange destRange = [revisionRequestLog rangeOfString:@"\"ttnet_version\""];
    NSUInteger location = destRange.location;
    NSUInteger length = destRange.length;
    if (length != 0) {
        //insert component_version before ttnet_version in requestLog
        [revisionRequestLog insertString:insertVersion atIndex:location];
    } else {
        //didn't find ttnet_version in C++ requestLog, insert after "other":{
        //this shouldn't happen up to now
        destRange = [revisionRequestLog rangeOfString:@"\"other\":{"];
        location = destRange.location;
        length = destRange.length;
        if (length != 0) {
            [revisionRequestLog insertString:insertVersion atIndex:location + length];
        }
        //do nothing if no "other":{ in C++ requestLog
    }
    
    return [revisionRequestLog copy];
}

+ (NSString *)addCompressLogToRequestLog:(NSString *)originalRequestLog compressLog:(NSString *)compressLog {
    if (!originalRequestLog) {
        LOGI(@"original request log is null");
        return nil;
    }
    if ([originalRequestLog containsString:@"compress"]) {
        return originalRequestLog;
    }


    NSMutableString *revisionRequestLog = [NSMutableString stringWithString:originalRequestLog];
    NSRange destRange = [revisionRequestLog rangeOfString:@"\"dns\":{"];
    NSUInteger location = destRange.location;
    [revisionRequestLog insertString:compressLog atIndex:location];

    return [revisionRequestLog copy];

}

+ (NSDictionary *)convertQueryToDict:(NSString *)queryString {
    if (!queryString) {
        LOGE(@"queryString is nil");
        return nil;
    }
    
    NSArray *queryKVs = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *mutableKVDict = [NSMutableDictionary dictionary];
    for (NSString *kvItem in queryKVs) {
        NSString *key, *value;
        NSRange queryRange = [kvItem rangeOfString:@"="];
        if (queryRange.location == NSNotFound) {
            //if item is NOT a valid query string,put it to kTTNetQueryFilterReservedKey
            [self.class convertQueryInternalWithDuplicatedKey:mutableKVDict key:kTTNetQueryFilterReservedKey value:kvItem];
            continue;
        } else {
            key = [kvItem substringToIndex:queryRange.location];
            value = [kvItem substringFromIndex:queryRange.location + 1];
        }

        [self.class convertQueryInternalWithDuplicatedKey:mutableKVDict key:key value:value];
    }
    return [mutableKVDict copy];
}

+ (void)convertQueryInternalWithDuplicatedKey:(NSMutableDictionary *)mutableKVDict
                                          key:(NSString *)key
                                        value:(NSString *)value {
    //if the key already exist,append the value to a array,even though the value is the same
    if ([[mutableKVDict allKeys] containsObject:key]) {
        id preValue = [mutableKVDict objectForKey:key];
        NSMutableArray *mutableValueArray = nil;
        if ([preValue isKindOfClass:NSMutableArray.class]) {
            [preValue addObject:value];
            mutableValueArray = preValue;
        } else {
            mutableValueArray = [NSMutableArray arrayWithObject:preValue];
            [mutableValueArray addObject:value];
        }

        [mutableKVDict setValue:mutableValueArray forKey:key];
    } else {
        [mutableKVDict setValue:value forKey:key];
    }
}

+ (ImageType)imageTypeDetect:(CFDataRef)data {
    if (!data) {
        return ImageTypeUnknown;
    }
        
    CFIndex length = CFDataGetLength(data);
    if (length < 16) {
        return ImageTypeUnknown;
    }
    
    const char *bytes = (char *)CFDataGetBytePtr(data);
    
    // JPG             FF D8 FF
    if (memcmp(bytes,"\377\330\377",3) == 0) {
        return ImageTypeJPEG;
    }
        
    // JP2
    if (memcmp(bytes + 4, "\152\120\040\040\015", 5) == 0) {
        return ImageTypeJPEG2000;
    }
    
    uint32_t magic4 = *((uint32_t *)bytes);
    switch (magic4) {
        case YY_FOUR_CC(0x4D, 0x4D, 0x00, 0x2A): { // big endian TIFF
            return ImageTypeTIFF;
        } break;
            
        case YY_FOUR_CC(0x49, 0x49, 0x2A, 0x00): { // little endian TIFF
            return ImageTypeTIFF;
        } break;
            
        case YY_FOUR_CC(0x00, 0x00, 0x01, 0x00): { // ICO
            return ImageTypeICO;
        } break;
            
        case YY_FOUR_CC(0x00, 0x00, 0x02, 0x00): { // CUR
            return ImageTypeICO;
        } break;
            
        case YY_FOUR_CC('i', 'c', 'n', 's'): { // ICNS
            return ImageTypeICNS;
        } break;
            
        case YY_FOUR_CC('G', 'I', 'F', '8'): { // GIF
            return ImageTypeGIF;
        } break;
            
        case YY_FOUR_CC(0x89, 'P', 'N', 'G'): {  // PNG
            uint32_t tmp = *((uint32_t *)(bytes + 4));
            if (tmp == YY_FOUR_CC('\r', '\n', 0x1A, '\n')) {
                return ImageTypePNG;
            }
        } break;
            
        case YY_FOUR_CC('R', 'I', 'F', 'F'): { // WebP
            uint32_t tmp = *((uint32_t *)(bytes + 8));
            if (tmp == YY_FOUR_CC('W', 'E', 'B', 'P')) {
                return ImageTypeWebP;
            }
        } break;
    }
    
    uint16_t magic2 = *((uint16_t *)bytes);
    switch (magic2) {
        case YY_TWO_CC('B', 'A'):
        case YY_TWO_CC('B', 'M'):
        case YY_TWO_CC('I', 'C'):
        case YY_TWO_CC('P', 'I'):
        case YY_TWO_CC('C', 'I'):
        case YY_TWO_CC('C', 'P'): { // BMP
            return ImageTypeBMP;
        }
        case YY_TWO_CC(0xFF, 0x4F): { // JPEG2000
            return ImageTypeJPEG2000;
        }
    }
    uint8_t c = *((uint8_t *)bytes);
    if (c == 0x00) {
        //http://nokiatech.github.io/heif/technical.html
        //....ftypheic ....ftypheix ....ftyphevc ....ftyphevx（ImageIO）; mif1,msf1（libttheif_dec）
        uint32_t ftmp = *((uint32_t *)(bytes + 4));
        if (ftmp == YY_FOUR_CC('f', 't', 'y', 'p')) {
            uint32_t etmp = *((uint32_t *)(bytes + 8));
            switch (etmp) {
                case YY_FOUR_CC('h', 'e', 'i', 'c'):
                case YY_FOUR_CC('h', 'e', 'i', 'x'):
                case YY_FOUR_CC('h', 'e', 'v', 'c'):
                case YY_FOUR_CC('h', 'e', 'v', 'x'):
                    return ImageTypeHeic;
                case YY_FOUR_CC('m', 'i', 'f', '1'):
                case YY_FOUR_CC('m', 's', 'f', '1'):
                    return ImageTypeHeif;
            }
        }
    }
    return ImageTypeUnknown;
}

+ (NSString *)imageTypeString:(ImageType)type {
    NSString *text = nil;
    switch (type) {
        case ImageTypeJPEG:
            text = @"jpeg";
            break;
        case ImageTypeJPEG2000:
            text = @"jpeg2000";
            break;
        case ImageTypeTIFF:
            text = @"tiff";
            break;
        case ImageTypeBMP:
            text = @"bmp";
            break;
        case ImageTypeICO:
            text = @"ico";
            break;
        case ImageTypeICNS:
            text = @"icns";
            break;
        case ImageTypeGIF:
            text = @"gif";
            break;
        case ImageTypePNG:
            text = @"png";
            break;
        case ImageTypeWebP:
            text = @"webp";
            break;
        case ImageTypeHeic:
            text = @"heic";
            break;
        case ImageTypeHeif:
            text = @"heif";
            break;
        default:
            text = @"unknow";
            break;
    }
    return text;
}

+ (NSString *)replaceFirstAppearString:(NSString *)originalString target:(NSString *)targetString toString:(NSString *)newString {
    if (!originalString || !targetString || !newString) {
        return originalString;
    }
    
    NSRange targetRange = [originalString rangeOfString:targetString];
    if (targetRange.length <= 0) {
        return originalString;
    }
    
    return [originalString stringByReplacingCharactersInRange:targetRange withString:newString];
}

+ (BOOL)doesQueryContainKey:(NSString *)originalQueryString keyName:(NSString *)keyName keyValue:(NSString *)keyValue {
    if (!originalQueryString || !keyName) {
        return NO;
    }
    
    NSDictionary *queryMap = [TTNetworkUtil convertQueryToDict:originalQueryString];
    if (queryMap && [[queryMap allKeys] containsObject:keyName]) {
        NSString *value = [queryMap objectForKey:keyName];
        if ([value isEqualToString:keyValue]) {
            //no_retry=1 query found,bypass concurrent request
            return YES;
        }
    }
    return NO;
}

@end
