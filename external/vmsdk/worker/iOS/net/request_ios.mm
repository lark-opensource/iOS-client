#import "worker/iOS/net/request_ios.h"

@implementation RequestIOS

- (instancetype _Nonnull)init:(NSString* _Nonnull)url {
  return [self init:url method:@"GET"];
}

- (instancetype _Nonnull)init:(NSString* _Nonnull)url method:(NSString* _Nonnull)method {
  return [self init:url method:method headers:nil];
}

- (instancetype _Nonnull)init:(NSString* _Nonnull)url
                       method:(NSString* _Nonnull)method
                      headers:(NSDictionary* _Nullable)headers {
  return [self init:url method:method headers:headers body:nil];
}

- (instancetype _Nonnull)init:(NSString* _Nonnull)url
                       method:(NSString* _Nonnull)method
                      headers:(NSDictionary* _Nullable)headers
                         body:(NSData* _Nullable)body {
  self = [super init];
  _url = [NSURL URLWithString:url];
  _method = method;
  _headers = headers;
  _body = body;
  return self;
}
@end
