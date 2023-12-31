// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXDYNAMICCOMPONENTFETCHER_H_
#define DARWIN_COMMON_LYNX_LYNXDYNAMICCOMPONENTFETCHER_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^onComponentLoaded)(NSData* _Nullable data, NSError* _Nullable error);

@protocol LynxDynamicComponentFetcher <NSObject>

- (void)loadDynamicComponent:(NSString*)url withLoadedBlock:(onComponentLoaded)block;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_LYNXDYNAMICCOMPONENTFETCHER_H_
