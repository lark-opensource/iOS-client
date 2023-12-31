//
//  TTHTTPRequestSerializerBaseChromium.m
//  Pods
//
//  Created by gaohaidong on 11/16/16.
//
//

#import "TTHTTPRequestSerializerBaseChromium.h"
#import "TTNetworkUtil.h"
#import "TTHttpMultipartFormDataChromium.h"
#import "TTHttpRequestChromium.h"
#import "TTNetworkManager.h"
#import "TTNetworkManagerChromium.h"

// same(renamed to avoid conflict) as the AF method: AFPercentEscapedQueryStringKeyFromStringWithEncoding
static NSString * const kTTCharactersToBeEscapedInQueryString = @":/?&=;+!@#$()',*";

static NSString * TTPercentEscapedQueryStringKeyFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kTTCharactersToLeaveUnescapedInQueryStringPairKey = @"[].";
    
    return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kTTCharactersToLeaveUnescapedInQueryStringPairKey, (__bridge CFStringRef)kTTCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

static NSString * TTPercentEscapedQueryStringValueFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)kTTCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}


static inline NSString * TTQueryStringWithParameters(NSDictionary *params)
{
    NSMutableString *query = [NSMutableString new];
    NSString *sep = @"";
    for (NSString *key in [params allKeys]) {
        
        NSString *pair = [NSString stringWithFormat:@"%@=%@", TTPercentEscapedQueryStringKeyFromStringWithEncoding([key description], NSUTF8StringEncoding), TTPercentEscapedQueryStringValueFromStringWithEncoding([params[key] description], NSUTF8StringEncoding)];
        [query appendFormat:@"%@%@", sep, pair];
        sep = @"&";
    }
    return [query copy];
};

@interface TTQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (id)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding;
@end

@implementation TTQueryStringPair

- (id)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.field = field;
    self.value = value;
    
    return self;
}

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return TTPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding);
    } else {
        return [NSString stringWithFormat:@"%@=%@", TTPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding), TTPercentEscapedQueryStringValueFromStringWithEncoding([self.value description], stringEncoding)];
    }
}

@end

NSArray * TTQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        // make a deep copy, fix the crash that the value was mutated while being enumerated.
        NSDictionary *dictionary = [[NSDictionary alloc] initWithDictionary:value copyItems:YES];;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = [dictionary objectForKey:nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:TTQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
      // make a deep copy, fix the crash that the value was mutated while being enumerated.
        NSArray *array = [[NSArray alloc] initWithArray:value copyItems:YES];
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:TTQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
      // make a deep copy, fix the crash that the value was mutated while being enumerated.
        NSSet *set = [[NSSet alloc] initWithSet:value copyItems:YES];
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:TTQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        TTQueryStringPair *pair = [[TTQueryStringPair alloc] initWithField:key value:value];
        if (pair) {
            [mutableQueryStringComponents addObject:pair];
        }
    }
    
    return mutableQueryStringComponents;
}

NSArray * TTQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return TTQueryStringPairsFromKeyAndValue(nil, dictionary);
}

static NSString * TTQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding) {
    if (![parameters isKindOfClass:NSDictionary.class] || parameters.count == 0) {
        return @"";
    }
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (TTQueryStringPair *pair in TTQueryStringPairsFromDictionary(parameters)) {
        NSString *pairURLEncodedString = [pair URLEncodedStringValueWithEncoding:stringEncoding];
        if (pairURLEncodedString) {
            [mutablePairs addObject:pairURLEncodedString];
        }
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}


@interface TTHTTPRequestSerializerBaseChromium()

@property (nonatomic, copy) NSString *defaultUserAgentString;

/**
 HTTP methods for which serialized requests will encode parameters as a query string. `GET`, `HEAD`, and `DELETE` by default.
 */
@property (nonatomic, strong) NSSet *HTTPMethodsEncodingParametersInURI;

@end

@implementation TTHTTPRequestSerializerBaseChromium

+ (NSObject<TTHTTPRequestSerializerProtocol> *)serializer
{
    return [[TTHTTPRequestSerializerBaseChromium alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", @"DELETE", nil];;
    }
    return self;
}

- (TTHttpRequest *)URLRequestWithRequestModel:(TTRequestModel *)requestModel
                                 commonParams:(NSDictionary *)commonParam
{
    NSString *requestURL = [[requestModel _requestURL] absoluteString];
    if (!([requestURL rangeOfString:@"?"].location != NSNotFound ||
          [requestURL hasSuffix:@"/"])) {
        requestURL = [NSString stringWithFormat:@"%@/", requestURL];
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:commonParam];
    if ([requestModel._additionGetParams isKindOfClass:[NSDictionary class]] &&
        [requestModel._additionGetParams count] > 0) {
        [params addEntriesFromDictionary:requestModel._additionGetParams];
    }
    return [self URLRequestWithURL:requestURL
                            params:[requestModel _requestParams]
                            method:[requestModel _requestMethod]
             constructingBodyBlock:[requestModel _bodyBlock]
                      commonParams:params];
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                         headerField:(NSDictionary *)headField
                              params:(NSDictionary *)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam
{
    TTHttpRequest *request = [self URLRequestWithURL:URL
                                              params:params
                                              method:method
                               constructingBodyBlock:bodyBlock
                                        commonParams:commonParam];
    
    if (headField != nil) {
        for (NSString *key in [headField allKeys]) {
            [request setValue:headField[key] forHTTPHeaderField:key];
        }
    }
    
    return  request;
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(NSDictionary *)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam
{
    NSString *fullUrl = [TTNetworkUtil URLString:URL appendCommonParams:commonParam];
    
    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[method uppercaseString]]) {
        if (params && ![params isKindOfClass:NSDictionary.class]) {
            return nil;
        }
        if (params && params.count) {
            NSURL *fullRequestURL = [NSURL URLWithString:fullUrl];
            fullUrl = [[fullRequestURL absoluteString] stringByAppendingFormat:fullRequestURL.query ? @"&%@" : @"?%@", TTQueryStringWithParameters(params)];
        }
    }
    
#ifdef ENABLE_PARAMS_ENCRYPTION
    
    NSString *filteredUrl = nil;
    NSString *encrypted = nil;
    
    if ([TTNetworkManager shareInstance].isEncryptQuery || [TTNetworkManager shareInstance].isEncryptQueryInHeader) {
        encrypted = [TTNetworkUtil filterSensitiveParams:fullUrl outputUrl:&filteredUrl onlyInHeader: ! [TTNetworkManager shareInstance].isEncryptQuery keepPlainQuery:[TTNetworkManager shareInstance].isKeepPlainQuery];
//        LOGD(@"full url = %@, filtered url = %@", fullUrl, filteredUrl);
        
        if (encrypted) {
            fullUrl = filteredUrl;
        }
    }
    
#endif
    
    TTHttpMultipartFormDataChromium *multiForm = nil;
    
    if (![[method lowercaseString] isEqualToString:@"get"] &&
        ![[method lowercaseString] isEqualToString:@"put"] &&
        bodyBlock) {//get and put do not support multipart form
        
        multiForm = [[TTHttpMultipartFormDataChromium alloc] init];
        bodyBlock(multiForm);
    }
    
    TTHttpRequestChromium *ttRequest = [[TTHttpRequestChromium alloc] initWithURL:fullUrl method:method multipartForm:multiForm];
    
#ifdef ENABLE_PARAMS_ENCRYPTION
    if ([TTNetworkManager shareInstance].isEncryptQueryInHeader) {
        if (encrypted) {
            [ttRequest setValue:encrypted forHTTPHeaderField:@"X-SS-QUERIES"];
        }
    }
#endif
    
    if (![self.HTTPMethodsEncodingParametersInURI containsObject:[method uppercaseString]]) {
        // no multipart form data
        if (!bodyBlock) {
//            NSMutableString *query = [NSMutableString new];
//            NSString *sep = @"";
//            for (NSString *key in [params allKeys]) {
//
//                NSString *pair = [NSString stringWithFormat:@"%@=%@", TTPercentEscapedQueryStringKeyFromStringWithEncoding([key description], NSUTF8StringEncoding), TTPercentEscapedQueryStringValueFromStringWithEncoding([params[key] description], NSUTF8StringEncoding)];
//                [query appendFormat:@"%@%@", sep, pair];
//                sep = @"&";
//            }
            
            NSString *query = TTQueryStringFromParametersWithEncoding(params, NSUTF8StringEncoding);
            
            if (![ttRequest valueForHTTPHeaderField:@"Content-Type"]) {
                [ttRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            }
            
            [ttRequest setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
        } else { // multipart form data
            
            ttRequest.params = params;
        }
        
    }
    
    [self _buildRequestHeaders:ttRequest];
    
    return ttRequest;
}

/**
 *  set Head of HTTP request
 *  set no cookie in base and etc,  only set simple User-Agent,  If it cannot meet the demand, it needs to be inherited and rewritten
 *
 *  @param request request to be set
 */
- (void)_buildRequestHeaders:(TTHttpRequestChromium*)request
{
    if (isEmptyStringForNetworkUtil(_defaultUserAgentString)) {
        self.defaultUserAgentString = [self userAgentString];
    }
    
    if (![[request allHTTPHeaderFields] objectForKey:@"User-Agent"]) {
        if (_defaultUserAgentString) {
            [request setValue:_defaultUserAgentString forHTTPHeaderField:@"User-Agent"];
        }
    }
}

- (NSString *)userAgentString {
    return [TTNetworkManagerChromium shareInstance].defaultUserAgent;
}

@end
