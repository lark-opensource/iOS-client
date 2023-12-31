// Copyright 2020 The Lynx Authors. All rights reserved.

#import <Lynx/LynxDynamicComponentFetcher.h>
#import <Lynx/LynxEvent.h>
#import <Lynx/LynxResourceProvider.h>
#import <Lynx/LynxTemplateRender.h>
#import <Lynx/LynxTouchEvent.h>
#import <Lynx/LynxUIOwner.h>
@class LynxGetUIResultDarwin;
@class LynxEventDetail;

@interface LynxTemplateRender ()

@property(nonatomic, readonly) LynxUIOwner *uiOwner;
@property(nonatomic, assign) long initStartTiming;
@property(nonatomic, assign) long initEndTiming;
@property(nonatomic, readonly) id<LynxDynamicComponentFetcher> fetcher;

- (NSInteger)redBoxImageSizeWarningThreshold;
- (bool)sendSyncTouchEvent:(LynxTouchEvent *)event;
- (void)sendCustomEvent:(LynxCustomEvent *)event;
- (void)onPseudoStatusChanged:(int32_t)tag
                fromPreStatus:(int32_t)preStatus
              toCurrentStatus:(int32_t)currentStatus;

- (void)didMoveToWindow:(BOOL)windowIsNil;
- (void)hotModuleReplace:(NSString *)message withParams:(NSDictionary *)params;
- (void)loadComponent:(NSData *)tem withURL:(NSString *)url withCallbackId:(int32_t)callbackId;
- (void)getI18nResourceForChannel:(NSString *)channel withFallbackUrl:(NSString *)url;

- (void)runOnTasmThread:(dispatch_block_t)task;
- (void)onLynxEvent:(LynxEventDetail *)event;
@end
