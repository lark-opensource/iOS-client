//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxNetworkModule.h"
#import "LynxError.h"
#import "LynxLog.h"
#import "LynxNetworkProtocol.h"
#import "LynxService.h"

@implementation LynxNetworkModule

+ (NSDictionary<NSString *, NSString *> *)methodLookup {
  return @{
    @"call" : NSStringFromSelector(@selector(invokeWithRequest:callback:)),
  };
}

+ (NSString *)name {
  return @"__LynxNetwork";
}

- (void)invokeWithRequest:(LynxHttpRequest *)request callback:(LynxCallbackBlock)callback {
  id<LynxNetworkProtocol> networkImpl = LynxService(LynxNetworkProtocol);

  LLogInfo(@"NetworkModule invoke Request with %@ url %@", request.HTTPMethod, request.URL);
  if (networkImpl == nil) {
    LynxHttpResponse *resp = [[LynxHttpResponse alloc] init];
    resp.error =
        [NSError errorWithDomain:LynxErrorDomain
                            code:-1
                        userInfo:@{NSLocalizedDescriptionKey : @"No LynxNetwork Implementation."}];
    return;
  }
  [networkImpl fireRequest:request
                  callback:^(LynxHttpResponse *_Nonnull resp) {
                    callback(resp);
                  }];
}

@end
