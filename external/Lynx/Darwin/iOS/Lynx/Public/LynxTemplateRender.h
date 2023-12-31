//  Copyright 2020 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LynxConfig.h"
#import "LynxEventTarget.h"
#import "LynxGroup.h"
#import "LynxPerformance.h"
#import "LynxScrollListener.h"
#import "LynxTemplateData.h"
#import "LynxTemplateRenderDelegate.h"
#import "LynxTemplateRenderDelegateExternal.h"
#import "LynxTemplateRenderProtocol.h"

@class LynxResourceProvider;
@class LynxUIIntersectionObserverManager;
@protocol LynxKryptonHelper;
@class LynxGenericReportInfo;

@interface LynxTemplateRender : NSObject <LynxTemplateRenderProtocol>

// If you add an interface that works on both iOS and macOS, please add it to the
// LynxTemplateRenderProtocol

@property(nonatomic, strong, nullable) id<LynxKryptonHelper> kryptonHelper;

/// LynxGenericReportInfo hold some info like templateURL, thread strategy, pageConfig and etc.
@property(nonatomic, strong, readonly, nonnull) LynxGenericReportInfo* genericReportInfo;

@property(nonatomic, assign, readonly) BOOL enableAirStrictMode;

- (void)syncFlush;

- (nullable LynxUI*)findUIByIndex:(int)index;

- (void)setImageFetcherInUIOwner:(id<LynxImageFetcher> _Nullable)imageFetcher;

- (void)setResourceFetcherInUIOwner:(id<LynxResourceFetcher> _Nullable)resourceFetcher;

- (void)setScrollListener:(id<LynxScrollListener> _Nullable)scrollListener;

- (nullable id<LynxEventTarget>)hitTestInEventHandler:(CGPoint)point
                                            withEvent:(UIEvent* _Nonnull)event;

// prefer using `findViewWithName:` than `viewWithName:`.
// `viewWithName:` will be marked deprecated in 1.6
- (nullable UIView*)findViewWithName:(nonnull NSString*)name;
- (nullable UIView*)viewWithName:(nonnull NSString*)name;
- (nullable LynxUI*)uiWithName:(nonnull NSString*)name;
- (nullable UIView*)viewWithIdSelector:(nonnull NSString*)idSelector;
- (nullable LynxUI*)uiWithIdSelector:(nonnull NSString*)idSelector;
- (nonnull NSArray<UIView*>*)viewsWithA11yID:(nonnull NSString*)a11yID;

- (void)setImageDownsampling:(BOOL)enableImageDownsampling;
- (BOOL)enableImageDownsampling;
- (BOOL)enableNewImage;
- (BOOL)trailNewImage;
- (BOOL)enableLayoutOnly;
- (BOOL)enableTextLayerRender;
- (BOOL)enableBackgroundShapeLayer;

- (void)attachLynxView:(LynxView* _Nonnull)lynxView;
- (BOOL)processRender:(LynxView* _Nonnull)lynxView;

- (void)processLayout:(nonnull NSData*)tem
              withURL:(nonnull NSString*)url
             initData:(nullable LynxTemplateData*)data;

- (void)processLayoutWithSSRData:(nonnull NSData*)tem
                         withURL:(nonnull NSString*)url
                        initData:(nullable LynxTemplateData*)data;

- (void)setNeedPendingUIOperation:(BOOL)needPendingUIOperation;

- (void)willMoveToWindow:(nonnull UIWindow*)newWindow;

- (NSSet<NSString*>* _Nonnull)componentSet;

- (nullable LynxUIIntersectionObserverManager*)getLynxUIIntersectionObserverManager;

- (void)resetLayoutStatus;
- (BOOL)isLayoutFinish;
- (float)rootWidth;
- (float)rootHeight;

// It is only used to accept callbacks that calculate the height when lynxView has not been
// attached. AttachLynxView will override this delegate.
- (void)setTemplateRenderDelegate:(LynxTemplateRenderDelegateExternal* _Nonnull)delegate;

- (void)registerCanvasManager:(void* _Nonnull)canvasManager;

- (void)preloadDynamicComponents:(NSArray* _Nonnull)urls;

@end
