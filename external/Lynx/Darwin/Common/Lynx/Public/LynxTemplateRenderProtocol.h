//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "JSModule.h"
#import "LynxTheme.h"
#import "LynxView.h"

@class LynxDevtool;
@class LynxContext;
@class LynxExtraTiming;
@class LynxTimingHandler;
@class LynxTemplateBundle;

@protocol LynxTemplateRenderProtocol <NSObject>

// Layout, must call invalidateIntrinsicContentSize after change layout props
// If you use view.frame to set view frame, the layout mode will all be
// specified
@property(nonatomic, assign) LynxViewSizeMode layoutWidthMode;
@property(nonatomic, assign) LynxViewSizeMode layoutHeightMode;
@property(nonatomic, assign) CGFloat preferredMaxLayoutWidth;
@property(nonatomic, assign) CGFloat preferredMaxLayoutHeight;
@property(nonatomic, assign) CGFloat preferredLayoutWidth;
@property(nonatomic, assign) CGFloat preferredLayoutHeight;
@property(nonatomic, assign) CGRect frameOfLynxView;
@property(nonatomic, assign) BOOL isDestroyed;
@property(nonatomic, assign) BOOL hasRendered;
@property(nonatomic, strong, readonly, nullable) NSString* url;
@property(nonatomic, assign) BOOL enableJSRuntime;
@property(nonatomic, strong, nonnull) LynxDevtool* devTool;
@property(nonatomic, strong, nonnull) LynxTimingHandler* timingHandler;
@property(nonatomic, strong, nullable) NSMutableDictionary<NSString*, id>* lepusModulesClasses_;

#pragma mark - Init & Clean

- (nonnull instancetype)initWithBuilderBlock:
                            (void (^_Nullable)(NS_NOESCAPE LynxViewBuilder* _Nonnull))builder
                                    lynxView:(LynxView* _Nullable)lynxView;

- (void)reset;
- (void)clearForDestroy;

#pragma mark - Template data

- (void)loadTemplateFromURL:(NSString* _Nonnull)url initData:(LynxTemplateData* _Nullable)data;
- (void)loadTemplateWithoutLynxView:(NSData* _Nonnull)tem
                            withURL:(NSString* _Nonnull)url
                           initData:(LynxTemplateData* _Nullable)data;
- (void)loadTemplate:(nonnull NSData*)tem
             withURL:(nonnull NSString*)url
            initData:(nullable LynxTemplateData*)data;

- (void)loadTemplateBundle:(nonnull LynxTemplateBundle*)bundle
                   withURL:(nonnull NSString*)url
                  initData:(nullable LynxTemplateData*)data;

- (void)loadSSRData:(nonnull NSData*)tem
            withURL:(nonnull NSString*)url
           initData:(nullable LynxTemplateData*)data;
- (void)loadSSRDataFromURL:(nonnull NSString*)url initData:(nullable LynxTemplateData*)data;

- (void)ssrHydrate:(nonnull NSData*)tem
           withURL:(nonnull NSString*)url
          initData:(nullable LynxTemplateData*)data;
- (void)ssrHydrateFromURL:(nonnull NSString*)url initData:(nullable LynxTemplateData*)data;

- (void)updateGlobalPropsWithDictionary:(nullable NSDictionary<NSString*, id>*)data;
- (void)updateGlobalPropsWithTemplateData:(nullable LynxTemplateData*)data;

/**
 * Update template data
 */
- (void)updateDataWithString:(nullable NSString*)data processorName:(nullable NSString*)name;
- (void)updateDataWithDictionary:(nullable NSDictionary<NSString*, id>*)data
                   processorName:(nullable NSString*)name;
- (void)updateDataWithTemplateData:(nullable LynxTemplateData*)data;
- (void)updateDataWithTemplateData:(nullable LynxTemplateData*)data
            updateFinishedCallback:(void (^__nullable)(void))callback;
/**
 * Reset template data
 */
- (void)resetDataWithTemplateData:(nullable LynxTemplateData*)data;
/**
 * Reload template data and global props
 */
- (void)reloadTemplateWithTemplateData:(nullable LynxTemplateData*)data
                           globalProps:(nullable LynxTemplateData*)globalProps;

- (nonnull NSDictionary*)getCurrentData;
- (nonnull NSDictionary*)getPageDataByKey:(nonnull NSArray*)keys;

#pragma mark - Event

- (void)sendGlobalEvent:(nonnull NSString*)name withParams:(nullable NSArray*)params;
- (void)sendGlobalEventToLepus:(nonnull NSString*)name withParams:(nullable NSArray*)params;
- (void)triggerEventBus:(nonnull NSString*)name withParams:(nullable NSArray*)params;

- (void)onEnterForeground;
- (void)onEnterBackground;

- (void)onLongPress;

#pragma mark - Handle error

- (void)onErrorOccurred:(NSInteger)errCode message:(NSString* _Nonnull)errMessage;
- (void)onErrorOccurred:(NSInteger)errCode sourceError:(NSError* _Nonnull)source;

#pragma mark - View

- (void)triggerLayout;
- (void)triggerLayoutInTick;

- (void)updateViewport;
- (void)updateViewport:(BOOL)needLayout;

/**
 * EXPERIMENTAL API!
 * Updating the screen size for lynxview.
 * Updating the screen size does not trigger a re-layout, You should trigger  a re-layout by
 * yourself. It will be useful for the screen size change, like screen rotation. it can make some
 * css properties based on rpx shows better. Multiple views are not supported with different
 * settings!
 * @param width (dp) screen width
 * @param height (dp) screen screen(dp)
 */
- (void)updateScreenMetricsWithWidth:(CGFloat)width height:(CGFloat)height;

- (void)updateFontScale:(CGFloat)scale;

- (void)setTheme:(LynxTheme* _Nullable)theme;
- (void)setLocalTheme:(LynxTheme* _Nonnull)theme;
- (nullable LynxTheme*)theme;

- (void)pauseRootLayoutAnimation;
- (void)resumeRootLayoutAnimation;

- (void)restartAnimation;
- (void)resetAnimation;

- (void)setEnableAsyncDisplay:(BOOL)enableAsyncDisplay;
- (BOOL)enableAsyncDisplay;
- (BOOL)enableTextNonContiguousLayout;

- (void)notifyIntersectionObservers;

#pragma mark - Module

- (void)registerModule:(Class<LynxModule> _Nonnull)module param:(id _Nullable)param;

- (BOOL)isModuleExist:(NSString* _Nonnull)moduleName;

- (nullable JSModule*)getJSModule:(nonnull NSString*)name;

#pragma mark - Get Info

- (NSString* _Nonnull)cardVersion;

- (nonnull LynxConfigInfo*)lynxConfigInfo;

- (nonnull NSDictionary*)getAllJsSource;

- (nullable NSNumber*)getLynxRuntimeId;

- (nonnull LynxContext*)getLynxContext;

- (LynxThreadStrategyForRender)getThreadStrategyForRender;

#pragma mark - Perf

- (void)setExtraTiming:(LynxExtraTiming* _Nonnull)timing;

- (nullable NSDictionary*)getAllTimingInfo;

- (nullable NSDictionary*)getExtraInfo;

- (void)triggerTrailReport;

#pragma mark - Runtime

- (void)startLynxRuntime;

@end
