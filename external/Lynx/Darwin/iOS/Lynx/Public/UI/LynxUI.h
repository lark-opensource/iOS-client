// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxBackgroundManager.h"
#import "LynxBackgroundUtils.h"
#import "LynxComponent.h"
#import "LynxEventSpec.h"
#import "LynxEventTarget.h"
#import "LynxKeyframeManager.h"
#import "LynxUIContext.h"
#import "LynxUITarget.h"
#import "UIScrollView+Nested.h"

NS_ASSUME_NONNULL_BEGIN

@class LynxUI;
@class LynxLayoutAnimationManager;
@class LynxTransformRaw;
@class LynxTransformOriginRaw;
@class LynxAnimationTransformRotation;
@class LynxUICollection;
@class LynxBasicShape;

struct TransOffset {
  CGPoint left_top;
  CGPoint right_top;
  CGPoint right_bottom;
  CGPoint left_bottom;
};
typedef struct TransOffset TransOffset;

enum LynxPropStatus {
  kLynxPropEnable,
  kLynxPropDisable,
  kLynxPropUndefined,
};

@interface LynxUI<__covariant V : UIView*> : LynxComponent <LynxUI*> <LynxEventTarget, LynxUITarget>

@property(nonatomic, assign) NSInteger sign;
@property(nonatomic, readonly) NSString* name;
@property(nonatomic) NSString* idSelector;
@property(nonatomic) NSString* refId;
@property(nonatomic, readonly, copy) NSDictionary* dataset;
@property(nonatomic, copy) NSString* tagName;
@property(nonatomic, strong) LynxBasicShape* clipPath;

// Context info
@property(nonatomic, weak, readonly) LynxUIContext* context;

// Layout info
@property(nonatomic) CGRect frame;  // this frame updated when animation end
@property(nonatomic)
    CGRect updatedFrame;  // this frame is from lynx layout, make sure it's up to date
@property(nonatomic, readonly) UIEdgeInsets padding;
@property(nonatomic, readonly)
    UIEdgeInsets border;  // please use self.backgroundManager.borderWidth for rendering, as here is
                          // the value for layout, not exactly equal to the real value
@property(nonatomic, readonly) UIEdgeInsets margin;

@property(nonatomic, readonly) CGFloat fontSize;
@property(nonatomic, readwrite) CGPoint contentOffset;

// Border info
@property(nonatomic, readonly, nullable) LynxBackgroundManager* backgroundManager;
@property(nonatomic) BOOL clipOnBorderRadius;

// Animate info
@property(nonatomic, readonly, nullable) LynxKeyframeManager* animationManager;

@property(nonatomic, readonly) CGSize frameSize;

@property(nonatomic, readonly) short overflow;
@property(nonatomic, readonly) float scaleX;
@property(nonatomic, readonly) float scaleY;

// default is NO. Return YES if this LynxUI is scroll container, like scroll-view, swiper, list and
// so on.
@property(nonatomic, readonly) BOOL isScrollContainer;

@property(nonatomic, readonly, copy, nullable) NSString* exposureScene;
@property(nonatomic, readonly, copy, nullable) NSString* exposureID;
@property(nonatomic, copy, nullable) NSString* internalSignature;

// transform info
//@property(nonatomic, nullable) NSString* transformStr;
//@property(nonatomic, nullable) NSString* transformOriginStr;

@property(nonatomic, nullable, strong) NSArray<LynxTransformRaw*>* transformRaw;
@property(nonatomic, nullable, strong) LynxTransformOriginRaw* transformOriginRaw;
@property(nonatomic, readonly, nullable, strong) NSArray* perspective;
@property(nonatomic, nonnull, strong) LynxAnimationTransformRotation* lastTransformRotation;
@property(nonatomic) CATransform3D lastTransformWithoutRotate;
@property(nonatomic) CATransform3D lastTransformWithoutRotateXY;
@property(nonatomic, strong) NSArray<NSString*>* accessibilityElementsIds;
@property(nonatomic, strong) NSArray<NSString*>* accessibilityElementsA11yIds;

@property(nonatomic, nullable) NSArray* sticky;
// If you need to do something in onNodeReady later, add them as 'dispath_block_t's here.
@property(nonatomic) NSMutableArray* readyBlockArray;

// block list event to improve performance, default is NO
@property(nonatomic, assign) BOOL blockListEvent;

// lynx rtl direction.Use by rtl subview.
// WARNNNING: In any case other than that you need to override the propsetter for direction and set
// direction of super class, NEVER directly call the setter of directionType.
@property(nonatomic, readwrite) LynxDirectionType directionType;

@property(nonatomic, readwrite) BOOL enableNewTransformOrigin;

@property(nonatomic, strong) NSString* a11yID;

- (instancetype)init;
- (instancetype)initWithView:(nullable V)view;

- (nonnull V)view;
- (nullable V)createView;

- (void)updateFrame:(CGRect)frame
            withPadding:(UIEdgeInsets)padding
                 border:(UIEdgeInsets)border
                 margin:(UIEdgeInsets)margin
    withLayoutAnimation:(BOOL)with;

- (void)updateFrame:(CGRect)frame
            withPadding:(UIEdgeInsets)padding
                 border:(UIEdgeInsets)border
    withLayoutAnimation:(BOOL)with;

- (void)updateSticky:(NSArray*)info;
- (void)checkStickyOnParentScroll:(CGFloat)offsetX withOffsetY:(CGFloat)offsetY;

// layoutDidFinish is called only LayoutRecursively is actually executed
// finishLayoutOperation on the other hand, is always being called, and it is called before
// layoutDidFinish
// TODO: merge layoutDidFinished to finishLayoutOperation in layout_context.cc
- (void)layoutDidFinished;
- (void)finishLayoutOperation;
- (BOOL)hasCustomLayout;
- (void)didInsertChild:(LynxUI*)child atIndex:(NSInteger)index;

- (void)onReceiveUIOperation:(nullable id)value;
- (void)prepareKeyframeManager;

- (void)setRawEvents:(NSSet<NSString*>*)events andLepusRawEvents:(NSSet<NSString*>*)lepusEvents;
- (void)eventDidSet;

- (bool)updateLayerMaskOnFrameChanged;

- (float)getScrollX __attribute__((deprecated("Do not use this after lynx 2.5")));
- (float)getScrollY __attribute__((deprecated("Do not use this after lynx 2.5")));
- (void)resetContentOffset;
- (LynxUI*)getParent;

- (float)getTransationX;
- (float)getTransationY;
- (float)getTransationZ;

- (CALayer*)getPresentationLayer;

- (CGRect)getBoundingClientRect;

- (TransOffset)getTransformValueWithLeft:(float)left
                                   right:(float)right
                                     top:(float)top
                                  bottom:(float)bottom;

- (CGRect)frameFromParent;

// TODO lifecycle
//- (void)willUnload;

- (void)willMoveToWindow:(UIWindow*)window;
- (void)frameDidChange;

- (BOOL)shouldHitTest:(CGPoint)point withEvent:(nullable UIEvent*)event;

- (BOOL)dispatchEvent:(LynxEventDetail*)event;

- (void)onAnimationStart:(NSString*)type
              startFrame:(CGRect)startFrame
              finalFrame:(CGRect)finalFrame
                duration:(NSTimeInterval)duration;
- (void)onAnimationEnd:(NSString*)type
            startFrame:(CGRect)startFrame
            finalFrame:(CGRect)finalFrame
              duration:(NSTimeInterval)duration;

- (void)resetAnimation;
- (void)restartAnimation;
- (void)removeAnimationForReuse;

- (void)sendLayoutChangeEvent;

- (CALayer*)topLayer;
- (CALayer*)bottomLayer;

- (BOOL)isRtl;

- (void)updateCSSDefaultValue;

- (LynxOverflowType)getInitialOverflowType;
- (void)onListCellAppear:(nullable NSString*)itemKey withList:(LynxUICollection*)list;
- (void)onListCellDisappear:(nullable NSString*)itemKey
                      exist:(BOOL)isExist
                   withList:(LynxUICollection*)list;
- (void)onListCellPrepareForReuse:(nullable NSString*)itemKey withList:(LynxUICollection*)list;

- (BOOL)notifyParent;

- (CGFloat)toPtWithUnitValue:(NSString*)unitValue fontSize:(CGFloat)fontSize;

- (void)setLayerValue:(id)value
           forKeyPath:(nonnull NSString*)keyPath
         forAllLayers:(BOOL)forAllLayers;

@end

NS_ASSUME_NONNULL_END
