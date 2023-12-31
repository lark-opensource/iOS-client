
//  Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxGetUIResultDarwin.h"

@implementation LynxGetUIResultDarwin

- (instancetype)init:(NSArray *)ui errCode:(int)err errMsg:(NSString *)msg {
  self = [super init];
  if (self) {
    _uiArray = ui;
    _errCode = err;
    _errMsg = msg;
  }
  return self;
}

@end
