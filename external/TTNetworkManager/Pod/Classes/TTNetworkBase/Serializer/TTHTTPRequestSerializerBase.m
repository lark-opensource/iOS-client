//
//  TTHTTPRequestSerializerBase.m
//  Pods
//
//  Created by ZhangLeonardo on 15/9/6.
//
//

#import "TTHTTPRequestSerializerBase.h"
#import "TTNetworkManager.h"
#import <CommonCrypto/CommonDigest.h>

// for chromium
#import "TTHttpRequestSerializerBaseChromium.h"

@interface TTHTTPRequestSerializerBase()

@property (nonatomic, strong) NSObject<TTHTTPRequestSerializerProtocol> *currentImpl;

@end

@implementation TTHTTPRequestSerializerBase

+ (NSObject<TTHTTPRequestSerializerProtocol> *)serializer
{
    return [[TTHTTPRequestSerializerBase alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        if ([TTNetworkManager getLibraryImpl] == TTNetworkManagerImplTypeLibChromium) {
            self.currentImpl = [TTHTTPRequestSerializerBaseChromium serializer];
        } else {
            NSAssert(false, @"please set the underlining impl lib to TTNetworkManagerImplTypeLibChromium!");
        }
    }
    return self;
}

- (TTHttpRequest *)URLRequestWithRequestModel:(TTRequestModel *)requestModel
                                 commonParams:(NSDictionary *)commonParam
{
    if (!requestModel._requestURL) {
        return nil;
    }
    return [self.currentImpl URLRequestWithRequestModel:requestModel commonParams:commonParam];
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                         headerField:(NSDictionary *)headField
                              params:(NSDictionary *)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam
{
    if (!URL || URL.length == 0) {
        return nil;
    }
    return [self.currentImpl URLRequestWithURL:URL headerField:headField params:params method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(NSDictionary *)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam
{
    if (!URL || URL.length == 0) {
        return nil;
    }
    return [self.currentImpl URLRequestWithURL:URL params:params method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
}

- (NSString *)userAgentString
{
    return [self.currentImpl userAgentString];
}

+ (TTHttpRequest *)hashRequest:(TTHttpRequest *)request body:(NSData *)body
{
    if ([TTNetworkManager shareInstance].urlHashBlock) {
        NSMutableDictionary *parameter = nil;
        if ([body length] > 0) {
            unsigned char digest[CC_MD5_DIGEST_LENGTH];
            CC_MD5(body.bytes, (CC_LONG)[body length], digest);
            
            NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
            for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
                [output appendFormat:@"%02x",digest[i]];
            }
            parameter = [[NSMutableDictionary alloc] init];
            parameter[@"d"] = output;
        }
        request.URL = [TTNetworkManager shareInstance].urlHashBlock(request.URL, parameter);
    }
    return request;
}

@end
