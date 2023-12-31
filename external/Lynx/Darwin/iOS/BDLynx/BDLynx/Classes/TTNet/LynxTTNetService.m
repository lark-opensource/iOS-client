//  Copyright 2022 The Lynx Authors. All rights reserved.

#if __has_include(<Lynx/LynxNetworkProtocol.h>)

#import "LynxTTNetService.h"
#import <TTNetworkManager/TTNetworkManager.h>

#import <TTNetworkManager/TTNetworkUtil.h>

@implementation LynxRequestSerializer

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(id)parameters
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
  LynxHttpRequest *lynxRequest = (LynxHttpRequest *)parameters;
  TTHttpRequest *request = [super URLRequestWithURL:URL
                                             params:lynxRequest.params
                                             method:method
                              constructingBodyBlock:bodyBlock
                                       commonParams:commonParam];
  [self setRequestBody:request withBody:lynxRequest.HTTPBody];
  [self requestDidBuild:request];
  return request;
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                         headerField:(NSDictionary *)headField
                              params:(id)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
  LynxHttpRequest *lynxRequest = (LynxHttpRequest *)params;
  TTHttpRequest *request = [super URLRequestWithURL:URL
                                        headerField:headField
                                             params:lynxRequest.params
                                             method:method
                              constructingBodyBlock:bodyBlock
                                       commonParams:commonParam];
  [self setRequestBody:request withBody:lynxRequest.HTTPBody];
  [self requestDidBuild:request];
  return request;
}

- (TTHttpRequest *)setRequestBody:(TTHttpRequest *)request withBody:(id)parameters {
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  for (NSString *field in [request.allHTTPHeaderFields allKeys]) {
    if ([[field lowercaseString] isEqualToString:@"content-type"] &&
        [request.allHTTPHeaderFields[field] containsString:@"application/x-protobuf"]) {
      [request setValue:@"application/x-protobuf" forHTTPHeaderField:@"Accept"];
    }
  }
  [request setHTTPBody:parameters];
  return request;
}

- (void)requestDidBuild:(TTHttpRequest *)request {
}

@end

@LynxServiceRegister(LynxTTNetService) @implementation LynxTTNetService

+ (LynxServiceScope)serviceScope {
  return LynxServiceScopeDefault;
}

+ (LynxServiceType)serviceType {
  return LynxServiceTypeNetwork;
}

+ (NSString *)serviceBizID {
  return DEFAULT_LYNX_SERVICE;
}

static Class<TTHTTPRequestSerializerProtocol> _serialzerClass;

+ (void)setSerializerClass:(Class<TTHTTPRequestSerializerProtocol>)clazz {
  _serialzerClass = clazz;
}

+ (Class<TTHTTPRequestSerializerProtocol>)serializerClass {
  return _serialzerClass;
}

+ (void)requestCallback:(NSError *)error
                    obj:(id)obj
               response:(TTHttpResponse *)response
               callback:(LynxHttpResponseBlock)block {
  LynxHttpResponse *resp = [[LynxHttpResponse alloc] init];
  resp.statusCode = response.statusCode;
  resp.clientCode = error.code;
  resp.URL = response.URL;
  resp.MIMEType = response.MIMEType;
  resp.allHeaderFields = response.allHeaderFields;
  resp.body = obj;
  resp.error = error;
  block(resp);
}

- (void)fireRequest:(LynxHttpRequest *)request callback:(LynxHttpResponseBlock)block {
  NSString *url = request.URL.absoluteString;

  [TTNetworkManager.shareInstance
      requestForBinaryWithResponse:url
                            params:request
                            method:request.HTTPMethod
                  needCommonParams:request.addCommonParams
                       headerField:request.allHTTPHeaderFields
                   enableHttpCache:NO
                 requestSerializer:LynxTTNetService.serializerClass ?: LynxRequestSerializer.class
                responseSerializer:nil
                          progress:nil
                          callback:^(NSError *error, id obj, TTHttpResponse *response) {
                            [LynxTTNetService requestCallback:error
                                                          obj:obj
                                                     response:response
                                                     callback:block];
                          }
              callbackInMainThread:NO];
}

@end

#endif
