// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_BASE_LYNXRESOURCESERVICEFETCHER_H_
#define DARWIN_COMMON_LYNX_BASE_LYNXRESOURCESERVICEFETCHER_H_

#import "LynxResourceFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxResourceServiceFetcher : NSObject <LynxResourceFetcher>

+ (BOOL)ensureLynxService;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_BASE_LYNXRESOURCESERVICEFETCHER_H_
