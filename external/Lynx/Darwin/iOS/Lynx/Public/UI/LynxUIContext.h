// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxEventEmitter.h"
#import "LynxImageFetcher.h"
#import "LynxLifecycleDispatcher.h"
#import "LynxScreenMetrics.h"
#import "LynxScrollListener.h"

NS_ASSUME_NONNULL_BEGIN
@class LynxRootUI;
@class LynxFontFaceContext;

@class LynxEventHandler;
@class LynxLifecycleDispatcher;
@class LynxShadowNodeOwner;
@class LynxUIExposure;
@class LynxUIIntersectionObserverManager;
@class LynxTimingHandler;
@class LynxGlobalObserver;

@interface LynxUIContext : NSObject
@property(nonatomic, weak, nullable, readwrite) id<LynxImageFetcher> imageFetcher;
@property(nonatomic, weak, nullable, readwrite) id<LynxResourceFetcher> resourceFetcher;
@property(nonatomic, weak, nullable, readwrite) id<LynxScrollListener> scrollListener;
@property(nonatomic, strong, readwrite) id<LynxScrollListener> scrollFluencyMonitor;
@property(nonatomic, weak, nullable, readonly) LynxEventHandler* eventHandler;
@property(nonatomic, weak, nullable, readonly) LynxEventEmitter* eventEmitter;
@property(nonatomic, weak, nullable, readonly) UIView* rootView;
@property(nonatomic, weak, nullable, readwrite) LynxRootUI* rootUI;
@property(nonatomic, weak, nullable, readwrite) LynxFontFaceContext* fontFaceContext;
@property(nonatomic, weak, nullable, readwrite) LynxShadowNodeOwner* nodeOwner;
@property(nonatomic, weak, nullable, readwrite) LynxTimingHandler* timingHandler;
@property(nonatomic, assign, readwrite) int64_t shellPtr;
@property(nonatomic, readwrite) LynxScreenMetrics* screenMetrics;
@property(nonatomic, readonly) LynxUIIntersectionObserverManager* intersectionManager;
@property(nonatomic) LynxUIExposure* uiExposure;
@property(nonatomic, strong, nullable, readonly) NSDictionary* keyframesDict;
@property(nonatomic, nullable) NSDictionary* contextDict;
@property(nonatomic) LynxGlobalObserver* observer;

// settings
@property(nonatomic, readonly) BOOL defaultOverflowVisible;
@property(nonatomic, readonly) BOOL defaultImplicitAnimation;
@property(nonatomic, readonly) BOOL enableTextRefactor;
@property(nonatomic, readonly) BOOL defaultAutoResumeAnimation;
@property(nonatomic, readonly) BOOL defaultEnableNewTransformOrigin;
@property(nonatomic, readonly) BOOL enableEventRefactor;
@property(nonatomic, readonly) BOOL enableA11yIDMutationObserver;
@property(nonatomic, readonly) BOOL enableTextOverflow;
@property(nonatomic, readonly) BOOL enableNewClipMode;
@property(nonatomic, readonly) BOOL enableEventThrough;
@property(nonatomic, readonly) BOOL enableBackgroundShapeLayer;
@property(nonatomic, readonly) BOOL enableFiberArch;
@property(nonatomic, readonly) BOOL enableExposureUIMargin;
@property(nonatomic, readonly) BOOL enableTextLayerRender;
@property(nonatomic, readonly) BOOL enableTextLanguageAlignment;
@property(nonatomic, readonly) BOOL enableXTextLayoutReused;
@property(nonatomic, readonly) NSString* targetSdkVersion;

- (instancetype)initWithScreenMetrics:(LynxScreenMetrics*)screenMetrics;
- (void)updateScreenSize:(CGSize)screenSize;
- (void)onGestureRecognized;
- (void)onGestureRecognizedByUI:(LynxUI*)ui;
- (NSNumber*)getLynxRuntimeId;

- (void)didReceiveResourceError:(NSError*)error;

- (void)reportError:(nonnull NSError*)error;

- (void)didReceiveException:(NSException*)exception
                withMessage:(NSString*)message
                      forUI:(LynxUI*)ui;

- (BOOL)isDev;
- (void)addUIToExposuredMap:(LynxUI*)ui;
- (void)removeUIFromExposuredMap:(LynxUI*)ui;
- (void)removeUIFromIntersectionManager:(LynxUI*)ui;

@end
NS_ASSUME_NONNULL_END
