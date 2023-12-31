// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxPageReloadHelper.h"

@protocol LynxBaseRedBox <NSObject>

@required

- (nonnull instancetype)initWithLynxView:(nullable LynxView *)view;

- (void)setReloadHelper:(nullable LynxPageReloadHelper *)reload_helper;

- (void)showErrorMessage:(nullable NSString *)message withCode:(NSInteger)errCode;

- (void)attachLynxView:(nonnull LynxView *)lynxView;

- (void)setRuntimeId:(NSInteger)runtimeId;

- (void)show;
@end
