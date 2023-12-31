// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_UTILS_LYNXCONVERTUTILS_H_
#define DARWIN_COMMON_LYNX_UTILS_LYNXCONVERTUTILS_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxConvertUtils : NSObject

+ (NSString *)convertToJsonData:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_UTILS_LYNXCONVERTUTILS_H_
