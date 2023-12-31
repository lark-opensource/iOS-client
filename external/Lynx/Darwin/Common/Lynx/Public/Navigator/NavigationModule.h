// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_NAVIGATOR_NAVIGATIONMODULE_H_
#define DARWIN_COMMON_LYNX_NAVIGATOR_NAVIGATIONMODULE_H_

#import <Foundation/Foundation.h>
#import "LynxModule.h"

NS_ASSUME_NONNULL_BEGIN

@interface NavigationModule : NSObject <LynxModule>

- (void)registerRoute:(NSDictionary *)routeTable;
- (void)navigateTo:(NSString *)url param:(NSDictionary *)param;
- (void)replace:(NSString *)url param:(NSDictionary *)param;
- (void)goBack;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_NAVIGATOR_NAVIGATIONMODULE_H_
