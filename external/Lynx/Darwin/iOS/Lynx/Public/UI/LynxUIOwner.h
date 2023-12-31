// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxForegroundProtocol.h"
#import "LynxModule.h"
#import "LynxUI.h"
#import "LynxUIContext.h"
#import "LynxUIMethodProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@class LynxView;
@class LynxRootUI;
@class LynxEventHandler;
@class LynxComponentScopeRegistry;
@class LynxWeakProxy;

@protocol LynxBaseInspectorOwner;
@protocol LynxForegroundProtocol;

typedef void (^LynxOnFirstScreenListener)(void);
typedef void (^LynxOnPageUpdateListener)(void);

@interface LynxUIContext (Internal)
@property(nonatomic, weak, nullable, readwrite) id<LynxImageFetcher> imageFetcher;
@property(nonatomic, weak, nullable, readwrite) LynxEventHandler* eventHandler;
@property(nonatomic, weak, nullable, readwrite) LynxEventEmitter* eventEmitter;
@property(nonatomic, weak, nullable, readonly) UIView* rootView;
@property(nonatomic, strong, nullable, readwrite) NSDictionary* keyframesDict;
- (void)mergeKeyframesWithLynxKeyframes:(LynxKeyframes*)keyframes forKey:(NSString*)name;
@end

@interface LynxUIOwner : NSObject

@property(nonatomic, nullable) LynxOnFirstScreenListener onFirstScreenListener;
@property(nonatomic, nullable) LynxOnFirstScreenListener onPageUpdateListener;
@property(nonatomic, readonly) LynxUIContext* uiContext;
@property(nonatomic, readonly) LynxRootUI* rootUI;
@property(nonatomic, readonly) LynxFontFaceContext* fontFaceContext;
@property(nonatomic, readonly) id<LynxBaseInspectorOwner> baseInspectOwner;
@property(nonatomic, weak, readonly) LynxTemplateRender* templateRender;

- (void)attachLynxView:(LynxView* _Nonnull)containerView;
- (instancetype)initWithContainerView:(LynxView*)containerView
                       templateRender:(LynxTemplateRender*)templateRender
                    componentRegistry:(LynxComponentScopeRegistry*)registry
                        screenMetrics:(LynxScreenMetrics*)screenMetrics;

- (LynxUI*)findUIBySign:(NSInteger)sign;
- (LynxUI*)findUIByComponentId:(NSInteger)componentId;

- (LynxUI*)findUIByIdSelector:(NSString*)idSelector withinUI:(LynxUI*)ui;
- (LynxUI*)findUIByIdSelectorInParent:(NSString*)idSelector child:(LynxUI*)child;

- (LynxUI*)findUIByRefId:(NSString*)refId withinUI:(LynxUI*)ui;

- (NSSet<NSString*>*)componentSet;
- (void)componentStatistic:(NSString*)componentName;

- (void)createUIWithSign:(NSInteger)sign
                 tagName:(NSString*)tagName
                eventSet:(NSSet<NSString*>*)eventSet
           lepusEventSet:(NSSet<NSString*>*)lepusEventSet
                   props:(NSDictionary*)props;

- (void)updateUIWithSign:(NSInteger)sign
                   props:(NSDictionary*)props
                eventSet:(NSSet<NSString*>*)eventSet
           lepusEventSet:(NSSet<NSString*>*)lepusEventSet;

- (void)insertNode:(NSInteger)childSign toParent:(NSInteger)parentSign atIndex:(NSInteger)index;

- (void)listWillReuseNode:(NSInteger)sign withItemKey:(NSString*)itemKey;

- (void)detachNode:(NSInteger)sign;

- (void)recycleNode:(NSInteger)sign;

- (void)updateUI:(NSInteger)sign
      layoutLeft:(CGFloat)left
             top:(CGFloat)top
           width:(CGFloat)width
          height:(CGFloat)height
         padding:(UIEdgeInsets)padding
          border:(UIEdgeInsets)border
          margin:(UIEdgeInsets)margin
          sticky:(nullable NSArray*)sticky;

- (void)updateUI:(NSInteger)sign
      layoutLeft:(CGFloat)left
             top:(CGFloat)top
           width:(CGFloat)width
          height:(CGFloat)height
         padding:(UIEdgeInsets)padding
          border:(UIEdgeInsets)border;

- (void)invokeUIMethod:(NSString*)method
                params:(NSDictionary*)params
              callback:(LynxUIMethodCallbackBlock)callback
              fromRoot:(int)componentId
               toNodes:(NSArray*)nodes;

- (void)invokeUIMethodForSelectorQuery:(NSString*)method
                                params:(NSDictionary*)params
                              callback:(LynxUIMethodCallbackBlock)callback
                                toNode:(int)sign;

- (void)willContainerViewMoveToWindow:(UIWindow*)window;
- (void)onReceiveUIOperation:(id)value onUI:(NSInteger)sign;

// layoutDidFinish is called only LayoutRecursively is actually executed
// finishLayoutOperation on the other hand, is always being called, and it is called before
// layoutDidFinish
// TODO: merge layoutDidFinished to finishLayoutOperation in layout_context.cc
- (void)layoutDidFinish;
- (void)finishLayoutOperation:(int64_t)operationID componentID:(NSInteger)componentID;
- (void)onAnimatedNodeReady:(NSInteger)sign;
- (void)onNodeReady:(NSInteger)sign;

- (nullable LynxUI*)uiWithName:(NSString*)name;
- (nullable LynxUI*)uiWithIdSelector:(NSString*)idSelector;
- (nullable LynxWeakProxy*)weakLynxUIWithName:(NSString*)name;

- (void)reset;

- (void)pauseRootLayoutAnimation;
- (void)resumeRootLayoutAnimation;
/**
 *在 cell 复用 ，prepareForReuse 时进行调用，复用成功时调用 restart。
 */
- (void)resetAnimation;
- (void)restartAnimation;

// When LynxView enter foreground, call this function to resume keyframe animation.
- (void)resumeAnimation;

// When LynxView enter foreground
- (void)onEnterForeground;

// When LynxView enter background
- (void)onEnterBackground;

- (void)registerForegroundListener:(id<LynxForegroundProtocol>)listener;

- (void)unRegisterForegroundListener:(id<LynxForegroundProtocol>)listener;

- (void)updateFontFaceWithDictionary:(NSDictionary*)dic;

- (LynxComponentScopeRegistry*)getComponentRegistry;

- (void)didMoveToWindow:(BOOL)windowIsNil;

- (void)updateAnimationKeyframes:(NSDictionary*)keyframesDict;

- (NSArray<LynxUI*>*)uiWithA11yID:(NSString*)a11yID;

- (BOOL)isTagVirtual:(NSString*)tagName;
@end

NS_ASSUME_NONNULL_END
