// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_NAVIGATOR_LYNXHOLDER_H_
#define DARWIN_COMMON_LYNX_NAVIGATOR_LYNXHOLDER_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LynxView;
@class LynxRoute;

@protocol LynxHolder <NSObject>

- (LynxView *)createLynxView:(LynxRoute *)route;
- (void)showLynxView:(nonnull LynxView *)lynxView name:(nonnull NSString *)name;
- (void)hideLynxView:(nonnull LynxView *)lynxView;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_NAVIGATOR_LYNXHOLDER_H_
