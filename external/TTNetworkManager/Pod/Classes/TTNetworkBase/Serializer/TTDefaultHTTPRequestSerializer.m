//
//  TTDefaultHTTPRequestSerializer.m
//  Article
//
//  Created by Huaqing Luo on 24/9/15.
//
//

#import "TTDefaultHTTPRequestSerializer.h"
//#import "TTNetworkUtilities.h"
#import "TTNetworkManager.h"
#import "TTNetworkManagerChromium.h"

@implementation TTDefaultHTTPRequestSerializer

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(NSDictionary *)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam
{
    NSURL *origURL = [NSURL URLWithString:URL];
    NSURL *convertUrl = [self _transferedURL:origURL];
    TTHttpRequest *mutableURLRequest = [super URLRequestWithURL:convertUrl.absoluteString params:params method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    
    //Add build-in headers
    [self buildRequestHeaders:mutableURLRequest];
    
    return mutableURLRequest;
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                         headerField:(NSDictionary *)headField
                              params:(NSDictionary *)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    
    NSURL *origURL = [NSURL URLWithString:URL];
    NSURL *convertUrl = [self _transferedURL:origURL];
    
    TTHttpRequest *mutableURLRequest = [super URLRequestWithURL:convertUrl.absoluteString headerField:headField params:params method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    
    //Add build-in headers
    [self buildRequestHeaders:mutableURLRequest];
    
    return mutableURLRequest;
}

- (TTHttpRequest *)URLRequestWithRequestModel:(TTRequestModel *)requestModel commonParams:(NSDictionary *)commonParam {
    //Normalize requestModel;
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:requestModel._requestURL.absoluteString];
    requestModel._uri = urlComponents.path;
    requestModel._host = [urlComponents.scheme stringByAppendingFormat:@"://%@", urlComponents.host];
    
    NSURL *origURL = [requestModel._requestURL copy];
    NSURL *convertUrl = [self _transferedURL:origURL];
    
    requestModel._host = [convertUrl.scheme stringByAppendingFormat:@"://%@", convertUrl.host];
    
    TTHttpRequest *mutableURLRequest = [super URLRequestWithRequestModel:requestModel commonParams:commonParam];
    
    //Add build-in headers
    [self buildRequestHeaders:mutableURLRequest];
    
    return mutableURLRequest;
}

- (NSURL *)_transferedURL:(NSURL *)url {
    return [[TTNetworkManager shareInstance] transferedURL:url];
}

+ (instancetype)serializer
{
    return [[[self class] alloc] init];
}

- (void)buildRequestHeaders:(TTHttpRequest*)request
{
    if (!request || !request.URL) {
        return;
    }
    [self applyCookieHeader:request];
    
    // Build and set the user agent string if the request does not already have a custom user agent specified
    if (![[request allHTTPHeaderFields] objectForKey:@"User-Agent"]) {
        
        NSString *tempUserAgentString = [TTNetworkManagerChromium shareInstance].defaultUserAgent;
        if (tempUserAgentString) {
            
            [request setValue: tempUserAgentString forHTTPHeaderField:@"User-Agent"];
            
        }
    }
    
    // add request time
    NSUInteger requestTime = [[NSDate date] timeIntervalSince1970] * 1000;
    [request setValue:[@(requestTime) stringValue] forHTTPHeaderField:@"tt-request-time"];
}

- (void)applyCookieHeader:(TTHttpRequest*)request
{
    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[[request URL] absoluteURL]];
    
    if ([cookies count] > 0) {
        NSString *cookieHeader = nil;
        for (NSHTTPCookie *cookie in cookies) {
            if (!cookieHeader) {
                cookieHeader = [NSString stringWithFormat: @"%@=%@",[cookie name],[cookie value]];
            } else {
                cookieHeader = [NSString stringWithFormat: @"%@; %@=%@",cookieHeader,[cookie name],[cookie value]];
            }
        }
        if (cookieHeader) {
            [request setValue: cookieHeader forHTTPHeaderField:@"Cookie"];
            [request setValue: cookieHeader forHTTPHeaderField:@"X-SS-Cookie"];
        }
    }
}

- (void)applyCookieHeaderFrom:(NSURL*)url toRequest:(TTHttpRequest*)toRequest
{
    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[url absoluteURL]];
    
    
    if ([cookies count] > 0) {
        NSString *cookieHeader = nil;
        for (NSHTTPCookie *cookie in cookies) {
            if (!cookieHeader) {
                cookieHeader = [NSString stringWithFormat: @"%@=%@",[cookie name],[cookie value]];
            } else {
                cookieHeader = [NSString stringWithFormat: @"%@; %@=%@",cookieHeader,[cookie name],[cookie value]];
            }
        }
        if (cookieHeader) {
            [toRequest setValue: cookieHeader forHTTPHeaderField:@"Cookie"];
            [toRequest setValue: cookieHeader forHTTPHeaderField:@"X-SS-Cookie"];
        }
    }
}

@end

