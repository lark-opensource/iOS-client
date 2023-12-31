//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxHttpRequest.h"
#import "LynxServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LynxServiceProtocol;
typedef void (^LynxHttpResponseBlock)(LynxHttpResponse*);

@protocol LynxNetworkProtocol <LynxServiceProtocol>

- (void)fireRequest:(LynxHttpRequest*)request callback:(LynxHttpResponseBlock)block;

@end

NS_ASSUME_NONNULL_END
