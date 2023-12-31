// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxResourceResponse.h"

const NSInteger LynxResourceResponseCodeSuccess = 0;
const NSInteger LynxResourceResponseCodeFailed = -1;

@implementation LynxResourceResponse

- (instancetype)initWithData:(id)data {
  if (self = [super init]) {
    _data = data;
  }
  return self;
}

- (instancetype)initWithError:(NSError *)error code:(NSInteger)code {
  if (self = [super init]) {
    _error = error;
    _code = code;
  }
  return self;
}

- (bool)success {
  return _data != nil;
}

@end
