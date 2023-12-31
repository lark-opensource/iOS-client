// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxPageReloadHelper.h"
#if OS_IOS
#import "LynxUIOwner.h"
#endif
#import "LynxView.h"

typedef void (^LynxDevMenuShowConsoleBlock)(void);

@protocol LynxBaseInspectorOwner <NSObject>

@required

- (nonnull instancetype)initWithLynxView:(nullable LynxView *)view;

- (void)setReloadHelper:(nullable LynxPageReloadHelper *)reloadHelper;

- (void)onTemplateAssemblerCreated:(intptr_t)ptr;

- (void)handleLongPress;

- (void)startCasting:(int)quality width:(int)maxWidth height:(int)maxHeight;

- (void)stopCasting;

- (void)continueCasting;

- (void)pauseCasting;

- (void)setPostUrl:(nullable NSString *)postUrl;

- (void)onLoadFinished;

- (void)reloadLynxView:(BOOL)ignoreCache;

- (void)navigateLynxView:(nonnull NSString *)url;

- (void)emulateTouch:(nonnull NSString *)type
         coordinateX:(int)x
         coordinateY:(int)y
              button:(nonnull NSString *)button
              deltaX:(CGFloat)dx
              deltaY:(CGFloat)dy
           modifiers:(int)modifiers
          clickCount:(int)clickCount;

- (void)call:(NSString *_Nonnull)function withParam:(NSString *_Nullable)params;

- (intptr_t)GetLynxDevtoolFunction;

- (void)dispatchConsoleMessage:(nonnull NSString *)message
                     withLevel:(int32_t)level
                  withTimStamp:(int64_t)timeStamp;

- (void)attach:(nonnull LynxView *)lynxView;

- (intptr_t)createInspectorRuntimeManager;

- (intptr_t)getJavascriptDebugger;

- (intptr_t)getLepusDebugger:(NSString *_Nonnull)url;

- (void)setSharedVM:(LynxGroup *_Nullable)group;

- (void)destroyDebugger;

// methods below only support iOS platform now, empty implementation on macOS now
- (nonnull NSString *)groupID;

- (void)onFirstScreen;

- (void)setShowConsoleBlock:(LynxDevMenuShowConsoleBlock _Nonnull)block;

- (void)reloadLynxView:(BOOL)ignoreCache
          withTemplate:(nullable NSString *)templateBin
         fromFragments:(BOOL)fromFragments
              withSize:(int32_t)size;

- (void)onReceiveTemplateFragment:(nullable NSString *)data withEof:(BOOL)eof;

- (NSInteger)attachDebugBridge;

- (void)endTestbench:(NSString *_Nonnull)filePath;

- (void)RunOnJSThread:(intptr_t)closure;

- (void)onPageUpdate;

#if OS_IOS
- (void)attachLynxUIOwnerToAgent:(nullable LynxUIOwner *)uiOwner;
#endif

- (void)downloadResource:(NSString *_Nonnull)url callback:(LynxResourceLoadBlock _Nonnull)callback;

@end

@protocol LynxViewStateListener <NSObject>

@required
- (void)onLoadFinished;
- (void)onMovedToWindow;
- (void)onEnterForeground;
- (void)onEnterBackground;
- (void)onDestroy;

@end
