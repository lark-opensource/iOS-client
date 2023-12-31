//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxPageReloadHelper.h"

typedef NS_ENUM(NSInteger, LynxLogBoxLevel) {
  kLevelWarning,
  kLevelError,
  kLevelTest,
};

@protocol LynxBaseLogBoxProxy <NSObject>

@required

- (nonnull instancetype)initWithLynxView:(nullable LynxView *)view;

- (void)onMovedToWindow;

- (void)setReloadHelper:(nullable LynxPageReloadHelper *)reload_helper;

- (void)showLogMessage:(nullable NSString *)message
             withLevel:(LynxLogBoxLevel)level
              withCode:(NSInteger)errCode;

- (void)attachLynxView:(nonnull LynxView *)lynxView;

- (void)reloadLynxView;  // long press, Page.reload, etc

- (void)setRuntimeId:(NSInteger)runtimeId;

- (void)showConsole;

- (void)destroy;

@end
