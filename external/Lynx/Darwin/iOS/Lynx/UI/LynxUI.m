// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxUI.h"
#import "AbsLynxUIScroller.h"
#import "LynxAnimationTransformRotation.h"
#import "LynxBackgroundDrawable.h"
#import "LynxBackgroundUtils.h"
#import "LynxBasicShape.h"
#import "LynxBoxShadowManager.h"
#import "LynxCSSType.h"
#import "LynxColorUtils.h"
#import "LynxContext.h"
#import "LynxConverter+LynxCSSType.h"
#import "LynxConverter+Transform.h"
#import "LynxConverter+UI.h"
#import "LynxEvent.h"
#import "LynxEventHandler+Internal.h"
#import "LynxGlobalObserver.h"
#import "LynxHeroTransition.h"
#import "LynxKeyframeAnimator.h"
#import "LynxLayoutAnimationManager.h"
#import "LynxLog.h"
#import "LynxPropsProcessor.h"
#import "LynxRootUI.h"
#import "LynxSizeValue.h"
#import "LynxTemplateRender+Internal.h"
#import "LynxTransformOriginRaw.h"
#import "LynxTransformRaw.h"
#import "LynxTransitionAnimationManager.h"
#import "LynxUI+Accessibility.h"
#import "LynxUI+Internal.h"
#import "LynxUIContext+Internal.h"
#import "LynxUIIntersectionObserver.h"
#import "LynxUIMethodProcessor.h"
#import "LynxUIScroller.h"
#import "LynxUnitUtils.h"
#import "LynxVersion.h"
#import "LynxVersionUtils.h"
#import "LynxView+Internal.h"
#import "LynxView.h"
#import "UIView+Lynx.h"

static const short OVERFLOW_X_VAL = 0x01;
static const short OVERFLOW_Y_VAL = 0x02;
short const OVERFLOW_XY_VAL = 0x03;
short const OVERFLOW_HIDDEN_VAL = 0x00;

#define IS_ZERO(num) (fabs(num) < 0.0000000001)

@interface LynxUI ()
// transition animation
@property(nonatomic, strong, nullable) LynxTransitionAnimationManager* transitionAnimationManager;
// layout animation
@property(nonatomic, strong, nullable) LynxLayoutAnimationManager* layoutAnimationManager;
@property(nonatomic, assign) CGRect lastUpdatedFrame;
@property(nonatomic, assign) BOOL didTransformChanged;
@property(nonatomic, strong) Class accessibilityAttachedCellClass;
@property(nonatomic, strong) UIView* accessibilityAttachedCell;
@property(nonatomic, assign) BOOL accessibilityAutoScroll;
- (void)prepareKeyframeManager;
- (void)prepareLayoutAnimationManager;
- (void)prepareTransitionAnimationManager;

@end

@implementation LynxUI {
  UIView* _view;
  __weak LynxUIContext* _context;
  __weak CAShapeLayer* _overflowMask;
  BOOL _userInteractionEnabled;
  // angles to consume slide events
  NSMutableArray<NSArray<NSNumber*>*>* _angleArray;
  // block all native event of this element
  BOOL _blockNativeEvent;
  // block native event at some areas of this element
  NSArray<NSArray<LynxSizeValue*>*>* _blockNativeEventAreas;
  // Default value is false. When setting _simultaneousTouch as true and clicking to the ui or its
  // sub ui, the lynx touch gestures will not fail.
  BOOL _enableSimultaneousTouch;
  BOOL _enableTouchPseudoPropagation;
  BOOL _ignoreFocus;
  double _touchSlop;
  BOOL _onResponseChain;
  enum LynxEventPropStatus _eventThrough;
  enum LynxPropStatus _enableExposureUIMargin;
  NSDictionary<NSString*, LynxEventSpec*>* _eventSet;
  CGFloat _filter_amount;
  LynxFilterType _filter_type;
  BOOL _autoResumeAnimation;
}

- (instancetype)init {
  return [self initWithView:nil];
}

- (instancetype)initWithView:(UIView*)view {
  self = [super init];
  if (self) {
    _sign = NSNotFound;
    _view = view ? view : [self createView];
    _backgroundManager = [[LynxBackgroundManager alloc] initWithUI:self];
    _fontSize = 14;
    _userInteractionEnabled = YES;
    _angleArray = nil;
    _blockNativeEvent = NO;
    _blockNativeEventAreas = nil;
    _enableSimultaneousTouch = NO;
    _enableTouchPseudoPropagation = YES;
    _eventThrough = kLynxEventPropUndefined;
    // touch slop's default value is 8 the same as Android.
    _touchSlop = 8;
    _onResponseChain = NO;
    _transformRaw = nil;
    _transformOriginRaw = nil;
    _asyncDisplayFromTTML = YES;
    _dataset = [NSDictionary dictionary];
    _view.isAccessibilityElement = self.enableAccessibilityByDefault;
    _view.accessibilityTraits = self.accessibilityTraitsByDefault;
    _view.accessibilityLabel = nil;
    _view.lynxClickable = self.accessibilityClickable;
    _useDefaultAccessibilityLabel = YES;
    _isFirstAnimatedReady = YES;
    _filter_amount = -1;
    _filter_type = LynxFilterTypeNone;
    _updatedFrame = CGRectZero;
    _lastUpdatedFrame = CGRectZero;
    _overflow = OVERFLOW_HIDDEN_VAL;
    _lastTransformRotation = [[LynxAnimationTransformRotation alloc] init];
    _lastTransformWithoutRotate = CATransform3DIdentity;
    _lastTransformWithoutRotateXY = CATransform3DIdentity;
    _autoResumeAnimation = YES;
    _enableNewTransformOrigin = YES;
    _enableExposureUIMargin = kLynxPropUndefined;
  }
  return self;
}

- (UIView*)view {
  return _view;
}

- (UIView*)createView {
  NSAssert(false, @"You must override %@ in a subclass", NSStringFromSelector(_cmd));
  return nil;
}

- (void)updateCSSDefaultValue {
  if (_context.rootUI.lynxView.lynxConfigInfo.cssAlignWithLegacyW3c) {
    [_backgroundManager makeCssDefaultValueToFitW3c];
  }
}

- (void)setSign:(NSInteger)sign {
  _sign = sign;
  self.view.lynxSign = [NSNumber numberWithInteger:sign];
}

- (void)setContext:(LynxUIContext*)context {
  _context = context;
  // if the SDK version < 1.5, set clipOnBorderRadius = true;
  // else, set clipOnBorderRadius = false.
  if ([LynxVersionUtils compareLeft:[_context targetSdkVersion]
                          withRight:LYNX_TARGET_SDK_VERSION_1_5] < 0) {
    _clipOnBorderRadius = YES;
  } else {
    _clipOnBorderRadius = NO;
  }

  _autoResumeAnimation = _context.defaultAutoResumeAnimation;
  _enableNewTransformOrigin = _context.defaultEnableNewTransformOrigin;
}

- (LynxUIContext*)context {
  return _context;
}

- (void)dispatchMoveToWindow:(UIWindow*)window {
  if (self.view.window != window) {
    [self willMoveToWindow:window];
    for (LynxUI* child in self.children) {
      [child dispatchMoveToWindow:window];
    }
  }
}

- (CGPoint)contentOffset {
  return CGPointZero;
}

- (BOOL)isScrollContainer {
  return NO;
}

- (void)setContentOffset:(CGPoint)contentOffset {
}

/**
 * Leaf node or container that has custom layout may need padding
 */
- (void)updateFrame:(CGRect)frame
            withPadding:(UIEdgeInsets)padding
                 border:(UIEdgeInsets)border
                 margin:(UIEdgeInsets)margin
    withLayoutAnimation:(BOOL)with {
  if (!CGRectEqualToRect(self.updatedFrame, frame) ||
      !UIEdgeInsetsEqualToEdgeInsets(_padding, padding) ||
      !UIEdgeInsetsEqualToEdgeInsets(_border, border)) {
    self.updatedFrame = frame;
    // remove layout ani before next updateFrame
    // Do not remove transition transform animation here.
    [_layoutAnimationManager removeAllLayoutAnimation];
    if (with) {
      [self updateFrameWithLayoutAnimation:frame withPadding:padding border:border margin:margin];
    } else {
      [_transitionAnimationManager removeAllLayoutTransitionAnimation];
      [self updateFrameWithoutLayoutAnimation:frame
                                  withPadding:padding
                                       border:border
                                       margin:margin];
    }
  }
  [self sendLayoutChangeEvent];
}

- (void)updateFrame:(CGRect)frame
            withPadding:(UIEdgeInsets)padding
                 border:(UIEdgeInsets)border
    withLayoutAnimation:(BOOL)with {
  [self updateFrame:frame
              withPadding:padding
                   border:border
                   margin:UIEdgeInsetsZero
      withLayoutAnimation:with];
}

- (void)setEnableNested:(BOOL)value requestReset:(BOOL)requestReset {
  // override by subclasses
}

- (void)updateSticky:(NSArray*)info {
  if (info == nil || [info count] < 4) {
    _sticky = nil;
    return;
  }
  LynxUI* uiParent = (LynxUI*)self.parent;
  if ([uiParent isKindOfClass:[LynxUIScroller class]]) {
    LynxUIScroller* parent = (LynxUIScroller*)uiParent;
    parent.enableSticky = YES;
    _sticky = info;
  } else {
    return;
  }
}

- (void)checkStickyOnParentScroll:(CGFloat)offsetX withOffsetY:(CGFloat)offsetY {
  if (_sticky == nil) {
    return;
  }
  LynxUIScroller* parent = self.parent;
  CGFloat left = self.frame.origin.x;
  CGFloat top = self.frame.origin.y;
  CGPoint trans = CGPointZero;
  if (top - offsetY <= [_sticky[1] floatValue]) {
    trans.y = offsetY + [_sticky[1] floatValue] - top;
  } else {
    CGFloat scrollHeight = parent.frame.size.height;
    CGFloat bottom = scrollHeight - top - self.frame.size.height;
    if (bottom + offsetY <= [_sticky[3] floatValue]) {
      trans.y = offsetY + bottom - [_sticky[3] floatValue];
    } else {
      trans.y = 0;
    }
  }
  if (left - offsetX <= [_sticky[0] floatValue]) {
    trans.x = offsetX + [_sticky[0] floatValue] - left;
  } else {
    CGFloat scrollWidth = parent.frame.size.width;
    CGFloat right = scrollWidth - left - self.frame.size.width;
    if (right + offsetX <= [_sticky[2] floatValue]) {
      trans.x = offsetX + right - [_sticky[2] floatValue];
    } else {
      trans.x = 0;
    }
  }
  [self.backgroundManager setPostTranslate:trans];
}

- (void)updateFrameWithoutLayoutAnimation:(CGRect)frame
                              withPadding:(UIEdgeInsets)padding
                                   border:(UIEdgeInsets)border
                                   margin:(UIEdgeInsets)margin {
  _padding = padding;
  _border = border;
  _margin = margin;
  self.frame = frame;
  [self frameDidChange];
}

- (void)updateManagerRelated {
  _backgroundManager.backgroundInfo.paddingWidth = _padding;
  [_backgroundManager applyEffect];
  if (_filter_type != LynxFilterTypeNone) {
    id filter = [self getFilterWithType:LynxFilterTypeGrayScale];
    if (filter) {
      [_backgroundManager setFilters:@[ filter ]];
    }
  }
}

- (void)propsDidUpdate {
  [_context addUIToExposuredMap:self];
  // Notify property have changed.
  [_context.observer notifyProperty:nil];
  [self updateManagerRelated];
}

- (void)setAsyncDisplayFromTTML:(BOOL)async {
  _asyncDisplayFromTTML = async;
}

// Notice: onAnimatedNodeReady may be triggered multiple times in once props update.
- (void)onAnimatedNodeReady {
  if ([self shouldReDoTransform]) {
    [self applyTransform];
  }
  if (_transitionAnimationManager) {
    [_transitionAnimationManager applyTransitionAnimation];
  }
  if (nil != _animationManager) {
    [_animationManager notifyAnimationUpdated];
  }
  if (_isFirstAnimatedReady) {
    _isFirstAnimatedReady = NO;
  }
  _didTransformChanged = NO;
  _lastUpdatedFrame = _updatedFrame;
}

- (void)onNodeReady {
  if (_readyBlockArray) {
    NSArray* blockArray = [_readyBlockArray copy];
    for (dispatch_block_t ready in blockArray) {
      ready();
    }
  }
  [_readyBlockArray removeAllObjects];
  // to override if need to watch onNodeReady and remember to call super after override

  [self handleAccessibility:self.accessibilityAttachedCell autoScroll:self.accessibilityAutoScroll];
}

- (void)clearOverflowMask {
  if (_overflowMask != nil) {
    _overflowMask = self.view.layer.mask = nil;
  }
}

- (bool)updateLayerMaskOnFrameChanged {
  if (_clipPath) {
    CAShapeLayer* mask = [[CAShapeLayer alloc] init];
    UIBezierPath* path = [_clipPath pathWithFrameSize:self.frameSize];
    mask.path = path.CGPath;
    _overflowMask = self.view.layer.mask = mask;
    return true;
  }
  if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
    return false;
  }

  if (_overflow == OVERFLOW_XY_VAL) {
    self.view.clipsToBounds = NO;
    if (_overflowMask != nil) {
      _overflowMask = self.view.layer.mask = nil;
    }
    return true;
  }

  bool hasDifferentRadii = false;
  if (_overflow == 0) {
    hasDifferentRadii = [self.backgroundManager hasDifferentBorderRadius];
    if (!hasDifferentRadii) {
      self.view.clipsToBounds = YES;
      if (_overflowMask != nil) {
        _overflowMask = self.view.layer.mask = nil;
      }
      return true;
    }
  }

  if (self.view.layer.mask != nil && self.view.layer.mask != _overflowMask) {
    // mask is used, we could not set overflow
    return false;
  }

  self.view.clipsToBounds = FALSE;

  CGPathRef pathRef = nil;
  if (_overflow == 0 && hasDifferentRadii) {
    pathRef = [LynxBackgroundUtils
        createBezierPathWithRoundedRect:CGRectMake(self.contentOffset.x, self.contentOffset.y,
                                                   self.frame.size.width, self.frame.size.height)
                            borderRadii:self.backgroundManager.borderRadius];

  } else {
    const CGSize screenSize = _context.screenMetrics.screenSize;
    CGFloat x = 0, y = 0, width = self.frame.size.width, height = self.frame.size.height;
    if ((_overflow & OVERFLOW_X_VAL) != 0) {
      x -= screenSize.width;
      width += 2 * screenSize.width;
    }
    if ((_overflow & OVERFLOW_Y_VAL) != 0) {
      y -= screenSize.height;
      height += 2 * screenSize.height;
    }
    pathRef = CGPathCreateWithRect(CGRectMake(self.contentOffset.x + x, self.contentOffset.y + y,
                                              MAX(width, 0), MAX(height, 0)),
                                   nil);
  }

  CAShapeLayer* shapeLayer = [[CAShapeLayer alloc] init];
  shapeLayer.path = pathRef;
  CGPathRelease(pathRef);

  _overflowMask = self.view.layer.mask = shapeLayer;

  return true;
}

- (void)willMoveToWindow:(UIWindow*)window {
  if (_context.eventEmitter && _eventSet && _eventSet.count != 0) {
    static NSString* LynxEventAttach = @"attach";
    static NSString* LynxEventDettach = @"detach";
    if (window && [_eventSet valueForKey:LynxEventAttach]) {
      [_context.eventEmitter
          dispatchCustomEvent:[[LynxCustomEvent alloc] initWithName:LynxEventAttach
                                                         targetSign:_sign]];
    } else if (!window && [_eventSet valueForKey:LynxEventDettach]) {
      [_context.eventEmitter
          dispatchCustomEvent:[[LynxCustomEvent alloc] initWithName:LynxEventDettach
                                                         targetSign:_sign]];
    }
  }
  [_backgroundManager updateShadow];

  if (window) {
    if ([self respondsToSelector:@selector(targetOnScreen)]) {
      [self targetOnScreen];
    }
    [_animationManager resumeAnimation];
  } else {
    if ([self respondsToSelector:@selector(targetOffScreen)]) {
      [self targetOffScreen];
    }
  }
}

- (void)frameDidChange {
  if (!self.parent || ![self.parent hasCustomLayout]) {
    if (!_backgroundManager.implicitAnimation) {
      [CATransaction begin];
      [CATransaction setDisableActions:YES];
    }
    if (CATransform3DIsIdentity(self.view.layer.transform)) {
      self.view.frame = self.frame;
    } else {
      CGRect bounds = self.frame;
      bounds.origin = self.view.bounds.origin;
      self.view.bounds = bounds;
      if (!_enableNewTransformOrigin) {
        self.view.center = CGPointMake(self.frame.origin.x + self.frame.size.width / 2,
                                       self.frame.origin.y + self.frame.size.height / 2);
      } else {
        CGFloat newCenterX, newCenterY;
        newCenterX = self.frame.origin.x + self.frame.size.width * self.view.layer.anchorPoint.x;
        newCenterY = self.frame.origin.y + self.frame.size.height * self.view.layer.anchorPoint.y;
        self.view.center = CGPointMake(newCenterX, newCenterY);
      }
    }

    [self updateLayerMaskOnFrameChanged];
    [self updateManagerRelated];
    if (!_backgroundManager.implicitAnimation) {
      [CATransaction commit];
    }
  }
}

- (BOOL)childrenContainPoint:(CGPoint)point {
  BOOL contain = NO;
  if (_context.enableEventRefactor) {
    for (LynxUI* ui in self.children) {
      CGPoint newPoint = [self.view convertPoint:point toView:ui.view];
      if ([ui shouldHitTest:newPoint withEvent:nil]) {
        contain = contain || [ui containsPoint:newPoint];
      }
    }
    return contain;
  }

  CGPoint offset = self.frame.origin;
  CGPoint newPoint = CGPointMake(point.x + self.contentOffset.x - offset.x - [self getTransationX],
                                 point.y + self.contentOffset.y - offset.y - [self getTransationY]);
  for (LynxUI* ui in self.children) {
    if ([ui shouldHitTest:newPoint withEvent:nil]) {
      contain = contain || [ui containsPoint:newPoint];
    }
  }
  return contain;
}

- (CGPoint)getHitTestPoint:(CGPoint)inPoint {
  return CGPointMake(inPoint.x + self.contentOffset.x - self.getTransationX - self.frame.origin.x,
                     inPoint.y + self.contentOffset.y - self.getTransationY - self.frame.origin.y);
}

- (CGRect)getHitTestFrameWithFrame:(CGRect)frame {
  // frame should calculate translate and scale
  float scaleX = self.scaleX;
  float scaleY = self.scaleY;
  float centerX = frame.origin.x + frame.size.width / 2.0f;
  float centerY = frame.origin.y + frame.size.height / 2.0f;
  float rectX = centerX - frame.size.width * scaleX / 2.0f;
  float rectY = centerY - frame.size.height * scaleY / 2.0f;
  return CGRectMake(rectX + self.getTransationX, rectY + self.getTransationY,
                    frame.size.width * scaleX, frame.size.height * scaleY);
}

- (CGRect)getHitTestFrame {
  return [self getHitTestFrameWithFrame:self.frame];
}

- (LynxUI*)hitTest:(CGPoint)point withEvent:(UIEvent*)event onUIWithCustomLayout:(LynxUI*)ui {
  UIView* view = [ui.view hitTest:point withEvent:event];
  if (view == ui.view || !view) {
    return nil;
  }

  UIView* targetViewWithUI = view;
  while (view.superview != ui.view) {
    view = view.superview;
    if (view.lynxSign) {
      targetViewWithUI = view;
    }
  }
  for (LynxUI* child in ui.children) {
    if (child.view == targetViewWithUI) {
      return child;
    }
  }
  return nil;
}

- (void)insertChild:(LynxUI*)child atIndex:(NSInteger)index {
  // main layer and its super layer
  CALayer* mainLayer = child.view.layer;
  CALayer* superLayer = self.view.layer;
  LynxBackgroundManager* mgr = [child backgroundManager];

  // insert the child & its view into the proper position;
  [self didInsertChild:child atIndex:index];
  [self.view insertSubview:[child view] atIndex:index];

  // adjust its layer's position
  // if the current LynxUI is not at the beginning of children
  if (index > 0) {
    LynxUI* siblingUI = [self.children objectAtIndex:index - 1];

    if (!siblingUI) {
      LLogError(@"siblingUI at index%ld is nil", (long)(index - 1));
    }

    // check if the index of the left neighbor's rightmost layer(aka. the top layer) is greater than
    // the index of the 'mainLayer' if so, we need to move the 'mainLayer' to the right
    if ([superLayer.sublayers indexOfObject:[siblingUI topLayer]] >
        [superLayer.sublayers indexOfObject:mainLayer]) {
      // view operations
      [child.view removeFromSuperview];
      [self.view insertSubview:child.view aboveSubview:siblingUI.view];
      // layer operations
      [mainLayer removeFromSuperlayer];
      [superLayer insertSublayer:mainLayer above:[siblingUI topLayer]];
    }
  }

  // if the current LynxUI is not at the end of children
  if ((NSUInteger)index < [self.children count] - 1) {
    LynxUI* siblingUI = [self.children objectAtIndex:index + 1];

    if (!siblingUI) {
      LLogError(@"siblingUI at index%ld is nil", (long)(index + 1));
    }

    // check if the index of the right neighbor's leftmost layer(aka. the bottom layer) is less than
    // the index of the 'mainLayer' if so, we need to move the 'mainLayer' to the left
    if ([superLayer.sublayers indexOfObject:[siblingUI bottomLayer]] <
        [superLayer.sublayers indexOfObject:mainLayer]) {
      // view operations
      [child.view removeFromSuperview];
      [self.view insertSubview:child.view belowSubview:siblingUI.view];
      // layer operations
      [mainLayer removeFromSuperlayer];
      [superLayer insertSublayer:mainLayer below:[siblingUI bottomLayer]];
    }
  }

  // append the borderLayer & backgroundLayer
  if (mgr) {
    // if the borderLayer exists:
    if (mgr.borderLayer) {
      [mgr.borderLayer removeFromSuperlayer];
      if (OVERFLOW_HIDDEN_VAL == child.overflow) {
        [superLayer insertSublayer:mgr.borderLayer above:mainLayer];
      } else {
        // Border should below content to enable subview overflow the bounds.
        [superLayer insertSublayer:mgr.borderLayer below:mainLayer];
      }
    }

    // if the backgroundLayer exists:
    if (mgr.backgroundLayer) {
      [mgr.backgroundLayer removeFromSuperlayer];
      if (OVERFLOW_HIDDEN_VAL != child.overflow && mgr.borderLayer) {
        // backgroundLayer | borderLayer | mainLayer
        // To enable overflow.
        [superLayer insertSublayer:mgr.backgroundLayer below:mgr.borderLayer];
      } else {
        // backgroundLayer | mainLayer | <optional> borderLayer
        // overflow: hidden.
        [superLayer insertSublayer:mgr.backgroundLayer below:mainLayer];
      }
    }
  }
}

- (void)didInsertChild:(LynxUI*)child atIndex:(NSInteger)index {
  [super insertChild:child atIndex:index];
}

- (void)willRemoveComponent:(LynxUI*)child {
  [[child view] removeFromSuperview];
}

- (void)willMoveToSuperComponent:(LynxUI*)newSuperUI {
  [super willMoveToSuperComponent:newSuperUI];
  [self dispatchMoveToWindow:newSuperUI ? newSuperUI.view.window : nil];

  // the insertion (of associated layers) will be handled inside LynxUI::insertchild
  // deletion is handled here
  if (!newSuperUI) {
    [_backgroundManager removeAssociateLayers];
  }

  if (!newSuperUI) {
    [_context.intersectionManager removeAttachedIntersectionObserver:self];
  }
}

- (void)onReceiveUIOperation:(id)value {
}

- (void)layoutDidFinished {
}

- (void)finishLayoutOperation {  // before layoutDidFinished
}

- (BOOL)hasCustomLayout {
  return NO;
}

- (CGRect)frameFromParent {
  CGRect result = self.frame;
  LynxUI* parent = self.parent;
  while (parent != nil) {
    result.origin.x = result.origin.x + parent.frame.origin.x;
    result.origin.y = result.origin.y + parent.frame.origin.y;
    parent = parent.parent;
  }
  return result;
}

- (void)setRawEvents:(NSSet<NSString*>*)events andLepusRawEvents:(NSSet<NSString*>*)lepusEvents {
  _eventSet = [LynxEventSpec convertRawEvents:events andRwaLepusEvents:lepusEvents];
  [self eventDidSet];
}

- (void)eventDidSet {
}

- (float)getScrollX __attribute__((deprecated("Do not use this after lynx 2.5"))) {
  return 0;
}

- (float)getScrollY __attribute__((deprecated("Do not use this after lynx 2.5"))) {
  return 0;
}

- (void)resetContentOffset {
  // override this in scroll-view related classes
}

- (void)applyRTL:(BOOL)rtl {
  // override by subclasses
}

- (LynxUI*)getParent {
  return self.parent;
}

- (float)getTransationX {
  return [[[self getPresentationLayer] valueForKeyPath:@"transform.translation.x"] floatValue];
}

- (float)getTransationY {
  return [[[self getPresentationLayer] valueForKeyPath:@"transform.translation.y"] floatValue];
}

- (float)getTransationZ {
  return [[[self getPresentationLayer] valueForKeyPath:@"transform.translation.z"] floatValue];
}

- (float)scaleX {
  return [[[self getPresentationLayer] valueForKeyPath:@"transform.scale.x"] floatValue];
}

- (float)scaleY {
  return [[[self getPresentationLayer] valueForKeyPath:@"transform.scale.y"] floatValue];
}

- (NSMutableArray*)readyBlockArray {
  if (!_readyBlockArray) {
    _readyBlockArray = [NSMutableArray array];
  }
  return _readyBlockArray;
}

- (CALayer*)getPresentationLayer {
  if (self.view.layer.presentationLayer != nil) {
    return self.view.layer.presentationLayer;
  }
  return self.view.layer;
}

- (CGRect)getBoundingClientRect {
  UIView* rootView = ((LynxUI*)self.context.rootUI).view;
  int left = 0;
  int top = 0;
  if (rootView == NULL) {
    return CGRectMake(left, top, self.frame.size.width, self.frame.size.height);
  }
  CGRect rect = [self.view convertRect:self.view.bounds toView:rootView];
  return rect;
}

- (TransOffset)getTransformValueWithLeft:(float)left
                                   right:(float)right
                                     top:(float)top
                                  bottom:(float)bottom {
  TransOffset res;
  UIView* root_view = [[UIApplication sharedApplication] keyWindow];
  CALayer* layer = self.view.layer;
  CGFloat width = layer.bounds.size.width;
  CGFloat height = layer.bounds.size.height;
  if ([self.view isKindOfClass:[UIScrollView class]]) {
    CGPoint contentOffset = ((UIScrollView*)self.view).contentOffset;
    left += contentOffset.x;
    right += contentOffset.x;
    top += contentOffset.y;
    bottom += contentOffset.y;
  }
  res.left_top = [self.view convertPoint:CGPointMake(left, top) toView:root_view];
  res.right_top = [self.view convertPoint:CGPointMake(width + right, top) toView:root_view];
  res.right_bottom = [self.view convertPoint:CGPointMake(width + right, height + bottom)
                                      toView:root_view];
  res.left_bottom = [self.view convertPoint:CGPointMake(left, height + bottom) toView:root_view];
  return res;
}

- (CGRect)getRectToWindow {
  UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
  CGRect rect = [self.view convertRect:self.view.bounds toView:window];
  return rect;
}

LYNX_UI_METHOD(boundingClientRect) {
  CGRect rect = [self getBoundingClientRect];
  callback(
      kUIMethodSuccess, @{
        @"id" : _idSelector ?: @"",
        @"dataset" : self.dataset,
        @"left" : @(rect.origin.x),
        @"right" : @(rect.origin.x + rect.size.width),
        @"top" : @(rect.origin.y),
        @"bottom" : @(rect.origin.y + rect.size.height),
        @"width" : @(rect.size.width),
        @"height" : @(rect.size.height)
      });
}

// Document: https://bytedance.feishu.cn/docs/doccnSBwgJHXduQsCsD1n9VVa1g#
LYNX_UI_METHOD(requestUIInfo) {
  NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
  if ([[params allKeys] containsObject:@"node"]) {
    // node: implemented in timor canvas
    [dict setObject:@{} forKey:@"node"];
  }
  if ([[params allKeys] containsObject:@"id"]) {
    [dict setObject:_idSelector ?: @"" forKey:@"id"];
  }
  if ([[params allKeys] containsObject:@"dataset"]) {
    [dict setObject:_dataset ?: @{} forKey:@"dataset"];
  }
  // Same as boundingClientRect query callback
  if ([[params allKeys] containsObject:@"rect"] || [[params allKeys] containsObject:@"size"]) {
    CGRect rect = [self getBoundingClientRect];
    if ([[params allKeys] containsObject:@"rect"]) {
      [dict addEntriesFromDictionary:@{
        @"left" : @(rect.origin.x),
        @"right" : @(rect.origin.x + rect.size.width),
        @"top" : @(rect.origin.y),
        @"bottom" : @(rect.origin.y + rect.size.height),
      }];
    }

    if ([[params allKeys] containsObject:@"size"]) {
      [dict addEntriesFromDictionary:@{
        @"width" : @(rect.size.width),
        @"height" : @(rect.size.height)
      }];
    }
  }
  // The node selected is <scroll-view> to get the position of scroll vertical and scroll landscape.
  // Otherwise, the two scrolling values will always be 0,0.
  if ([[params allKeys] containsObject:@"scrollOffset"]) {
    if ([[self view] isKindOfClass:UIScrollView.class]) {
      UIScrollView* scrollView = [self view];
      [dict addEntriesFromDictionary:@{
        @"scrollTop" : @(scrollView.contentOffset.y),
        @"scrollLeft" : @(scrollView.contentOffset.x)
      }];
    } else {
      [dict addEntriesFromDictionary:@{@"scrollTop" : @(0), @"scrollLeft" : @(0)}];
    }
  }
  callback(kUIMethodSuccess, dict.copy);
}

LYNX_UI_METHOD(scrollIntoView) {
  NSString* behavior = @"auto";
  NSString* blockType = @"start";
  NSString* inlineType = @"nearest";
  NSDictionary* scrollIntoViewOptions;
  if ([[params allKeys] containsObject:@"scrollIntoViewOptions"]) {
    scrollIntoViewOptions = ((NSDictionary*)[params objectForKey:@"scrollIntoViewOptions"]);
  }
  if (scrollIntoViewOptions == nil) {
    return;
  }
  if ([[scrollIntoViewOptions allKeys] containsObject:@"behavior"]) {
    behavior = ((NSString*)[scrollIntoViewOptions objectForKey:@"behavior"]);
  }
  if ([[scrollIntoViewOptions allKeys] containsObject:@"block"]) {
    blockType = ((NSString*)[scrollIntoViewOptions objectForKey:@"block"]);
  }
  if ([[scrollIntoViewOptions allKeys] containsObject:@"inline"]) {
    inlineType = ((NSString*)[scrollIntoViewOptions objectForKey:@"inline"]);
  }

  [self scrollIntoViewWithSmooth:[behavior isEqualToString:@"smooth"]
                       blockType:blockType
                      inlineType:inlineType];
}

- (void)scrollIntoViewWithSmooth:(BOOL)isSmooth
                       blockType:(NSString*)blockType
                      inlineType:(NSString*)inlineType {
  BOOL scrollFlag = false;
  LynxUI* uiParent = (LynxUI*)self.parent;
  while (uiParent != nil) {
    if ([uiParent isKindOfClass:[AbsLynxUIScroller class]]) {
      [((AbsLynxUIScroller*)uiParent) scrollInto:self
                                        isSmooth:isSmooth
                                       blockType:blockType
                                      inlineType:inlineType];
      scrollFlag = true;
      break;
    }
    uiParent = (LynxUI*)uiParent.parent;
  }
  if (!scrollFlag) {
    LLogWarn(@"scrollIntoView not supported for nodeId:%ld", self.sign);
  }
}

LYNX_UI_METHOD(takeScreenshot) {
  if (!_view || _view.frame.size.width <= 0 || _view.frame.size.height <= 0) {
    return callback(kUIMethodNoUiForNode, @{});
  }
  bool usePng = false;
  if ([[params allKeys] containsObject:@"format"]) {
    NSString* foramt = ((NSString*)[params objectForKey:@"format"]);
    if ([foramt isEqualToString:@"png"]) {
      usePng = true;
    }
  }
  CGFloat scale = 1.f;
  if ([[params allKeys] containsObject:@"scale"]) {
    scale = ((NSNumber*)[params objectForKey:@"scale"]).floatValue;
  }

  UIGraphicsBeginImageContextWithOptions(_view.frame.size, NO, [UIScreen mainScreen].scale * scale);
  if (_backgroundManager.backgroundColor &&
      ![_backgroundManager.backgroundColor isEqual:[UIColor clearColor]]) {
    CGRect rect = CGRectMake(0, 0, _view.frame.size.width, _view.frame.size.height);
    [_backgroundManager.backgroundColor setFill];
    UIRectFill(rect);
  }
  [_view drawViewHierarchyInRect:_view.bounds afterScreenUpdates:NO];
  UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  NSData* data = usePng ? UIImagePNGRepresentation(image) : UIImageJPEGRepresentation(image, 1.0);
  NSString* header = usePng ? @"data:image/png;base64," : @"data:image/jpeg;base64,";
  NSString* str = [header stringByAppendingString:[data base64EncodedStringWithOptions:0]];

  callback(
      kUIMethodSuccess, @{
        @"width" : @(image.size.width * image.scale),
        @"height" : @(image.size.height * image.scale),
        @"data" : str
      });
}

LYNX_PROPS_GROUP_DECLARE(
    LYNX_PROP_DECLARE("accessibility-auto-scroll-if-focused", setAccessibilityAutoScrollIfFocused,
                      BOOL),
    LYNX_PROP_DECLARE("accessibility-attached-cell-class", setAccessibilityAttachedCellClass,
                      NSString*),
    LYNX_PROP_DECLARE("should-rasterize-shadow", setShouldRasterizeShadow, BOOL),
    LYNX_PROP_DECLARE("animation", setAnimation, NSArray*),
    LYNX_PROP_DECLARE("transform", setTransform, NSArray*),
    LYNX_PROP_DECLARE("transform-origin", setTransformOrigin, NSArray*),
    LYNX_PROP_DECLARE("async-display", setAsyncDisplay, BOOL),
    LYNX_PROP_DECLARE("clip-radius", enableClipOnCornerRadius, NSString*),
    LYNX_PROP_DECLARE("mask-image", setMaskImage, NSArray*),
    LYNX_PROP_DECLARE("background-image", setBackgroundImage, NSArray*),
    LYNX_PROP_DECLARE("background", setBackground, NSString*),
    LYNX_PROP_DECLARE("background-color", setBackgroundColor, UIColor*),
    LYNX_PROP_DECLARE("background-origin", setBackgroundOrigin, NSArray*),
    LYNX_PROP_DECLARE("background-position", setBackgroundPosition, NSArray*),
    LYNX_PROP_DECLARE("background-repeat", setBackgroundRepeat, NSArray*),
    LYNX_PROP_DECLARE("background-size", setBackgroundSize, NSArray*),
    LYNX_PROP_DECLARE("background-capInsets", setBackgroundCapInsets, NSString*),
    LYNX_PROP_DECLARE("clip-path", setClipPath, NSArray*),
    LYNX_PROP_DECLARE("opacity", setOpacity, CGFloat),
    LYNX_PROP_DECLARE("visibility", setVisibility, LynxVisibilityType),
    LYNX_PROP_DECLARE("direction", setLynxDirection, LynxDirectionType),
    LYNX_PROP_DECLARE("border-radius", setBorderRadius, NSArray*),
    LYNX_PROP_DECLARE("border-top-left-radius", setBorderTopLeftRadius, NSArray*),
    LYNX_PROP_DECLARE("border-bottom-left-radius", setBorderBottomLeftRadius, NSArray*),
    LYNX_PROP_DECLARE("border-top-right-radius", setBorderTopRightRadius, NSArray*),
    LYNX_PROP_DECLARE("border-bottom-right-radius", setBorderBottomRightRadius, NSArray*),
    LYNX_PROP_DECLARE("border-top-width", setBorderTopWidth, CGFloat),
    LYNX_PROP_DECLARE("border-left-width", setBorderLeftWidth, CGFloat),
    LYNX_PROP_DECLARE("border-bottom-width", setBorderBottomWidth, CGFloat),
    LYNX_PROP_DECLARE("border-right-width", setBorderRightWidth, CGFloat),
    LYNX_PROP_DECLARE("outline-width", setOutlineWidth, CGFloat),
    LYNX_PROP_DECLARE("border-top-color", setBorderTopColor, UIColor*),
    LYNX_PROP_DECLARE("border-left-color", setBorderLeftColor, UIColor*),
    LYNX_PROP_DECLARE("border-bottom-color", setBorderBottomColor, UIColor*),
    LYNX_PROP_DECLARE("border-right-color", setBorderRightColor, UIColor*),
    LYNX_PROP_DECLARE("outline-color", setOutlineColor, UIColor*),
    LYNX_PROP_DECLARE("border-left-style", setBorderLeftStyle, LynxBorderStyle),
    LYNX_PROP_DECLARE("border-right-style", setBorderRightStyle, LynxBorderStyle),
    LYNX_PROP_DECLARE("border-top-style", setBorderTopStyle, LynxBorderStyle),
    LYNX_PROP_DECLARE("border-bottom-style", setBorderBottomStyle, LynxBorderStyle),
    LYNX_PROP_DECLARE("outline-style", setOutlineStyle, LynxBorderStyle),
    LYNX_PROP_DECLARE("name", setName, NSString*),
    LYNX_PROP_DECLARE("idSelector", setIdSelector, NSString*),
    LYNX_PROP_DECLARE("accessibility-label", setAccessibilityLabel, NSString*),
    LYNX_PROP_DECLARE("accessibility-traits", setAccessibilityTraits, NSString*),
    LYNX_PROP_DECLARE("accessibility-element", setAccessibilityElement, BOOL),
    LYNX_PROP_DECLARE("box-shadow", setBoxShadow, NSArray*),
    LYNX_PROP_DECLARE("implicit-animation", setImplicitAnimationFiber, BOOL),
    LYNX_PROP_DECLARE("layout-animation-create-duration", setLayoutAnimationCreateDuration,
                      NSTimeInterval),
    LYNX_PROP_DECLARE("layout-animation-create-delay", setLayoutAnimationCreateDelay,
                      NSTimeInterval),
    LYNX_PROP_DECLARE("layout-animation-create-property", setLayoutAnimationCreateProperty,
                      LynxAnimationProp),
    LYNX_PROP_DECLARE("layout-animation-create-timing-function",
                      setLayoutAnimationCreateTimingFunction, CAMediaTimingFunction*),
    LYNX_PROP_DECLARE("layout-animation-update-duration", setLayoutAnimationUpdateDuration,
                      NSTimeInterval),
    LYNX_PROP_DECLARE("layout-animation-update-delay", setLayoutAnimationUpdateDelay,
                      NSTimeInterval),
    LYNX_PROP_DECLARE("layout-animation-update-property", setLayoutAnimationUpdateProperty,
                      LynxAnimationProp),
    LYNX_PROP_DECLARE("layout-animation-update-timing-function",
                      setLayoutAnimationUpdateTimingFunction, CAMediaTimingFunction*),
    LYNX_PROP_DECLARE("layout-animation-delete-duration", setLayoutAnimationDeleteDuration,
                      NSTimeInterval),
    LYNX_PROP_DECLARE("layout-animation-delete-delay", setLayoutAnimationDeleteDelay,
                      NSTimeInterval),
    LYNX_PROP_DECLARE("layout-animation-delete-property", setLayoutAnimationDeleteProperty,
                      LynxAnimationProp),
    LYNX_PROP_DECLARE("layout-animation-delete-timing-function",
                      setLayoutAnimationDeleteTimingFunction, CAMediaTimingFunction*),
    LYNX_PROP_DECLARE("font-size", setFontSize, CGFloat),
    LYNX_PROP_DECLARE("transition", setTransitions, NSArray*),
    LYNX_PROP_DECLARE("lynx-test-tag", setTestTag, NSString*),
    LYNX_PROP_DECLARE("user-interaction-enabled", setUserInteractionEnabled, BOOL),
    LYNX_PROP_DECLARE("native-interaction-enabled", setNativeInteractionEnabled, BOOL),
    LYNX_PROP_DECLARE("allow-edge-antialiasing", setAllowEdgeAntialiasing, BOOL),
    LYNX_PROP_DECLARE("overflow-x", setOverflowX, LynxOverflowType),
    LYNX_PROP_DECLARE("overflow-y", setOverflowY, LynxOverflowType),
    LYNX_PROP_DECLARE("overflow", setOverflow, LynxOverflowType),
    LYNX_PROP_DECLARE("background-clip", setBackgroundClip, NSArray*),
    LYNX_PROP_DECLARE("caret-color", setCaretColor, NSString*),
    LYNX_PROP_DECLARE("consume-slide-event", setConsumeSlideEvent, NSArray*),
    LYNX_PROP_DECLARE("block-native-event", setBlockNativeEvent, BOOL),
    LYNX_PROP_DECLARE("block-native-event-areas", setBlockNativeEventAreas, NSArray*),
    LYNX_PROP_DECLARE("ios-enable-simultaneous-touch", setEnableSimultaneousTouch, BOOL),
    LYNX_PROP_DECLARE("enable-touch-pseudo-propagation", setEnableTouchPseudoPropagation, BOOL),
    LYNX_PROP_DECLARE("event-through", setEventThrough, BOOL),
    LYNX_PROP_DECLARE("ignore-focus", setIgnoreFocus, BOOL),
    LYNX_PROP_DECLARE("react-ref", setRefId, NSString*),
    LYNX_PROP_DECLARE("dataset", setDataset, NSDictionary*),
    LYNX_PROP_DECLARE("intersection-observers", setIntersectionObservers, NSArray*),
    LYNX_PROP_DECLARE("perspective", setPerspective, NSArray*),
    LYNX_PROP_DECLARE("auto-resume-animation", setAutoResumeAnimation, BOOL),
    LYNX_PROP_DECLARE("enable-new-transform-origin", setEnableNewTransformOrigin, BOOL),
    LYNX_PROP_DECLARE("overlap-ios", setOverlapRendering, BOOL),
    LYNX_PROP_DECLARE("background-shape-layer", setUseBackgroundShapeLayer, BOOL),
    LYNX_PROP_DECLARE("enable-nested-scroll", setEnableNested, BOOL))

#pragma mark - keyframe animation

LYNX_PROP_DEFINE("animation", setAnimation, NSArray*) {
  [self prepareKeyframeManager];
  if (requestReset || [value isEqual:[NSNull null]] || value == nil) {
    [_animationManager endAllAnimation];
    return;
  }
  NSMutableArray<LynxAnimationInfo*>* infos = [[NSMutableArray alloc] init];
  for (id v in value) {
    if ([v isKindOfClass:[NSArray class]]) {
      LynxAnimationInfo* info = [LynxConverter toKeyframeAnimationInfo:v];
      if (info != nil) {
        [infos addObject:info];
      }
    }
  }
  [_animationManager setAnimations:infos];
}

#pragma mark - Transform

LYNX_PROP_DEFINE("transform", setTransform, NSArray*) {
  if (requestReset) {
    value = nil;
  }
  _didTransformChanged = YES;
  _transformRaw = [LynxTransformRaw toTransformRaw:value];

  if (nil != _animationManager) {
    [_animationManager notifyPropertyUpdated:[LynxKeyframeAnimator kTransformStr]
                                       value:_transformRaw];
  }
}

LYNX_PROP_DEFINE("transform-origin", setTransformOrigin, NSArray*) {
  if (requestReset) {
    value = nil;
  }
  _didTransformChanged = YES;
  _transformOriginRaw = [LynxTransformOriginRaw convertToLynxTransformOriginRaw:value];
}

LYNX_PROP_DEFINE("perspective", setPerspective, NSArray*) {
  if (requestReset) {
    _perspective = nil;
    return;
  }
  _perspective = value;
}

LYNX_PROP_DEFINE("async-display", setAsyncDisplay, BOOL) {
  if (requestReset) {
    _asyncDisplayFromTTML = YES;
    return;
  }
  _asyncDisplayFromTTML = value;
}

- (void)applyTransformOrigin {
  CGFloat anchorX = 0, anchorY = 0;
  CGFloat oldAnchorX = self.view.layer.anchorPoint.x;
  CGFloat oldAnchorY = self.view.layer.anchorPoint.y;
  if (self.transformOriginRaw == nil) {
    anchorX = 0.5;
    anchorY = 0.5;
  } else {
    if ([self.transformOriginRaw isP0Percent]) {
      anchorX = self.transformOriginRaw.p0;
    } else {
      if (self.updatedFrame.size.width == 0) {
        anchorX = 0.5;
      } else {
        anchorX = self.transformOriginRaw.p0 / self.updatedFrame.size.width;
      }
    }
    if ([self.transformOriginRaw isP1Percent]) {
      anchorY = self.transformOriginRaw.p1;
    } else {
      if (self.updatedFrame.size.height == 0) {
        anchorY = 0.5;
      } else {
        anchorY = self.transformOriginRaw.p1 / self.updatedFrame.size.height;
      }
    }
  }

  CGFloat newCenterX = self.view.center.x + (anchorX - oldAnchorX) * self.updatedFrame.size.width;
  CGFloat newCenterY = self.view.center.y + (anchorY - oldAnchorY) * self.updatedFrame.size.height;
  self.view.center = CGPointMake(newCenterX, newCenterY);
  self.view.layer.anchorPoint = CGPointMake(anchorX, anchorY);
  self.backgroundManager.transformOrigin = CGPointMake(anchorX, anchorY);
}

- (void)applyTransform {
  [_transitionAnimationManager removeTransitionAnimation:TRANSITION_TRANSFORM];
  if (_enableNewTransformOrigin) {
    [self applyTransformOrigin];
  }
  char rotationType = LynxTransformRotationNone;
  CGFloat currentRotationX = 0;
  CGFloat currentRotationY = 0;
  CGFloat currentRotationZ = 0;
  CATransform3D transformWithoutRotate = CATransform3DIdentity;
  CATransform3D transformWithoutRotateXY = CATransform3DIdentity;
  CATransform3D transform3D = [LynxConverter toCATransform3D:_transformRaw
                                                          ui:self
                                                    newFrame:_updatedFrame
                                      transformWithoutRotate:&transformWithoutRotate
                                    transformWithoutRotateXY:&transformWithoutRotateXY
                                                rotationType:&rotationType
                                                   rotationX:&currentRotationX
                                                   rotationY:&currentRotationY
                                                   rotationZ:&currentRotationZ];

  LynxAnimationTransformRotation* oldTransformRotation = _lastTransformRotation;
  LynxAnimationTransformRotation* newTransformRotation =
      [[LynxAnimationTransformRotation alloc] init];
  newTransformRotation.rotationX = currentRotationX;
  newTransformRotation.rotationY = currentRotationY;
  newTransformRotation.rotationZ = currentRotationZ;

  if (_didTransformChanged && !_isFirstAnimatedReady && _transitionAnimationManager &&
      ([_transitionAnimationManager isTransitionTransform:_view.layer.transform
                                             newTransform:transform3D] ||
       [_transitionAnimationManager isTransitionTransformRotation:oldTransformRotation
                                             newTransformRotation:newTransformRotation])) {
    __weak LynxUI* weakSelf = self;
    [_transitionAnimationManager
        performTransitionAnimationsWithTransform:transform3D
                          transformWithoutRotate:transformWithoutRotate
                        transformWithoutRotateXY:transformWithoutRotateXY
                                        rotation:newTransformRotation
                                        callback:^(BOOL finished) {
                                          weakSelf.view.layer.transform = transform3D;
                                          weakSelf.backgroundManager.transform = transform3D;
                                          weakSelf.lastTransformRotation = newTransformRotation;
                                          weakSelf.lastTransformWithoutRotate =
                                              transformWithoutRotate;
                                          weakSelf.lastTransformWithoutRotateXY =
                                              transformWithoutRotateXY;
                                          [weakSelf.view setNeedsDisplay];
                                        }];
  } else {
    if (!CATransform3DEqualToTransform(_view.layer.transform, transform3D)) {
      // Transform will be apply on background manager
      _view.layer.transform = transform3D;
      _backgroundManager.transform = transform3D;
      self.lastTransformRotation = newTransformRotation;
      self.lastTransformWithoutRotate = transformWithoutRotate;
      self.lastTransformWithoutRotateXY = transformWithoutRotateXY;
      [self.view setNeedsDisplay];
      // Static transform animation changes the UI‘s layout.
      [self.context.observer notifyLayout:nil];
    }
  }
}

// This informs whether clipping will take place if a subview overflows a superview's border-radius
// part.
LYNX_PROP_DEFINE("clip-radius", enableClipOnCornerRadius, NSString*) {
  if (requestReset) {
    if ([LynxVersionUtils compareLeft:[_context targetSdkVersion]
                            withRight:LYNX_TARGET_SDK_VERSION_1_5] < 0) {
      _clipOnBorderRadius = YES;
    } else {
      _clipOnBorderRadius = NO;
    }
  }

  if ((value && [value caseInsensitiveCompare:@"no"] == NSOrderedSame) ||
      (value && [value caseInsensitiveCompare:@"false"] == NSOrderedSame)) {
    _clipOnBorderRadius = NO;
  } else if ((value && [value caseInsensitiveCompare:@"yes"] == NSOrderedSame) ||
             (value && [value caseInsensitiveCompare:@"true"] == NSOrderedSame)) {
    _clipOnBorderRadius = YES;
  }

  [self.view setNeedsDisplay];
}

LYNX_PROP_DEFINE("mask-image", setMaskImage, NSArray*) {
  if (requestReset) {
    value = [NSArray new];
  }

  [_backgroundManager.maskImageUrlOrGradient removeAllObjects];

  for (NSUInteger i = 0; i < [value count]; i++) {
    NSUInteger type = [LynxConverter toNSUInteger:[value objectAtIndex:i]];
    if (type == LynxBackgroundImageURL) {
      i++;
      [_backgroundManager addMaskImage:[[LynxBackgroundImageDrawable alloc]
                                           initWithString:[LynxConverter toNSString:value[i]]]];
    } else if (type == LynxBackgroundImageLinearGradient) {
      i++;
      [_backgroundManager
          addMaskImage:[[LynxBackgroundLinearGradientDrawable alloc] initWithArray:value[i]]];
    } else if (type == LynxBackgroundImageRadialGradient) {
      i++;
      [_backgroundManager
          addMaskImage:[[LynxBackgroundRadialGradientDrawable alloc] initWithArray:value[i]]];
    } else if (type == LynxBackgroundImageNone) {
      i++;
      [_backgroundManager addMaskImage:[LynxBackgroundNoneDrawable new]];
    }
  }
  [self.view setNeedsDisplay];
}

LYNX_PROP_DEFINE("background-image", setBackgroundImage, NSArray*) {
  if (requestReset) {
    value = [NSArray new];
  }

  [_backgroundManager clearAllBackgroundDrawable];

  for (NSUInteger i = 0; i < [value count]; i++) {
    NSUInteger type = [LynxConverter toNSUInteger:[value objectAtIndex:i]];
    if (type == LynxBackgroundImageURL) {
      i++;
      [_backgroundManager
          addBackgroundImage:[[LynxBackgroundImageDrawable alloc]
                                 initWithString:[LynxConverter toNSString:value[i]]]];
    } else if (type == LynxBackgroundImageLinearGradient) {
      i++;
      [_backgroundManager
          addBackgroundImage:[[LynxBackgroundLinearGradientDrawable alloc] initWithArray:value[i]]];
    } else if (type == LynxBackgroundImageRadialGradient) {
      i++;
      [_backgroundManager
          addBackgroundImage:[[LynxBackgroundRadialGradientDrawable alloc] initWithArray:value[i]]];
    } else if (type == LynxBackgroundImageNone) {
      continue;
    }
  }
  [self.view setNeedsDisplay];
}

LYNX_PROP_DEFINE("background", setBackground, NSString*) {
  LLogWarn(@"setBackground is deprecated, call this method has no effect");
}

LYNX_PROP_DEFINE("background-color", setBackgroundColor, UIColor*) {
  if (requestReset) {
    value = nil;
  }

  if (nil != _animationManager) {
    [_animationManager notifyPropertyUpdated:[LynxKeyframeAnimator kBackgroundColorStr]
                                       value:(id)value.CGColor];
  }

  if (_transitionAnimationManager &&
      [_transitionAnimationManager maybeUpdateBackgroundWithTransitionAnimation:value]) {
    return;
  }

  _backgroundManager.backgroundColor = value;
  [self.view setNeedsDisplay];
}

LYNX_PROP_DEFINE("background-origin", setBackgroundOrigin, NSArray*) {
  [_backgroundManager clearAllBackgroundOrigin];
  if (requestReset) {
    value = [NSArray new];
  }
  for (NSNumber* origin in value) {
    NSUInteger backgroundOrigin = [origin unsignedIntegerValue];
    if (backgroundOrigin > LynxBackgroundOriginContentBox) {
      backgroundOrigin = LynxBackgroundOriginBorderBox;
    }
    [_backgroundManager addBackgroundOrigin:backgroundOrigin];
  }
  [self.view setNeedsDisplay];
}

LYNX_PROP_DEFINE("background-position", setBackgroundPosition, NSArray*) {
  [_backgroundManager clearAllBackgroundPosition];
  if (requestReset || value.count % 2 != 0) {
    value = [NSArray new];
  }

  for (NSUInteger i = 0; i < [value count]; i += 2) {
    NSUInteger type = [LynxConverter toNSUInteger:[value objectAtIndex:i + 1]];
    LynxBackgroundPosition* backgroundPosition = NULL;
    if (type == LynxPlatformLengthUnitCalc) {
      NSArray* position = [value objectAtIndex:i];
      NSNumber* numberValue = [position objectAtIndex:0];
      NSNumber* percentValue = [position objectAtIndex:1];
      backgroundPosition = [[LynxBackgroundPosition alloc] initWithValue:[numberValue floatValue]
                                                              andPercent:[percentValue floatValue]
                                                                    type:type];
    } else {
      NSNumber* position = [value objectAtIndex:i];
      backgroundPosition = [[LynxBackgroundPosition alloc] initWithValue:[position floatValue]
                                                                    type:type];
    }
    [_backgroundManager addBackgroundPosition:backgroundPosition];
  }
  [self.view setNeedsDisplay];
}

LYNX_PROP_DEFINE("background-repeat", setBackgroundRepeat, NSArray*) {
  [_backgroundManager.backgroundRepeat removeAllObjects];
  if (requestReset) {
    value = [NSArray array];
  }
  for (NSNumber* number in value) {
    [_backgroundManager addBackgroundRepeat:[number integerValue]];
  }
  [self.view setNeedsDisplay];
}

LYNX_PROP_DEFINE("background-size", setBackgroundSize, NSArray*) {
  [_backgroundManager.backgroundImageSize removeAllObjects];
  if (requestReset || value.count % 2 != 0) {
    value = [NSArray new];
  }

  for (NSUInteger i = 0; i < [value count]; i += 2) {
    NSNumber* size = [value objectAtIndex:i];
    NSUInteger type = [LynxConverter toNSUInteger:[value objectAtIndex:i + 1]];
    [_backgroundManager
        addBackgroundSize:[[LynxBackgroundSize alloc] initWithValue:[size floatValue] type:type]];
  }
  [self.view setNeedsDisplay];
}

LYNX_PROP_DEFINE("background-capInsets", setBackgroundCapInsets, NSString*) {
  if (requestReset) {
    value = @"";
  }
  value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([value isEqualToString:@""]) {
    [_backgroundManager.backgroundCapInsets reset];
  } else {
    LynxBackgroundCapInsets* backgroundCapInsets =
        [[LynxBackgroundCapInsets alloc] initWithParams:value];
    backgroundCapInsets.ui = self;
    _backgroundManager.backgroundCapInsets = backgroundCapInsets;
  }
  [self.view setNeedsDisplay];
}

LYNX_PROP_DEFINE("opacity", setOpacity, CGFloat) {
  if (requestReset) {
    value = 1;
  }
  if (nil != _animationManager) {
    [_animationManager notifyPropertyUpdated:[LynxKeyframeAnimator kOpacityStr]
                                       value:[NSNumber numberWithFloat:value]];
  }

  if (_transitionAnimationManager &&
      [_transitionAnimationManager maybeUpdateOpacityWithTransitionAnimation:value]) {
    return;
  }
  [self view].layer.opacity = value;
  _backgroundManager.opacity = value;
  [self.view setNeedsDisplay];
}

LYNX_PROP_DEFINE("visibility", setVisibility, LynxVisibilityType) {
  if (requestReset) {
    value = (int)LynxVisibilityVisible;
  }
  LynxVisibilityType type = (LynxVisibilityType)value;
  BOOL isVisible = (type == LynxVisibilityVisible);
  BOOL isHidden = (type == LynxVisibilityHidden);

  if (_transitionAnimationManager) {
    [_transitionAnimationManager removeTransitionAnimation:TRANSITION_VISIBILITY];
  }

  if (_transitionAnimationManager &&
      ([_transitionAnimationManager isTransitionVisibility:self.view.hidden newState:isHidden])) {
    __weak LynxUI* weakSelf = self;
    [_transitionAnimationManager
        performTransitionAnimationsWithVisibility:isHidden
                                         callback:^(BOOL finished) {
                                           __strong LynxUI* strongSelf = weakSelf;
                                           if (strongSelf) {
                                             if ([strongSelf view].hidden == false && isHidden) {
                                               [strongSelf view].hidden = true;
                                               [strongSelf backgroundManager].hidden = true;
                                             } else if ([strongSelf view].hidden == true &&
                                                        (isVisible || requestReset)) {
                                               [strongSelf view].hidden = false;
                                               [strongSelf backgroundManager].hidden = false;
                                             }
                                           }
                                         }];

  } else {
    if ([self view].hidden == false && isHidden) {
      [self view].hidden = true;
      [self backgroundManager].hidden = true;
    } else if ([self view].hidden == true && (isVisible || requestReset)) {
      [self view].hidden = false;
      [self backgroundManager].hidden = false;
    }
  }
}

LYNX_PROP_DEFINE("direction", setLynxDirection, LynxDirectionType) {
  if (requestReset) {
    _directionType = LynxDirectionLtr;
  } else {
    _directionType = value;
    // this block should be called in onNodeReady
    __weak typeof(self) weakSelf = self;
    [self.readyBlockArray addObject:^(void) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf) {
        [strongSelf resetContentOffset];
        [strongSelf applyRTL:value == LynxDirectionRtl];
      }
    }];
  }
}

- (LynxBorderUnitValue)toBorderUnitValue:(NSArray*)unitValue index:(int)index {
  LynxBorderUnitValue ret = {
      .val = [LynxConverter toCGFloat:[unitValue objectAtIndex:index]],
      .unit = (LynxPlatformLengthUnit)
                          [LynxConverter toNSUInteger:[unitValue objectAtIndex:index + 1]] ==
                      LynxPlatformLengthUnitNumber
                  ? LynxBorderValueUnitDefault
                  : LynxBorderValueUnitPercent};
  return ret;
}

#define SET_BORDER_UNIT_VAL(dst, src)                 \
  {                                                   \
    LynxBorderUnitValue tmp = src;                    \
    if (dst.val != tmp.val || dst.unit != tmp.unit) { \
      dst = tmp;                                      \
      changed = true;                                 \
    }                                                 \
  }

#define LYNX_PROP_SET_BORDER_RADIUS(cornerX, cornerY)                                  \
  {                                                                                    \
    if (requestReset) {                                                                \
      value = @[ @0, @0, @0, @0 ];                                                     \
    }                                                                                  \
    LynxBorderRadii borderRadius = _backgroundManager.borderRadius;                    \
    bool changed = false;                                                              \
    SET_BORDER_UNIT_VAL(borderRadius.cornerX, [self toBorderUnitValue:value index:0]); \
    SET_BORDER_UNIT_VAL(borderRadius.cornerY, [self toBorderUnitValue:value index:2]); \
    if (changed) {                                                                     \
      [_backgroundManager setBorderRadius:borderRadius];                               \
      [self.view setNeedsDisplay];                                                     \
    }                                                                                  \
  }

//@see computed_css_style.cc#borderRadiusToLepus.
LYNX_PROP_DEFINE("border-radius", setBorderRadius, NSArray*) {
  if (requestReset) {
    value = @[ @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0 ];
  }
  LynxBorderRadii borderRadius = _backgroundManager.borderRadius;
  bool changed = false;
  SET_BORDER_UNIT_VAL(borderRadius.topLeftX, [self toBorderUnitValue:value index:0]);
  SET_BORDER_UNIT_VAL(borderRadius.topLeftY, [self toBorderUnitValue:value index:2]);

  SET_BORDER_UNIT_VAL(borderRadius.topRightX, [self toBorderUnitValue:value index:4]);
  SET_BORDER_UNIT_VAL(borderRadius.topRightY, [self toBorderUnitValue:value index:6]);

  SET_BORDER_UNIT_VAL(borderRadius.bottomRightX, [self toBorderUnitValue:value index:8]);
  SET_BORDER_UNIT_VAL(borderRadius.bottomRightY, [self toBorderUnitValue:value index:10]);

  SET_BORDER_UNIT_VAL(borderRadius.bottomLeftX, [self toBorderUnitValue:value index:12]);
  SET_BORDER_UNIT_VAL(borderRadius.bottomLeftY, [self toBorderUnitValue:value index:14]);

  if (changed) {
    _backgroundManager.borderRadius = borderRadius;
    [self.view setNeedsDisplay];
  }
}

LYNX_PROP_DEFINE("border-top-left-radius", setBorderTopLeftRadius, NSArray*) {
  LYNX_PROP_SET_BORDER_RADIUS(topLeftX, topLeftY);
}

LYNX_PROP_DEFINE("border-bottom-left-radius", setBorderBottomLeftRadius, NSArray*) {
  LYNX_PROP_SET_BORDER_RADIUS(bottomLeftX, bottomLeftY);
}

LYNX_PROP_DEFINE("border-top-right-radius", setBorderTopRightRadius, NSArray*) {
  LYNX_PROP_SET_BORDER_RADIUS(topRightX, topRightY);
}

LYNX_PROP_DEFINE("border-bottom-right-radius", setBorderBottomRightRadius, NSArray*) {
  LYNX_PROP_SET_BORDER_RADIUS(bottomRightX, bottomRightY);
}

- (CGFloat)toBorderWidthValue:(NSString*)unitValue {
  if ([unitValue isEqualToString:@"thin"]) {
    return 1;
  } else if ([unitValue isEqualToString:@"medium"]) {
    return 3;
  } else if ([unitValue isEqualToString:@"thick"]) {
    return 5;
  }

  const CGSize rootSize = self.context.rootView.frame.size;
  LynxScreenMetrics* screenMetrics = self.context.screenMetrics;
  return [LynxUnitUtils toPtWithScreenMetrics:screenMetrics
                                    unitValue:unitValue
                                 rootFontSize:((LynxUI*)self.context.rootUI).fontSize
                                  curFontSize:self.fontSize
                                    rootWidth:rootSize.width
                                   rootHeight:rootSize.height
                                withDefaultPt:0];
}

#define LYNX_PROP_SET_BORDER_WIDTH(side)                     \
  UIEdgeInsets borderWidth = _backgroundManager.borderWidth; \
  if (value != borderWidth.side) {                           \
    borderWidth.side = value;                                \
    _backgroundManager.borderWidth = borderWidth;            \
    [self.view setNeedsDisplay];                             \
  }

LYNX_PROP_DEFINE("border-top-width", setBorderTopWidth, CGFloat){LYNX_PROP_SET_BORDER_WIDTH(top)}

LYNX_PROP_DEFINE("border-left-width", setBorderLeftWidth, CGFloat){LYNX_PROP_SET_BORDER_WIDTH(left)}

LYNX_PROP_DEFINE("border-bottom-width", setBorderBottomWidth,
                 CGFloat){LYNX_PROP_SET_BORDER_WIDTH(bottom)}

LYNX_PROP_DEFINE("border-right-width", setBorderRightWidth,
                 CGFloat){LYNX_PROP_SET_BORDER_WIDTH(right)}
#define LYNX_PROP_TOUICOLOR(colorStr) \
  [LynxConverter toUIColor:[NSNumber numberWithInt:[colorStr intValue]]]

LYNX_PROP_DEFINE("border-top-color", setBorderTopColor, UIColor*) {
  if (requestReset) {
    value = nil;
  }
  [_backgroundManager updateBorderColor:LynxBorderTop value:value];
}

LYNX_PROP_DEFINE("border-left-color", setBorderLeftColor, UIColor*) {
  if (requestReset) {
    value = nil;
  }
  [_backgroundManager updateBorderColor:LynxBorderLeft value:value];
}

LYNX_PROP_DEFINE("border-bottom-color", setBorderBottomColor, UIColor*) {
  if (requestReset) {
    value = nil;
  }
  [_backgroundManager updateBorderColor:LynxBorderBottom value:value];
}

LYNX_PROP_DEFINE("border-right-color", setBorderRightColor, UIColor*) {
  if (requestReset) {
    value = nil;
  }
  [_backgroundManager updateBorderColor:LynxBorderRight value:value];
}

LYNX_PROP_DEFINE("border-left-style", setBorderLeftStyle, LynxBorderStyle) {
  if (requestReset) {
    value = LynxBorderStyleSolid;
  }
  if ([_backgroundManager updateBorderStyle:LynxBorderLeft value:value]) {
    [self.view setNeedsDisplay];
  }
}

LYNX_PROP_DEFINE("border-right-style", setBorderRightStyle, LynxBorderStyle) {
  if (requestReset) {
    value = LynxBorderStyleSolid;
  }
  if ([_backgroundManager updateBorderStyle:LynxBorderRight value:value]) {
    [self.view setNeedsDisplay];
  }
}

LYNX_PROP_DEFINE("border-top-style", setBorderTopStyle, LynxBorderStyle) {
  if (requestReset) {
    value = LynxBorderStyleSolid;
  }
  if ([_backgroundManager updateBorderStyle:LynxBorderTop value:value]) {
    [self.view setNeedsDisplay];
  }
}

LYNX_PROP_DEFINE("border-bottom-style", setBorderBottomStyle, LynxBorderStyle) {
  if (requestReset) {
    value = LynxBorderStyleSolid;
  }
  if ([_backgroundManager updateBorderStyle:LynxBorderBottom value:value]) {
    [self.view setNeedsDisplay];
  }
}

LYNX_PROP_DEFINE("outline-width", setOutlineWidth, CGFloat) {
  const CGFloat val = (requestReset ? 0 : value);
  if ([_backgroundManager updateOutlineWidth:val]) {
    [self.view setNeedsDisplay];
  }
}

LYNX_PROP_DEFINE("outline-color", setOutlineColor, UIColor*) {
  if (requestReset) {
    value = nil;
  }
  if ([_backgroundManager updateOutlineColor:value]) {
    [self.view setNeedsDisplay];
  }
}

LYNX_PROP_DEFINE("outline-style", setOutlineStyle, LynxBorderStyle) {
  if (requestReset) {
    value = LynxBorderStyleNone;
  }

  if ([_backgroundManager updateOutlineStyle:value]) {
    [self.view setNeedsDisplay];
  }
}

LYNX_PROP_DEFINE("name", setName, NSString*) {
  if (requestReset) {
    value = @"";
  }
  [self setName:value];
}

- (void)setName:(NSString* _Nonnull)name {
  _name = name;
}

// this prop only be used in native and should not be used in ttml
LYNX_PROP_DEFINE("idSelector", setIdSelector, NSString*) {
  if (requestReset) {
    value = @"";
  }
  _idSelector = value;
}

LYNX_PROP_DEFINE("accessibility-label", setAccessibilityLabel, NSString*) {
  if (requestReset) {
    value = @"";
    self.useDefaultAccessibilityLabel = YES;
  }

  if (![value isEqualToString:@""]) {
    self.useDefaultAccessibilityLabel = NO;
  }
  self.view.accessibilityLabel = value;
}

LYNX_PROP_DEFINE("accessibility-traits", setAccessibilityTraits, NSString*) {
  if (requestReset) {
    self.view.accessibilityTraits = self.accessibilityTraitsByDefault;
  } else {
    self.view.accessibilityTraits = [LynxConverter toAccessibilityTraits:value];
  }
}

LYNX_PROP_DEFINE("accessibility-element", setAccessibilityElement, BOOL) {
  if (requestReset) {
    value = self.enableAccessibilityByDefault;
  }
  self.view.isAccessibilityElement = value;
}

LYNX_PROP_SETTER("accessibility-elements", setAccessibilityElements, NSString*) {
  self.accessibilityElementsIds = [value componentsSeparatedByString:@","];
}

LYNX_PROP_SETTER("accessibility-elements-a11y", setAccessibilityElementsA11y, NSString*) {
  self.accessibilityElementsA11yIds = [value componentsSeparatedByString:@","];
}
#pragma mark - Box Shadow

LYNX_PROP_DEFINE("box-shadow", setBoxShadow, NSArray*) {
  if (requestReset) {
    value = nil;
  }

  [self.backgroundManager setShadowArray:[LynxConverter toLynxBoxShadow:value]];
}

LYNX_PROP_DEFINE("implicit-animation", setImplicitAnimationFiber, BOOL) {
  if (requestReset) {
    value = _context.defaultImplicitAnimation;
  }
  _backgroundManager.implicitAnimation = value;
}

LYNX_PROP_DEFINE("auto-resume-animation", setAutoResumeAnimation, BOOL) {
  if (requestReset) {
    value = _context.defaultAutoResumeAnimation;
  }
  _autoResumeAnimation = value;
  _animationManager.autoResumeAnimation = value;
}

LYNX_PROP_DEFINE("enable-new-transform-origin", setEnableNewTransformOrigin, BOOL) {
  if (requestReset) {
    value = _context.defaultEnableNewTransformOrigin;
  }
  _enableNewTransformOrigin = value;
}

#pragma mark - Layout animation

// layout for layout-animation
- (void)updateFrameWithLayoutAnimation:(CGRect)newFrame
                           withPadding:(UIEdgeInsets)padding
                                border:(UIEdgeInsets)border
                                margin:(UIEdgeInsets)margin {
  if (!_layoutAnimationManager && !_transitionAnimationManager) {
    [self updateFrameWithoutLayoutAnimation:newFrame
                                withPadding:padding
                                     border:border
                                     margin:margin];
    return;
  }

  if (_layoutAnimationManager &&
      [_layoutAnimationManager maybeUpdateFrameWithLayoutAnimation:newFrame
                                                       withPadding:padding
                                                            border:border
                                                            margin:margin]) {
    LLogInfo(@"LynxUI do layoutAnimation");
  } else if (_transitionAnimationManager &&
             [_transitionAnimationManager maybeUpdateFrameWithTransitionAnimation:newFrame
                                                                      withPadding:padding
                                                                           border:border
                                                                           margin:margin]) {
    LLogInfo(@"LynxUI do transitionAnimation");
  } else {
    LLogInfo(@"LynxUI don't do any layout related animation.");
    [self updateFrameWithoutLayoutAnimation:newFrame
                                withPadding:padding
                                     border:border
                                     margin:margin];
  }
}

// init

- (void)prepareKeyframeManager {
  _backgroundManager.implicitAnimation = false;
  if (nil == _animationManager) {
    _animationManager = [[LynxKeyframeManager alloc] initWithUI:self];
    _animationManager.autoResumeAnimation = _autoResumeAnimation;
  }
}

- (void)prepareLayoutAnimationManager {
  _backgroundManager.implicitAnimation = false;
  if (!_layoutAnimationManager) {
    _layoutAnimationManager = [[LynxLayoutAnimationManager alloc] initWithLynxUI:self];
  }
}

- (void)prepareTransitionAnimationManager {
  _backgroundManager.implicitAnimation = false;
  if (!_transitionAnimationManager) {
    _transitionAnimationManager = [[LynxTransitionAnimationManager alloc] initWithLynxUI:self];
  }
}

// create
LYNX_PROP_DEFINE("layout-animation-create-duration", setLayoutAnimationCreateDuration,
                 NSTimeInterval) {
  if (requestReset) {
    value = 0;
  }
  [self prepareLayoutAnimationManager];
  if (IS_ZERO(value)) {
    [self.view.layer removeAllAnimations];
    [self.backgroundManager removeAllAnimations];
  }
  _layoutAnimationManager.createConfig.duration = value;
}

LYNX_PROP_DEFINE("layout-animation-create-delay", setLayoutAnimationCreateDelay, NSTimeInterval) {
  if (requestReset) {
    value = 0;
  }
  [self prepareLayoutAnimationManager];
  _layoutAnimationManager.createConfig.delay = value;
}

LYNX_PROP_DEFINE("layout-animation-create-property", setLayoutAnimationCreateProperty,
                 LynxAnimationProp) {
  if (requestReset) {
    value = NONE;
  }
  [self prepareLayoutAnimationManager];
  _layoutAnimationManager.createConfig.prop = value;
}

LYNX_PROP_DEFINE("layout-animation-create-timing-function", setLayoutAnimationCreateTimingFunction,
                 CAMediaTimingFunction*) {
  if (requestReset) {
    value = [LynxConverter toCAMediaTimingFunction:nil];
  }
  [self prepareLayoutAnimationManager];
  _layoutAnimationManager.createConfig.timingFunction = value;
}

// update
LYNX_PROP_DEFINE("layout-animation-update-duration", setLayoutAnimationUpdateDuration,
                 NSTimeInterval) {
  if (requestReset) {
    value = 0;
  }
  [self prepareLayoutAnimationManager];
  if (IS_ZERO(value)) {
    [self.view.layer removeAllAnimations];
    [self.backgroundManager removeAllAnimations];
  }
  _layoutAnimationManager.updateConfig.duration = value;
}

LYNX_PROP_DEFINE("layout-animation-update-delay", setLayoutAnimationUpdateDelay, NSTimeInterval) {
  if (requestReset) {
    value = 0;
  }
  [self prepareLayoutAnimationManager];
  _layoutAnimationManager.updateConfig.delay = value;
}

LYNX_PROP_DEFINE("layout-animation-update-property", setLayoutAnimationUpdateProperty,
                 LynxAnimationProp) {
  if (requestReset) {
    value = NONE;
  }
  [self prepareLayoutAnimationManager];
  _layoutAnimationManager.updateConfig.prop = value;
}

LYNX_PROP_DEFINE("layout-animation-update-timing-function", setLayoutAnimationUpdateTimingFunction,
                 CAMediaTimingFunction*) {
  if (requestReset) {
    value = [LynxConverter toCAMediaTimingFunction:nil];
  }
  [self prepareLayoutAnimationManager];
  _layoutAnimationManager.updateConfig.timingFunction = value;
}

// delete
LYNX_PROP_DEFINE("layout-animation-delete-duration", setLayoutAnimationDeleteDuration,
                 NSTimeInterval) {
  if (requestReset) {
    value = 0.0;
  }
  [self prepareLayoutAnimationManager];
  if (IS_ZERO(value)) {
    [self.view.layer removeAllAnimations];
    [self.backgroundManager removeAllAnimations];
  }
  _layoutAnimationManager.deleteConfig.duration = value;
}

LYNX_PROP_DEFINE("layout-animation-delete-delay", setLayoutAnimationDeleteDelay, NSTimeInterval) {
  if (requestReset) {
    value = 0.0;
  }
  [self prepareLayoutAnimationManager];
  _layoutAnimationManager.deleteConfig.delay = value;
}

LYNX_PROP_DEFINE("layout-animation-delete-property", setLayoutAnimationDeleteProperty,
                 LynxAnimationProp) {
  if (requestReset) {
    value = NONE;
  }
  [self prepareLayoutAnimationManager];
  _layoutAnimationManager.deleteConfig.prop = value;
}

LYNX_PROP_DEFINE("layout-animation-delete-timing-function", setLayoutAnimationDeleteTimingFunction,
                 CAMediaTimingFunction*) {
  if (requestReset) {
    value = [LynxConverter toCAMediaTimingFunction:nil];
  }
  [self prepareLayoutAnimationManager];
  _layoutAnimationManager.deleteConfig.timingFunction = value;
}

LYNX_PROP_DEFINE("font-size", setFontSize, CGFloat) {
  if (requestReset) {
    value = 14;
  }
  if (_fontSize != value) {
    _fontSize = value;
  }
}

#pragma mark - Transition

LYNX_PROP_DEFINE("transition", setTransitions, NSArray*) {
  if (requestReset) {
    value = nil;
  }
  [self prepareTransitionAnimationManager];
  if ([value isEqual:[NSNull null]] || value == nil || value.count == 0) {
    [_transitionAnimationManager removeAllTransitionAnimation];
    _transitionAnimationManager = nil;
    return;
  }
  [_transitionAnimationManager assembleTransitions:value];
}

LYNX_PROP_DEFINE("lynx-test-tag", setTestTag, NSString*) {
  if (requestReset) {
    value = @"";
  }
  if (_context.isDev) {
    self.useDefaultAccessibilityLabel = NO;
    self.view.isAccessibilityElement = YES;
    // TODO: use accessibilityIdentifier instead of accessibilityLabel
    self.view.accessibilityLabel = value;
  }
}

- (void)setOverflowMask:(short)mask withValue:(LynxOverflowType)val {
  short newVal = _overflow;
  if (val == LynxOverflowVisible) {
    newVal |= mask;
  } else {
    newVal &= ~mask;
  }
  self.view.clipsToBounds = (newVal == 0);
  if (newVal != _overflow) {
    _overflow = newVal;
    [self updateLayerMaskOnFrameChanged];
  }
}

- (void)setImplicitAnimation {
  _backgroundManager.implicitAnimation = _context.defaultImplicitAnimation;
}

- (short)overflow {
  return _overflow;
}

- (CGSize)frameSize {
  return self.frame.size;
}

LYNX_PROP_DEFINE("user-interaction-enabled", setUserInteractionEnabled, BOOL) {
  if (requestReset) {
    value = YES;
  }
  _userInteractionEnabled = value;
}

LYNX_PROP_DEFINE("native-interaction-enabled", setNativeInteractionEnabled, BOOL) {
  if (requestReset) {
    value = YES;
  }
  _view.userInteractionEnabled = value;
}

LYNX_PROP_DEFINE("allow-edge-antialiasing", setAllowEdgeAntialiasing, BOOL) {
  if (requestReset) {
    value = NO;
  }
  _view.layer.allowsEdgeAntialiasing = value;
  _backgroundManager.allowsEdgeAntialiasing = value;
}

LYNX_PROP_DEFINE("overflow-x", setOverflowX, LynxOverflowType) {
  if (requestReset) {
    value = [self getInitialOverflowType];
  }
  [self setOverflowMask:OVERFLOW_X_VAL withValue:value];
}

LYNX_PROP_DEFINE("overflow-y", setOverflowY, LynxOverflowType) {
  if (requestReset) {
    value = [self getInitialOverflowType];
  }
  [self setOverflowMask:OVERFLOW_Y_VAL withValue:value];
}
LYNX_PROP_DEFINE("overflow", setOverflow, LynxOverflowType) {
  if (requestReset) {
    value = [self getInitialOverflowType];
  }
  [self setOverflowMask:OVERFLOW_XY_VAL withValue:value];
}

LYNX_PROP_DEFINE("background-clip", setBackgroundClip, NSArray*) {
  [_backgroundManager.backgroundClip removeAllObjects];
  if (requestReset) {
    value = [NSArray new];
  }

  for (NSNumber* clip in value) {
    [_backgroundManager addBackgroundClip:[clip integerValue]];
  }

  [self.view setNeedsDisplay];
}

LYNX_PROP_DEFINE("caret-color", setCaretColor, NSString*) {
  // implemented by components
}

LYNX_PROP_DEFINE("consume-slide-event", setConsumeSlideEvent, NSArray*) {
  // If requestReset, let value be nil. If the value is not nil, check each item of the value to see
  // if it is NSArray and the first two items are NSNumber. If it meets the conditions, put it into
  // _angleArray. Otherwise, skip the item. If _angleArray is not empty, needCheckConsumeSlideEvent
  // is executed to indicate that consumeSlideEvent detection is needed.
  if (requestReset) {
    value = nil;
  }
  _angleArray = [[NSMutableArray alloc] init];
  for (id obj in value) {
    if (![obj isKindOfClass:[NSArray class]]) {
      continue;
    }
    NSArray* ary = (NSArray*)obj;
    if (ary.count >= 2 && [ary[0] isKindOfClass:[NSNumber class]] &&
        [ary[1] isKindOfClass:[NSNumber class]]) {
      [_angleArray addObject:ary];
    }
  }
  if ([_angleArray count] > 0) {
    [self.context.eventHandler needCheckConsumeSlideEvent];
  }
}

- (BOOL)consumeSlideEvent:(CGFloat)angle {
  // Traverse `_angleArray` and check if the given angle falls within each angle interval. If the
  // condition is met, return YES, indicating that the current LynxUI needs to consume slide events.
  // Otherwise, return NO indicating that the current LynxUI does not need to consume slide events.
  __block BOOL res = NO;
  [_angleArray enumerateObjectsUsingBlock:^(NSArray<NSNumber*>* _Nonnull obj, NSUInteger idx,
                                            BOOL* _Nonnull stop) {
    if (angle >= obj[0].doubleValue && angle <= obj[1].doubleValue) {
      res = YES;
      *stop = YES;
    }
  }];
  return res;
}

LYNX_PROP_DEFINE("block-native-event", setBlockNativeEvent, BOOL) {
  if (requestReset) {
    value = false;
  }
  _blockNativeEvent = value;
}

LYNX_PROP_DEFINE("block-native-event-areas", setBlockNativeEventAreas, NSArray*) {
  if (requestReset) {
    value = nil;
  }
  _blockNativeEventAreas = nil;
  if (![value isKindOfClass:[NSArray class]]) {
    LLogWarn(@"block-native-event-areas: type err: %@", value);
    return;
  }
  // 支持`30px`，`50%`两种类型
  NSMutableArray<NSArray<LynxSizeValue*>*>* blockNativeEventAreas = [NSMutableArray array];
  [value enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
    if ([obj isKindOfClass:[NSArray class]] && [(NSArray*)obj count] == 4) {
      NSArray* area = obj;
      LynxSizeValue* x = [LynxSizeValue sizeValueFromCSSString:area[0]];
      LynxSizeValue* y = [LynxSizeValue sizeValueFromCSSString:area[1]];
      LynxSizeValue* w = [LynxSizeValue sizeValueFromCSSString:area[2]];
      LynxSizeValue* h = [LynxSizeValue sizeValueFromCSSString:area[3]];
      if (x && y && w && h) {
        [blockNativeEventAreas addObject:@[ x, y, w, h ]];
      } else {
        LLogWarn(@"block-native-event-areas: %luth type err", (unsigned long)idx);
      }
    } else {
      LLogWarn(@"block-native-event-areas: %luth type err, size != 4", (unsigned long)idx);
    }
  }];
  if ([blockNativeEventAreas count] > 0) {
    _blockNativeEventAreas = [blockNativeEventAreas copy];
  } else {
    LLogWarn(@"block-native-event-areas: empty areas");
  }
}

// Temp setting for 2022 Spring Festival activities. Remove this later, and solve the similar
// problems by implementing flexible handling of conflicts between Lynx gestures and Native gestures
// in the future.
LYNX_PROP_DEFINE("ios-enable-simultaneous-touch", setEnableSimultaneousTouch, BOOL) {
  if (requestReset) {
    value = false;
  }
  _enableSimultaneousTouch = value;
}

- (BOOL)enableSimultaneousTouch {
  return _enableSimultaneousTouch;
}

LYNX_PROP_DEFINE("enable-touch-pseudo-propagation", setEnableTouchPseudoPropagation, BOOL) {
  if (requestReset) {
    value = YES;
  }
  _enableTouchPseudoPropagation = value;
}

- (BOOL)enableTouchPseudoPropagation {
  return _enableTouchPseudoPropagation;
}

- (void)onPseudoStatusFrom:(int32_t)preStatus changedTo:(int32_t)currentStatus {
  _pseudoStatus = currentStatus;
}

LYNX_PROP_DEFINE("event-through", setEventThrough, BOOL) {
  // If requestReset, the _eventThrough will be Undefined.
  enum LynxEventPropStatus res = kLynxEventPropUndefined;
  if (requestReset) {
    _eventThrough = res;
    return;
  }
  _eventThrough = value ? kLynxEventPropEnable : kLynxEventPropDisable;
}

- (BOOL)eventThrough {
  // If _eventThrough == Enable, return true. If _eventThrough == Disable, return false.
  // If _eventThrough == Undefined && parent not nil, return parent._eventThrough.
  if (_eventThrough == kLynxEventPropEnable) {
    return true;
  } else if (_eventThrough == kLynxEventPropDisable) {
    return false;
  }

  id<LynxEventTarget> parent = [self parentTarget];
  if (parent != nil) {
    // when parent is root ui, return false.
    if ([parent isKindOfClass:[LynxRootUI class]]) {
      return false;
    }
    return [parent eventThrough];
  }
  return false;
}

- (BOOL)blockNativeEvent:(UIGestureRecognizer*)gestureRecognizer {
  BOOL blockNativeEventAll = _blockNativeEvent;
  if (blockNativeEventAll) {
    return YES;
  }
  if (!_blockNativeEventAreas) {
    return NO;
  }
  CGPoint p = [gestureRecognizer locationInView:self.view];
  CGSize size = self.view.bounds.size;

  __block BOOL blockNativeEventThisPoint = NO;
  [_blockNativeEventAreas enumerateObjectsUsingBlock:^(NSArray<LynxSizeValue*>* _Nonnull obj,
                                                       NSUInteger idx, BOOL* _Nonnull stop) {
    if ([obj count] == 4) {
      CGFloat left = [obj[0] convertToDevicePtWithFullSize:size.width];
      CGFloat top = [obj[1] convertToDevicePtWithFullSize:size.height];
      CGFloat right = left + [obj[2] convertToDevicePtWithFullSize:size.width];
      CGFloat bottom = top + [obj[3] convertToDevicePtWithFullSize:size.height];
      blockNativeEventThisPoint = p.x >= left && p.x < right && p.y >= top && p.y < bottom;
      if (blockNativeEventThisPoint) {
        LLogInfo(@"blocked this point!");
        *stop = YES;
      }
    }
  }];
  return blockNativeEventThisPoint;
}

LYNX_PROP_SETTER("a11y-id", setA11yID, NSString*) { self.a11yID = value; }

LYNX_PROP_DEFINE("ignore-focus", setIgnoreFocus, BOOL) {
  if (requestReset) {
    value = false;
  }
  _ignoreFocus = value;
}

LYNX_PROP_SETTER("exposure-scene", setExposureScene, NSString*) {
  if (requestReset) {
    value = nil;
  }
  [_context removeUIFromExposuredMap:self];
  _exposureScene = value;
}

LYNX_PROP_SETTER("exposure-id", setExposureID, NSString*) {
  if (requestReset) {
    value = nil;
  }
  [_context removeUIFromExposuredMap:self];
  _exposureID = value;
}

LYNX_PROP_SETTER("exposure-screen-margin-top", setExposureScreenMarginTop, NSString*) {
  if (requestReset) {
    value = nil;
  }
  [_context removeUIFromExposuredMap:self];
  _exposureMarginTop = [LynxUnitUtils toPtFromUnitValue:value];
}

LYNX_PROP_SETTER("exposure-screen-margin-bottom", setExposureScreenMarginBottom, NSString*) {
  if (requestReset) {
    value = nil;
  }
  [_context removeUIFromExposuredMap:self];
  _exposureMarginBottom = [LynxUnitUtils toPtFromUnitValue:value];
}

LYNX_PROP_SETTER("exposure-screen-margin-left", setExposureScreenMarginLeft, NSString*) {
  if (requestReset) {
    value = nil;
  }
  [_context removeUIFromExposuredMap:self];
  _exposureMarginLeft = [LynxUnitUtils toPtFromUnitValue:value];
}

LYNX_PROP_SETTER("exposure-screen-margin-right", setExposureScreenMarginRight, NSString*) {
  if (requestReset) {
    value = nil;
  }
  [_context removeUIFromExposuredMap:self];
  _exposureMarginRight = [LynxUnitUtils toPtFromUnitValue:value];
}

LYNX_PROP_SETTER("enable-exposure-ui-margin", setEnableExposureUIMargin, BOOL) {
  enum LynxPropStatus res = kLynxPropUndefined;
  if (requestReset) {
    _enableExposureUIMargin = res;
    return;
  }
  _enableExposureUIMargin = value ? kLynxPropEnable : kLynxPropDisable;
}

- (BOOL)enableExposureUIMargin {
  if (_enableExposureUIMargin == kLynxPropEnable) {
    return true;
  } else if (_enableExposureUIMargin == kLynxPropDisable) {
    return false;
  }
  // read from pageConfig
  return [_context enableExposureUIMargin];
}

LYNX_PROP_SETTER("exposure-ui-margin-top", setExposureUIMarginTop, NSString*) {
  if (requestReset) {
    value = nil;
  }
  _exposureUIMarginTop = value;
}

LYNX_PROP_SETTER("exposure-ui-margin-bottom", setExposureUIMarginBottom, NSString*) {
  if (requestReset) {
    value = nil;
  }
  _exposureUIMarginBottom = value;
}

LYNX_PROP_SETTER("exposure-ui-margin-left", setExposureUIMarginLeft, NSString*) {
  if (requestReset) {
    value = nil;
  }
  _exposureUIMarginLeft = value;
}

LYNX_PROP_SETTER("exposure-ui-margin-right", setExposureUIMarginRight, NSString*) {
  if (requestReset) {
    value = nil;
  }
  _exposureUIMarginRight = value;
}

LYNX_PROP_SETTER("exposure-area", setExposureArea, NSString*) {
  if (requestReset) {
    value = nil;
  }
  _exposureArea = value;
}

LYNX_PROP_SETTER("block-list-event", setBlockListEvent, BOOL) { self.blockListEvent = value; }

LYNX_PROP_SETTER("align-height", setAlignHeight, BOOL) { _alignHeight = value; }

LYNX_PROP_SETTER("align-width", setAlignWidth, BOOL) { _alignWidth = value; }

// this prop only be used in "ref" within ReactLynx and should not be explicitly used in ttml by
// user
LYNX_PROP_DEFINE("react-ref", setRefId, NSString*) {
  if (requestReset) {
    value = @"";
  }
  _refId = value;
}

LYNX_PROP_DEFINE("dataset", setDataset, NSDictionary*) {
  if (requestReset) {
    value = [NSDictionary dictionary];
  }

  _dataset = value;
}

LYNX_PROP_DEFINE("intersection-observers", setIntersectionObservers, NSArray*) {
  if (requestReset) {
    value = [NSArray array];
  }
  [_context.intersectionManager removeAttachedIntersectionObserver:self];
  if (!value || [value count] == 0) {
    return;
  }
  for (NSUInteger idx = 0; idx < [value count]; idx++) {
    NSDictionary* propsObject = value[idx];
    if (propsObject) {
      LynxUIIntersectionObserver* observer =
          [[LynxUIIntersectionObserver alloc] initWithOptions:propsObject
                                                      manager:_context.intersectionManager
                                                   attachedUI:self];
      [_context.intersectionManager addIntersectionObserver:observer];
    }
  }
}

LYNX_PROP_SETTER("enable-scroll-monitor", setEnableScrollMonitor, BOOL) {
  if (requestReset) {
    value = NO;
  }
  _enableScrollMonitor = value;
}

LYNX_PROP_SETTER("scroll-monitor-tag", setScrollMonitorTag, NSString*) {
  if (requestReset) {
    value = nil;
  }
  _scrollMonitorTagName = value;
}

LYNX_PROP_SETTER("filter", setFilter, NSArray*) {
  float amount = .0f;

  if (requestReset || [value count] != 3) {
    amount = .0f;
    _filter_type = LynxFilterTypeNone;
  } else {
    _filter_type = [(NSNumber*)[value objectAtIndex:0] intValue];
    amount = [(NSNumber*)[value objectAtIndex:1] floatValue];
  }

  switch (_filter_type) {
    case LynxFilterTypeGrayScale:
      amount = 1 - amount;
      _filter_amount = [LynxUnitUtils clamp:amount min:0.0f max:1.0f];
      break;
    case LynxFilterTypeBlur:
    default:
      _filter_amount = amount;
  }

  id filter = [self getFilterWithType:_filter_type];
  if (filter) {
    self.view.layer.filters = @[ filter ];
    [_backgroundManager setFilters:@[ filter ]];
  } else {
    self.view.layer.filters = nil;
    [_backgroundManager setFilters:nil];
  }
}

LYNX_PROP_DEFINE("overlap-ios", setOverlapRendering, BOOL) {
  if (requestReset) {
    value = NO;
  }
  _backgroundManager.overlapRendering = value;
}

LYNX_PROP_DEFINE("background-shape-layer", setUseBackgroundShapeLayer, BOOL) {
  LynxBgShapeLayerProp enabled =
      requestReset ? LynxBgShapeLayerPropUndefine
                   : (value ? LynxBgShapeLayerPropEnabled : LynxBgShapeLayerPropDisabled);
  [_backgroundManager setUiBackgroundShapeLayerEnabled:enabled];
}

- (id)getFilterWithType:(LynxFilterType)type {
  if (_filter_type == LynxFilterTypeNone) {
    return nil;
  }
  // private api
  NSString* clsName = [NSString stringWithFormat:@"%@%@%@", @"CA", @"Fil", @"ter"];
  Class clz = NSClassFromString(clsName);
  if ([clz respondsToSelector:@selector(filterWithName:)]) {
    NSString* filterName = nil;
    NSString* keyPath = nil;
    switch (type) {
      case LynxFilterTypeGrayScale:
        filterName = [NSString stringWithFormat:@"%@%@%@", @"colo", @"rSatu", @"rate"];
        keyPath = [NSString stringWithFormat:@"%@%@%@", @"inpu", @"tAmo", @"unt"];
        break;
      case LynxFilterTypeBlur:
        filterName = [NSString stringWithFormat:@"%@%@%@", @"gauss", @"ianB", @"lur"];
        keyPath = [NSString stringWithFormat:@"%@%@%@", @"inpu", @"tRad", @"ius"];
        break;
      default:
        // No such filter
        return nil;
    };
    id filter = [clz filterWithName:filterName];
    [filter setValue:[NSNumber numberWithFloat:_filter_amount] forKey:keyPath];
    return filter;
  }
  // Api get failed.
  return nil;
}

// override by subclass
- (void)onAnimationStart:(NSString*)type
              startFrame:(CGRect)startFrame
              finalFrame:(CGRect)finalFrame
                duration:(NSTimeInterval)duration {
}

// override by subclass
- (void)onAnimationEnd:(NSString*)type
            startFrame:(CGRect)startFrame
            finalFrame:(CGRect)finalFrame
              duration:(NSTimeInterval)duratio {
}

- (void)resetAnimation {
  if (nil != _animationManager) {
    [_animationManager resetAnimation];
  }

  [self.children
      enumerateObjectsUsingBlock:^(LynxUI* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        [obj resetAnimation];
      }];
}

- (void)restartAnimation {
  if (nil != _animationManager) {
    [_animationManager restartAnimation];
  }
  [self.children
      enumerateObjectsUsingBlock:^(LynxUI* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        [obj restartAnimation];
      }];
}

- (void)removeAnimationForReuse {
  if (_layoutAnimationManager) {
    [_layoutAnimationManager removeAllLayoutAnimation];
  }
  if (_transitionAnimationManager) {
    [_transitionAnimationManager removeAllTransitionAnimation];
  }
}

- (void)sendLayoutChangeEvent {
  NSString* layoutChangeFunctionName = @"layoutchange";
  if ([self eventSet] && [[self eventSet] valueForKey:layoutChangeFunctionName]) {
    CGRect rect = [self getBoundingClientRect];
    NSDictionary* data = @{
      @"id" : _idSelector ?: @"",
      @"dataset" : @{},
      @"left" : @(rect.origin.x),
      @"right" : @(rect.origin.x + rect.size.width),
      @"top" : @(rect.origin.y),
      @"bottom" : @(rect.origin.y + rect.size.height),
      @"width" : @(rect.size.width),
      @"height" : @(rect.size.height)
    };
    LynxCustomEvent* event = [[LynxDetailEvent alloc] initWithName:layoutChangeFunctionName
                                                        targetSign:[self sign]
                                                            detail:data];
    [self.context.eventEmitter sendCustomEvent:event];
  }
}

/* EventTarget Section Begin */
- (NSInteger)signature {
  return self.sign;
}

- (int32_t)pseudoStatus {
  return _pseudoStatus;
}

- (nullable id<LynxEventTarget>)parentTarget {
  return self.parent;
}

- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
  LynxUI* guard = nil;
  // this is parent response to translate Point coordinate
  if ([self hasCustomLayout]) {
    guard = [self hitTest:point withEvent:event onUIWithCustomLayout:self];
    point = [self.view convertPoint:point toView:guard.view];
  } else {
    CGPoint childPoint = CGPointZero;
    for (LynxUI* child in [self.children reverseObjectEnumerator]) {
      if (![child shouldHitTest:point withEvent:event] || [child.view isHidden]) {
        continue;
      }

      CGPoint targetPoint = [self.view convertPoint:point toView:child.view];
      bool contain = false;
      if (_context.enableEventRefactor) {
        contain = [child containsPoint:targetPoint];
      } else {
        contain = [child containsPoint:point];
      }

      if (contain) {
        if (child.isOnResponseChain) {
          guard = child;
          break;
        }
        if (guard == nil || guard.getTransationZ < child.getTransationZ) {
          guard = child;
          childPoint = targetPoint;
        }
      }
    }
    if (_context.enableEventRefactor) {
      point = childPoint;
    } else {
      point = [guard getHitTestPoint:point];
    }
  }
  if (guard == nil) {
    // no new result
    return self;
  }
  return [guard hitTest:point withEvent:event];
}

- (BOOL)containsPoint:(CGPoint)point inHitTestFrame:(CGRect)frame {
  bool contain = NO;
  if (_context.enableEventRefactor) {
    frame =
        CGRectMake(frame.origin.x - self.touchSlop, frame.origin.y - self.touchSlop,
                   frame.size.width + 2 * self.touchSlop, frame.size.height + 2 * self.touchSlop);
    contain = CGRectContainsPoint(frame, point);
    if (!contain && _overflow != 0) {
      if (_overflow == OVERFLOW_X_VAL) {
        if (!(frame.origin.y - self.touchSlop < point.y &&
              frame.origin.y + frame.size.height + self.touchSlop > point.y)) {
          return contain;
        }
      } else if (_overflow == OVERFLOW_Y_VAL) {
        if (!(frame.origin.x - self.touchSlop < point.x &&
              frame.origin.x + frame.size.width + self.touchSlop > point.x)) {
          return contain;
        }
      }
      contain = [self childrenContainPoint:point];
    }
    return contain;
  }

  frame = CGRectMake(frame.origin.x - self.touchSlop, frame.origin.y - self.touchSlop,
                     frame.size.width + 2 * self.touchSlop, frame.size.height + 2 * self.touchSlop);
  contain = CGRectContainsPoint(frame, point);
  if (!contain && _overflow != 0) {
    if (_overflow == OVERFLOW_X_VAL) {
      if (!(frame.origin.y < point.y && frame.origin.y + frame.size.height > point.y)) {
        return contain;
      }
    } else if (_overflow == OVERFLOW_Y_VAL) {
      if (!(frame.origin.x < point.x && frame.origin.x + frame.size.width > point.x)) {
        return contain;
      }
    }
    contain = [self childrenContainPoint:point];
  }
  return contain;
}

- (BOOL)containsPoint:(CGPoint)point {
  CGRect frame = CGRectZero;
  if (_context.enableEventRefactor) {
    frame = self.view.bounds;
  } else {
    frame = [self getHitTestFrame];
  }
  return [self containsPoint:point inHitTestFrame:frame];
}

- (nullable NSDictionary<NSString*, LynxEventSpec*>*)eventSet {
  return _eventSet;
}

- (BOOL)shouldHitTest:(CGPoint)point withEvent:(nullable UIEvent*)event {
  // If set user-interaction-enabled="{{false}}" or visibility: hidden, this ui will not be on the
  // response chain.
  return _userInteractionEnabled && !self.view.hidden;
}

- (BOOL)isVisible {
  UIView* view = [self view];
  if (view == nil) {
    return NO;
  }

  // if view is hidden, return NO
  if (view.isHidden) {
    return NO;
  }

  // if view's alpha == 0, return NO
  if (view.alpha == 0) {
    return NO;
  }

  // if view's size == 0 and clipsToBounds is true, return NO
  if (view.frame.size.width == 0 || view.frame.size.height == 0) {
    if (view.clipsToBounds) {
      return NO;
    }
  }

  // if list cell is offscreen, return NO. see issue:#7727
  // Not only list inside lynxView, but also UICollectionView outside lynxView
  if ([view.superview.superview isKindOfClass:[UICollectionViewCell class]]) {
    UICollectionViewCell* cellView = (UICollectionViewCell*)view.superview.superview;
    UIView* listView = cellView.superview;
    if ([listView isKindOfClass:[UICollectionView class]]) {
      NSArray<UICollectionViewCell*>* visibleCells = ((UICollectionView*)listView).visibleCells;
      if (![visibleCells containsObject:cellView]) {
        return NO;
      }
    }
  }

  // if foldview cell is offscreen, return NO, like issue:#7727.
  // Not only foldview inside lynxView, but also UITableView outside lynxView
  if ([view.superview.superview.superview.superview.superview.superview.superview
          isKindOfClass:[UITableViewCell class]]) {
    UITableViewCell* cellView =
        (UITableViewCell*)
            view.superview.superview.superview.superview.superview.superview.superview;
    UIView* listView = cellView.superview;
    if ([listView isKindOfClass:[UITableView class]]) {
      NSArray<UITableViewCell*>* visibleCells = ((UITableView*)listView).visibleCells;
      if (![visibleCells containsObject:cellView]) {
        return NO;
      }
    }
  }

  // if view's window is nil, return NO
  return view.window != nil;
}

- (BOOL)ignoreFocus {
  return _ignoreFocus;
}

// only include touches and event, don't care Lynx frontend event
- (BOOL)dispatchTouch:(NSString* const)touchType
              touches:(NSSet<UITouch*>*)touches
            withEvent:(UIEvent*)event {
  return NO;
}

// include target point and Lynx frontend event
- (BOOL)dispatchEvent:(LynxEventDetail*)event {
  return NO;
}

- (void)onResponseChain {
  _onResponseChain = YES;
}

- (void)offResponseChain {
  _onResponseChain = NO;
}

- (BOOL)isOnResponseChain {
  return _onResponseChain;
}

- (double)touchSlop {
  if (_onResponseChain) {
    return _touchSlop;
  }
  return 0;
}

/* EventTarget Section End */

// this can be overriden if a UI typically has more than three layers
- (CALayer*)topLayer {
  if (_backgroundManager) {
    if (_backgroundManager.maskLayer) {
      return _backgroundManager.maskLayer;
    }
    if (_backgroundManager.borderLayer && self.overflow == OVERFLOW_HIDDEN_VAL) {
      return _backgroundManager.borderLayer;
    }
  }
  return self.view.layer;
}

- (CALayer*)bottomLayer {
  if (_backgroundManager) {
    if (_backgroundManager.backgroundLayer) {
      return _backgroundManager.backgroundLayer;
    }
  }
  return self.view.layer;
}

- (BOOL)isRtl {
  return _directionType == LynxDirectionRtl;
}

- (BOOL)enableAccessibilityByDefault {
  return NO;
}

- (BOOL)accessibilityClickable {
  if (!_context.eventEmitter || !_eventSet || _eventSet.count == 0) {
    return NO;
  }
  static NSString* LynxEventTap = @"tap";
  if ([_eventSet valueForKey:LynxEventTap]) {
    return YES;
  } else {
    return NO;
  }
}

- (UIAccessibilityTraits)accessibilityTraitsByDefault {
  return UIAccessibilityTraitNone;
}

- (BOOL)didSizeChanged {
  return !CGRectEqualToRect(_updatedFrame, _lastUpdatedFrame);
}

- (BOOL)shouldReDoTransform {
  return _didTransformChanged ||
         (([LynxTransformRaw hasPercent:_transformRaw] || [_transformOriginRaw isValid]) &&
          [self didSizeChanged]);
}

- (LynxOverflowType)getInitialOverflowType {
  return LynxOverflowHidden;
}

- (void)onListCellAppear:(NSString*)itemKey withList:(LynxUICollection*)list {
  for (LynxUI* child in self.children) {
    if (!child.blockListEvent) {
      [child onListCellAppear:itemKey withList:list];
    }
  }
}

- (void)onListCellDisappear:(NSString*)itemKey
                      exist:(BOOL)isExist
                   withList:(LynxUICollection*)list {
  for (LynxUI* child in self.children) {
    if (!child.blockListEvent) {
      [child onListCellDisappear:itemKey exist:isExist withList:list];
    }
  }
}

- (void)onListCellPrepareForReuse:(NSString*)itemKey withList:(LynxUICollection*)list {
  for (LynxUI* child in self.children) {
    if (!child.blockListEvent) {
      [child onListCellPrepareForReuse:itemKey withList:list];
    }
  }
}

- (BOOL)notifyParent {
  return NO;
}

- (CGFloat)toPtWithUnitValue:(NSString*)unitValue fontSize:(CGFloat)fontSize {
  LynxUI* rootUI = (LynxUI*)self.context.rootUI;
  return [LynxUnitUtils toPtWithScreenMetrics:self.context.screenMetrics
                                    unitValue:unitValue
                                 rootFontSize:rootUI.fontSize
                                  curFontSize:fontSize
                                    rootWidth:CGRectGetWidth(rootUI.frame)
                                   rootHeight:CGRectGetHeight(rootUI.frame)
                                withDefaultPt:0];
}

- (UIView*)accessibilityAttachedCell {
  if (!self.accessibilityAttachedCellClass) {
    return nil;
  }
  if (!_accessibilityAttachedCell) {
    // find attached cell from lower to upper
    UIView* view = self.view;
    while (view && ![view isKindOfClass:self.accessibilityAttachedCellClass]) {
      view = view.superview;
    }
  }
  return _accessibilityAttachedCell;
}

- (void)autoScrollIfFocusedChanged:(NSNotification*)notification {
  if (@available(iOS 9.0, *)) {
    UIView* currentFocusedElement = notification.userInfo[UIAccessibilityFocusedElementKey];
    if ([currentFocusedElement isKindOfClass:UIView.class]) {
      NSArray* array;
      UIView* cell = [self accessibilityAttachedCell];
      if (cell) {
        array = cell.accessibilityElements;
      } else {
        array = self.view.accessibilityElements;
      }

      // Automatically scroll to the focused item
      if ([array containsObject:currentFocusedElement]) {
        UIScrollView* scrollView = [self accessibilityFindScrollView:currentFocusedElement];
        if (scrollView) {
          // handle both horizontal and vertical
          if (scrollView.contentSize.width > scrollView.contentSize.height) {
            // scroll to center horizontally
            CGPoint pointCenterInScrollView =
                [currentFocusedElement convertPoint:currentFocusedElement.center toView:scrollView];
            CGPoint targetOffset = CGPointMake(0, scrollView.contentOffset.y);
            targetOffset.x =
                pointCenterInScrollView.x - currentFocusedElement.frame.size.width / 2.0;
            // we can not scroll beyond bounces
            targetOffset.x =
                MAX(-scrollView.contentInset.left,
                    MIN(targetOffset.x, scrollView.contentSize.width - scrollView.frame.size.width +
                                            scrollView.contentInset.right));
            [scrollView setContentOffset:targetOffset];
          } else if (scrollView.contentSize.width < scrollView.contentSize.height) {
            // scroll to center vertically
            CGPoint pointCenterInScrollView =
                [currentFocusedElement convertPoint:currentFocusedElement.center toView:scrollView];
            CGPoint targetOffset = CGPointMake(scrollView.contentOffset.x, 0);
            targetOffset.y =
                pointCenterInScrollView.y - currentFocusedElement.frame.size.height / 2.0;
            // we can not scroll beyond bounces
            targetOffset.y = MAX(
                -scrollView.contentInset.top,
                MIN(targetOffset.y, scrollView.contentSize.height - scrollView.frame.size.height +
                                        scrollView.contentInset.bottom));
            [scrollView setContentOffset:targetOffset];
          }
        }
      }
    }
  }
}

- (UIScrollView*)accessibilityFindScrollView:(UIView*)child {
  // find the first LynxScrollView which contains the target view
  UIView* view = child;
  Class cls = NSClassFromString(@"LynxScrollView");
  while (view && ![view isKindOfClass:cls]) {
    view.accessibilityElementsHidden = NO;
    view = view.superview;
  }
  return (UIScrollView*)view;
}

/// General API to set value via KVC for all layers, which are owned by this UI and parallel to the
/// LynxUI.view.layer, in `LynxBackgroundManager`. Currently backgroundLayer, borderLayer and
/// maskLayer.
///
/// - Parameters:
///   - value: value for key.
///   - keyPath: key path for for layer's property.
///   - forAllLayers: true to set the value for all layers related to the UI, and parallel to the
///   view.layer. (background layer, border layer, mask layer)
- (void)setLayerValue:(id)value
           forKeyPath:(nonnull NSString*)keyPath
         forAllLayers:(BOOL)forAllLayers {
  [self.view.layer setValue:value forKeyPath:keyPath];

  if (forAllLayers) {
    [self.backgroundManager.backgroundLayer setValue:value forKeyPath:keyPath];
    [self.backgroundManager.borderLayer setValue:value forKeyPath:keyPath];
    [self.backgroundManager.maskLayer setValue:value forKeyPath:keyPath];
  }
}

/**
 * @name: should-rasterize-shadow
 * @description: 使用bitmap backend绘制阴影，避免离屏
 * @note: box-shadow
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.8
 **/
LYNX_PROP_DEFINE("should-rasterize-shadow", setShouldRasterizeShadow, BOOL) {
  if (requestReset) {
    value = NO;
  }
  _backgroundManager.shouldRasterizeShadow = value;
}

/**
 * @name: accessibility-attached-cell-class
 * @description: Identifying the class name of a UITableViewCell. If the LynxView is in a
 * UITableViewCell, we have to set accessibilityElements to the cell itself, so that accessibility
 * changes can be responded.
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.8
 **/
LYNX_PROP_DEFINE("accessibility-attached-cell-class", setAccessibilityAttachedCellClass,
                 NSString*) {
  // Rest the class and the cell, and will fetch the cell later in `onNodeReady`
  self.accessibilityAttachedCellClass = NSClassFromString(value);
  _accessibilityAttachedCell = nil;
}

/**
 * @name: accessibility-auto-scroll-if-focused
 * @description: Automatically scroll to focused accessibility element if it is focused by code.
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.8
 **/
LYNX_PROP_DEFINE("accessibility-auto-scroll-if-focused", setAccessibilityAutoScrollIfFocused,
                 BOOL) {
  self.accessibilityAutoScroll = value;
}

/// This is a standard CSS property `clip-path`
/// - Parameter basicShape: <basic-shape-function> = [function type, params]
LYNX_PROP_DEFINE("clip-path", setClipPath, NSArray*) {
  if (requestReset || !value || [value count] < 1) {
    _clipPath = nil;
    // reset the layer mask.
    [self updateLayerMaskOnFrameChanged];
    return;
  }
  LynxBasicShapeType type = [[value objectAtIndex:0] intValue];
  switch (type) {
    case LynxBasicShapeTypeInset: {
      _clipPath = LBSCreateBasicShapeFromArray(value);
      break;
    }
    default:
      _clipPath = nil;
  }
  [self updateLayerMaskOnFrameChanged];
}

@end
