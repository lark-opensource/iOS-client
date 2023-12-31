// Copyright 2020 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

#if __has_include(<Lynx/LynxBaseRedBox.h>)
#import <Lynx/LynxBaseRedBox.h>
#import <Lynx/LynxPageReloadHelper.h>
#import <Lynx/LynxView+Internal.h>
#import <Lynx/LynxView.h>
#else
#import <LynxMacOS/LynxBaseRedBox.h>
#import <LynxMacOS/LynxPageReloadHelper.h>
#import <LynxMacOS/LynxView+Internal.h>
#import <LynxMacOS/LynxView.h>
#endif

#import "LynxLogBoxManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxRedBox : NSObject <LynxBaseRedBox>

- (nonnull instancetype)initWithLynxView:(nullable LynxView *)view;
- (void)setReloadHelper:(nullable LynxPageReloadHelper *)reload_helper;
- (void)showErrorMessage:(nullable NSString *)message withCode:(NSInteger)errCode;
- (void)setRuntimeId:(NSInteger)runtimeId;
- (void)show;

@end

@interface LynxLogBox : NSObject

- (instancetype)initWithLogBoxManager:(LynxLogBoxManager *)manager;
- (void)updateViewInfo:(nullable NSString *)url
          currentIndex:(NSInteger)index
            totalCount:(NSInteger)count;
- (void)updateTemplateUrl:(nullable NSString *)url;
- (BOOL)onNewLog:(nullable NSString *)message
       withLevel:(LynxLogBoxLevel)level
       withProxy:(LynxLogBoxProxy *)proxy;
- (BOOL)onNewConsole:(nullable NSDictionary *)message
           withProxy:(LynxLogBoxProxy *)proxy
              isOnly:(BOOL)only;
- (BOOL)isShowing;
- (BOOL)isConsoleOnly;
- (LynxLogBoxLevel)getCurrentLevel;
- (nullable LynxLogBoxProxy *)getCurrentProxy;
- (void)dismissIfNeeded;

@end

NS_ASSUME_NONNULL_END
