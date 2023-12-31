// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxResourceRequest.h"

@implementation LynxResourceRequest

- (instancetype)initWithUrl:(NSString *)url {
  if (self = [super init]) {
    _url = url;
  }
  return self;
}

- (instancetype)initWithUrl:(NSString *)url andRequestParams:(id)requestParams {
  if (self = [super init]) {
    _url = url;
    _requestParams = requestParams;
  }
  return self;
}

@end
