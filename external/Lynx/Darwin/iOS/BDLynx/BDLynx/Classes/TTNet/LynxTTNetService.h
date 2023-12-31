//  Copyright 2022 The Lynx Authors. All rights reserved.

#if __has_include(<Lynx/LynxNetworkProtocol.h>)

#import <TTNetworkManager/TTDefaultHTTPRequestSerializer.h>
#import <TTNetworkManager/TTHttpRequest.h>
#import "LynxHttpRequest.h"
#import "LynxNetworkProtocol.h"
#import "LynxService.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxRequestSerializer : TTDefaultHTTPRequestSerializer

- (void)requestDidBuild:(TTHttpRequest*)request;

@end

@interface LynxTTNetService : NSObject <LynxNetworkProtocol>

@property(class, readwrite) Class<TTHTTPRequestSerializerProtocol> serializerClass;

- (void)fireRequest:(LynxHttpRequest*)request callback:(LynxHttpResponseBlock)block;

+ (void)requestCallback:(NSError*)error
                    obj:(id)obj
               response:(TTHttpResponse*)response
               callback:(LynxHttpResponseBlock)block;

@end

NS_ASSUME_NONNULL_END

#endif
