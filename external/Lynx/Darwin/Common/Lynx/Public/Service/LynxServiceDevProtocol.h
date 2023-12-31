//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEDEVPROTOCOL_H_
#define DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEDEVPROTOCOL_H_

#import <Foundation/Foundation.h>

@protocol LynxServiceProtocol;

@protocol LynxServiceDevProtocol <LynxServiceProtocol>

- (BOOL)lynxDebugEnabled;

@end

#endif  // DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICEDEVPROTOCOL_H_
