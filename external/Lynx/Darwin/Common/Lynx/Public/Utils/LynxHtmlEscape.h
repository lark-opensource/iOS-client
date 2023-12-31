// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_UTILS_LYNXHTMLESCAPE_H_
#define DARWIN_COMMON_LYNX_UTILS_LYNXHTMLESCAPE_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (LynxHtmlEscape)

- (NSString *)stringByUnescapingFromHtml;

@end
NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_UTILS_LYNXHTMLESCAPE_H_
