// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_NAVIGATOR_LYNXROUTE_H_
#define DARWIN_COMMON_LYNX_NAVIGATOR_LYNXROUTE_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxRoute : NSObject

@property NSString* templateUrl;
@property NSString* routeName;
@property NSDictionary* param;

- (instancetype)initWithUrl:(NSString*)url param:(NSDictionary*)param;

- (instancetype)initWithUrl:(NSString*)url
                  routeName:(NSString*)routeName
                      param:(NSDictionary*)param;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_NAVIGATOR_LYNXROUTE_H_
