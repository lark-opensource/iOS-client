//
//  TTVideoEngineNetwork.m
//  Pods
//
//  Created by guikunzhi on 17/1/10.
//
//

#import "TTVideoEngineNetwork.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineUtilPrivate.h"
#import <AssertMacros.h>

static BOOL TTVideoEngineServerTrustIsValid(SecTrustRef serverTrust) {
    BOOL isValid = NO;
    SecTrustResultType result;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    __Require_noErr_Quiet(SecTrustEvaluate(serverTrust, &result), _out);
#pragma clang diagnostic pop

    isValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);

_out:
    return isValid;
}

@interface TTVideoEngineNetwork ()

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *urlRequest;
@property (nonatomic, assign) NSTimeInterval timeout;

@end

@implementation TTVideoEngineNetwork

- (instancetype)initWithTimeout:(NSTimeInterval)timeout {
    if (self = [super init]) {
        _useEphemeralSession = NO;
        _timeout = timeout;
    }
    return self;
}

- (void)setupSession {
    if (_session == nil) {
        NSURLSessionConfiguration *sessionConfiguration = nil;
        if (self.useEphemeralSession){
            sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        } else {
            sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
        sessionConfiguration.timeoutIntervalForRequest = self.timeout;
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:[[NSOperationQueue alloc] init]];
    }
}

- (void)configPostTaskWithURL:(NSURL *)url params:(NSDictionary *)paramsdata headers:(NSDictionary *)headers completion:(void (^)(id _Nullable jsonObject, NSError * _Nullable error))completionHandler {
    [self setupSession];
    
//    NSData *bodydata = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
//    [urlRequest setValue:@"TTVideoEngine(iOS)" forHTTPHeaderField:@"User-Agent"];
    for (NSString *key in [headers allKeys]) {
        [urlRequest setValue:[headers valueForKey:key] forHTTPHeaderField:key];
    }
    [urlRequest setValue:@"TTVideoEngine(iOS)" forHTTPHeaderField:@"User-Agent"];
    urlRequest.HTTPMethod = @"POST";
    NSError *error = nil;
    urlRequest.HTTPBody = [NSJSONSerialization dataWithJSONObject:paramsdata options:0 error:&error];
//    [urlRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    self.urlRequest = [self.session dataTaskWithRequest:[urlRequest copy]
                                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                          if (error) {
                                              completionHandler(nil,error);
                                          }
                                          else {
                                              NSInteger statusCode = -1;
                                              if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                  statusCode = ((NSHTTPURLResponse *)response).statusCode;
                                              }
                                              if ([response isKindOfClass:[NSHTTPURLResponse class]] && (statusCode == 200 || statusCode == 403)) {
                                                  NSError *jsonError = nil;
                                                  id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:nil error:&jsonError];
                                                  if (jsonError) {
                                                      NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:jsonError.userInfo];
                                                      if (data) {
                                                          const char *cStr = (const char *)[data bytes];
                                                          NSString *body = nil;
                                                          if (cStr != NULL) {
                                                              body = [NSString stringWithUTF8String:cStr];
                                                          }
                                                          if (body) {
                                                              [userInfo setValue:body forKey:@"body"];
                                                          } else {
                                                              [userInfo setValue:@"" forKey:@"body"];
                                                          }
                                                      }
                                                      NSError *parseError = [NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo code:TTVideoEngineErrorHTTPNot200 userInfo:userInfo];
                                                      
                                                      completionHandler(nil,parseError);
                                                  }
                                                  else {
                                                      NSError *retError = nil;
                                                      if (statusCode != 200) {
                                                          retError = [NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo code:TTVideoEngineErrorHTTPNot200 userInfo:@{@"description": response.description ?:@""}];
                                                      }
                                                      completionHandler(jsonObject,retError);
                                                  }
                                              }
                                              else {
                                                  completionHandler(nil,[NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo code:TTVideoEngineErrorHTTPNot200 userInfo:@{@"description": response.description ?:@""}]);
                                              }
                                          }
                                      }];
}

- (void)configTaskWithURL:(NSURL *)url completion:(void (^)(id _Nullable jsonObject, NSError * _Nullable error))completionHandler
{
    [self configTaskWithURL:url params:nil headers:nil completion:completionHandler];
}

- (void)configTaskWithURL:(NSURL *)url params:(NSDictionary *)params headers:(NSDictionary *)headers completion:(void (^)(id _Nullable jsonObject, NSError * _Nullable error))completionHandler {
    [self setupSession];
    
    NSString *originURL = url.absoluteString;
    NSMutableString *requestURL = [NSMutableString stringWithString:originURL];
    if (params != nil) {
        NSRange range = [originURL rangeOfString:@"?"];
        if (range.location == NSNotFound) {
            [requestURL appendString:@"?"];
        }
        else if (range.location != originURL.length - 1) {
            [requestURL appendString:@"&"];
        }
        int keysNum = [params allKeys].count;
        for (int i = 0; i < keysNum; i++) {
            NSString *key = [[params allKeys] objectAtIndex:i];
            NSString *value = [params objectForKey:key];
            NSString *encodedKey = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            NSString *encodedValue = nil;
            encodedValue = [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [requestURL appendString:[NSString stringWithFormat:@"%@=%@",encodedKey,encodedValue]];
            if (i != keysNum - 1) {
                [requestURL appendString:@"&"];
            }
        }
    }
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL]];
    [urlRequest setValue:@"TTVideoEngine(iOS)" forHTTPHeaderField:@"User-Agent"];
    for (NSString *key in [headers allKeys]) {
        [urlRequest setValue:[headers valueForKey:key] forHTTPHeaderField:key];
    }
    
    self.urlRequest = [self.session dataTaskWithRequest:[urlRequest copy]
                                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                          if (error) {
                                              completionHandler(nil,error);
                                          }
                                          else {
                                              id jsonObject = nil;
                                              if (data != nil && data.length > 0) {
                                                  NSError *jsonError = nil;
                                                  jsonObject = [NSJSONSerialization JSONObjectWithData:data options:nil error:&jsonError];
                                                  if (jsonError) {
                                                      NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:jsonError.userInfo];
                                                      if (data) {
                                                          const char *cStr = (const char *)[data bytes];
                                                          NSString *body = nil;
                                                          if (cStr != NULL) {
                                                              body = [NSString stringWithUTF8String:cStr];
                                                          }
                                                          if (body) {
                                                              [userInfo setValue:body forKey:@"body"];
                                                          } else {
                                                              [userInfo setValue:@"" forKey:@"body"];
                                                          }
                                                      }
                                                      NSError *parseError = [NSError errorWithDomain:kTTVideoErrorDomainHTTPDNS code:TTVideoEngineErrorParseJson userInfo:userInfo];
                                                      completionHandler(nil,parseError);
                                                      return;
                                                  }
                                              }
                                              
                                              NSError *retError = nil;
                                              if (response != nil) {
                                                  NSInteger statusCode = -1;
                                                  if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                      statusCode = ((NSHTTPURLResponse *)response).statusCode;
                                                  }
                                                  
                                                  if (statusCode != 200) {
                                                      retError = [NSError errorWithDomain:kTTVideoErrorDomainHTTPDNS
                                                                                     code:TTVideoEngineErrorHTTPNot200
                                                                                 userInfo:@{@"description": response.description ?:@"",@"resCode":@(statusCode)}];
                                                  }
                                              }
                                              
                                              completionHandler(jsonObject,retError);
                                          }
                                      }];
}

- (void)cancel {
    [self.urlRequest cancel];
}

- (void)resume {
    [self.urlRequest resume];
}

- (void)invalidAndCancel {
    [self.session invalidateAndCancel];
    self.session = nil;
}

#pragma - mark NSURLSessionDelegate
// HTTPS使用IP地址发送请求，证书校验方法参考 https://github.com/aliyun/alicloud-ios-demo/blob/master/httpdns_ios_demo/httpdns_ios_demo/HTTPSSceneViewController.m
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *_Nullable))completionHandler
{
    if (!challenge) {
        return;
    }
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    
    NSString *host = [[self.urlRequest.currentRequest allHTTPHeaderFields] objectForKey:@"host"];
    if (!host) {
        host = self.urlRequest.currentRequest.URL.host;
    }
    
     if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
         if ([self evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:host]) {
             disposition = NSURLSessionAuthChallengeUseCredential;
             credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
         }
         
     } else {
         disposition = NSURLSessionAuthChallengePerformDefaultHandling;
     }
    
    completionHandler(disposition, credential);
    
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(NSString *)domain
{
    NSMutableArray *policies = [NSMutableArray array];
    if (domain) {
        [policies addObject:(__bridge_transfer id) SecPolicyCreateSSL(true, (__bridge CFStringRef) domain)];
    } else {
        [policies addObject:(__bridge_transfer id) SecPolicyCreateBasicX509()];
    }

    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef) policies);
    return TTVideoEngineServerTrustIsValid(serverTrust);
}

@end
