// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxPageReloadHelper.h"
#import "LynxTemplateData.h"
#import "LynxTemplateRender.h"
#import "LynxView.h"

// Use system macro in header file to avoid host app can not recognize custom macro
#if TARGET_OS_IOS
#import "LynxUIOwner.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface LynxDevtool : NSObject

@property(nonatomic, readwrite) id<LynxBaseInspectorOwner> owner;

- (nonnull instancetype)initWithLynxView:(LynxView *)view debuggable:(BOOL)debuggable;
// - (nonnull instancetype)initWithLynxTemplateRender:(LynxTemplateRender *)templateRender;

- (void)registerModule:(LynxTemplateRender *)render;

- (void)onLoadFromLocalFile:(NSData *)tem withURL:(NSString *)url initData:(LynxTemplateData *)data;

- (void)onLoadFromURL:(NSString *)url initData:(LynxTemplateData *)data postURL:(NSString *)postURL;

- (void)onTemplateAssemblerCreated:(intptr_t)ptr;

- (void)onEnterForeground;

- (void)onEnterBackground;

- (void)onLoadFinished;

- (void)onFirstScreen;

- (void)handleLongPress;

- (void)showErrorMessage:(nullable NSString *)message withCode:(NSInteger)errCode;

- (void)attachLynxView:(LynxView *)lynxView;

#if TARGET_OS_IOS
- (void)attachLynxUIOwner:(nullable LynxUIOwner *)uiOwner;
#endif

- (void)setRuntimeId:(NSInteger)runtimeId;

- (void)onMovedToWindow;

- (void)setSharedVM:(LynxGroup *)group;

- (void)destroyDebugger;

- (void)onPageUpdate;

- (void)downloadResource:(NSString *_Nonnull)url callback:(LynxResourceLoadBlock _Nonnull)callback;

@end

NS_ASSUME_NONNULL_END
