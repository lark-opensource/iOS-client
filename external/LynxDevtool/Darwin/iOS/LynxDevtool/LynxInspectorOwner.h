// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <Lynx/LynxBaseInspectorOwnerNG.h>
#import <Lynx/LynxPageReloadHelper.h>
#import <Lynx/LynxView+Internal.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxInspectorOwner : NSObject <LynxBaseInspectorOwnerNG>

- (instancetype)init;
- (nonnull instancetype)initWithLynxView:(nullable LynxView *)view;
- (void)setReloadHelper:(nullable LynxPageReloadHelper *)reloadHelper;
- (void)call:(NSString *_Nonnull)function withParam:(NSString *_Nullable)params;

- (intptr_t)GetLynxDevtoolFunction;

- (void)onTemplateAssemblerCreated:(intptr_t)ptr;

- (void)dispatchDocumentUpdated;
- (void)dispatchScreencastVisibilityChanged:(Boolean)status;
- (void)dispatchStyleSheetAdded;

- (void)onLoadFinished;
- (void)onFirstScreen;

- (void)reloadLynxView:(BOOL)ignoreCache;
- (void)reloadLynxView:(BOOL)ignoreCache
          withTemplate:(nullable NSString *)templateBin
         fromFragments:(BOOL)fromFragments
              withSize:(int32_t)size;
- (void)onReceiveTemplateFragment:(nullable NSString *)data withEof:(BOOL)eof;

- (void)navigateLynxView:(nonnull NSString *)url;

- (void)startCasting:(int)quality width:(int)maxWidth height:(int)maxGeight;
- (void)stopCasting;
- (void)continueCasting;
- (void)pauseCasting;
- (LynxView *)getLynxView;

- (void)handleLongPress;

- (NSInteger)getSessionId;

- (void)emulateTouch:(nonnull NSString *)type
         coordinateX:(int)x
         coordinateY:(int)y
              button:(nonnull NSString *)button
              deltaX:(CGFloat)dx
              deltaY:(CGFloat)dy
           modifiers:(int)modifiers
          clickCount:(int)clickCount;

- (void)setConnectionID:(int)connectionID;

- (void)dispatchMessage:(NSString *)message;

- (NSString *)getTemplateUrl;

- (UIView *)getTemplateView;

- (LynxTemplateData *)getTemplateData;

- (NSString *)getTemplateConfigInfo;

- (BOOL)isDebugging;

- (void)dispatchConsoleMessage:(NSString *)message
                     withLevel:(int32_t)level
                  withTimStamp:(int64_t)timeStamp;

- (NSInteger)attachDebugBridge;

- (intptr_t)createInspectorRuntimeManager;

- (void)OnConnectionClose;

- (void)OnConnectionOpen;

- (void)RunOnJSThread:(intptr_t)closure;

- (void)sendTouchEvent:(nonnull NSString *)type sign:(int)sign x:(int)x y:(int)y;

- (intptr_t)getJavascriptDebugger;

- (intptr_t)getLepusDebugger:(NSString *_Nonnull)url;

- (void)setShowConsoleBlock:(LynxDevMenuShowConsoleBlock)block;

- (void)sendMessage:(CustomizedMessage *)message;

- (void)subscribeMessage:(NSString *)type withHandler:(id<MessageHandler>)handler;

- (void)unsubscribeMessage:(NSString *)type;

- (void)setSharedVM:(LynxGroup *_Nullable)group;

- (void)destroyDebugger;

- (int64_t)getRecordID;

- (void)enableRecording:(bool)enable;

- (void)enableTraceMode:(bool)enable;

- (void)sendCardPreviewWithDelay:(int)delay;

- (void)onPageUpdate;

- (void)attachLynxUIOwnerToAgent:(nullable LynxUIOwner *)uiOwner;

- (int)findNodeIdForLocationWithX:(float)x withY:(float)y fromUI:(int)uiSign;

- (NSString *)getLynxUITree;

- (NSString *)getUINodeInfo:(int)id;

- (int)setUIStyle:(int)id withStyleName:(NSString *)name withStyleContent:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
