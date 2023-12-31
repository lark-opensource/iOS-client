//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "BDXLynxOverlayLight.h"
#import "BDXLynxOverlayLightContainer.h"
#import "BDXLynxOverlayGlobalManager.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxCustomMeasureShadowNode.h>
#import <Lynx/LynxNativeLayoutNode.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/UIView+Lynx.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/LynxUI+Internal.h>
#import <Lynx/LynxEventHandler.h>
#import <Lynx/LynxTouchHandler.h>
#import <Lynx/LynxRootUI.h>
#import <Lynx/LynxViewVisibleHelper.h>
#import <Lynx/LynxGlobalObserver.h>


@interface LynxOverlayShadowNode : LynxCustomMeasureShadowNode

@end


@implementation LynxOverlayShadowNode

LYNX_LAZY_REGISTER_SHADOW_NODE("x-overlay-ng")


/**
 *  Customize Overlay's  measure strategy
 */
- (MeasureResult)customMeasureLayoutNode:(nonnull MeasureParam *)param
                          measureContext:(nullable MeasureContext *)context {
  [self.children enumerateObjectsUsingBlock:
   ^(LynxShadowNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ([obj isKindOfClass:[LynxNativeLayoutNode class]]) {
      // Overlay's frame is always equal to the screen, its child should be measured correctly
      MeasureParam *childParam = [[MeasureParam alloc] initWithWidth:UIScreen.mainScreen.bounds.size.width - obj.style.computedMarginLeft - obj.style.computedMarginRight
                                                           WidthMode:LynxMeasureModeDefinite
                                                              Height:UIScreen.mainScreen.bounds.size.height - obj.style.computedMarginTop - obj.style.computedMarginBottom
                                                          HeightMode:LynxMeasureModeDefinite];
      LynxNativeLayoutNode *child = (LynxNativeLayoutNode *)obj;
      [child measureWithMeasureParam:childParam MeasureContext:context];
    }
  }];
  // Overlay itself will never take up any space
  return (MeasureResult){CGSizeZero};
}


- (void)customAlignLayoutNode:(nonnull AlignParam *)param
                 alignContext:(nonnull AlignContext *)context {
  [self.children enumerateObjectsUsingBlock:
   ^(LynxShadowNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ([obj isKindOfClass:[LynxNativeLayoutNode class]]) {
      LynxNativeLayoutNode *child = (LynxNativeLayoutNode *)obj;
      AlignParam *param = [[AlignParam alloc] init];
      // apply margin to child
      [param SetAlignOffsetWithLeft:child.style.computedMarginLeft Top:child.style.computedMarginTop];
      [child alignWithAlignParam:param AlignContext:context];
    }
  }];
}


@end

typedef NS_ENUM(NSInteger, BDLynxOverlayTouchEvent) {
  BDLynxOverlayTouchEventUnknown = -1,
  BDLynxOverlayTouchEventBegan = 0,
  BDLynxOverlayTouchEventChanged = 1,
  BDLynxOverlayTouchEventEnded = 2,
};


@interface BDXLynxOverlayLight() <BDXLynxOverlayLightViewDelegate,LynxViewVisibleHelper>
// props
@property (nonatomic, assign) BOOL visible;
@property (nonatomic, assign) BOOL eventPassThrough;
@property (nonatomic, assign) BOOL allowPanGesture;
@property (nonatomic, assign) BDXLynxOverlayLightMode mode;
@property (nonatomic, assign) NSInteger level;
@property (nonatomic, strong) NSString *nestScrollViewID;

// nested scrollview in overlay, to resolve conflicts between scroll events and PanGesture
@property (nonatomic, strong) UIScrollView *nestScrollView;

// marks that overlay will be visible
@property (nonatomic, assign) BOOL willBecomeVisible;

@property (nonatomic, strong) Class customViewControllerClass;

@property (nonatomic, weak) UIViewController *customViewController;

@property (nonatomic, assign) BOOL notAdjustLeftMargin;

@property (nonatomic, assign) BOOL notAdjustTopMargin;

@end

@implementation BDXLynxOverlayLight


LYNX_LAZY_REGISTER_UI("x-overlay-ng")


#pragma mark - LynxUI

- (instancetype)init {
  if (self = [super init]) {
    // init default value
    self.eventPassThrough = YES;
    self.level = 1;
    self.notAdjustLeftMargin = YES;
    self.notAdjustTopMargin = YES;
  }
  return self;
}

- (UIView *)createView {
  BDXLynxOverlayLightContainer *container = [[BDXLynxOverlayLightContainer alloc] init];
  container.uiDelegate = self;
  return container;
}

/**
 *  Refresh UI and some status after props or layout updated
 */
- (void)onNodeReady {
  [super onNodeReady];
  
  // Overlay's frame must be equal to UIScreen
  self.view.frame = UIScreen.mainScreen.bounds;
  
  // add Overlay's view to global container according to its level and mode
  UIView *container = [[BDXLynxOverlayGlobalManager sharedInstance] showOverlayView:self.view atLevel:self.level withMode:self.mode customViewController:self.customViewController];
  
  // reset frame if container has its own offset
  CGPoint offset = [[self windowContainer] convertPoint:CGPointZero toView:container];
  
  CGRect rect = {(self.notAdjustLeftMargin ? 0 : offset.x), (self.notAdjustTopMargin ? 0 : offset.y), UIScreen.mainScreen.bounds.size};
  self.view.frame = rect;
  
  // make sure Overlay is always at the front
  if (self.willBecomeVisible) {
    self.willBecomeVisible = NO;
    [self.view.superview bringSubviewToFront:self.view];
  }
  
  if (self.view.hidden != !self.visible) {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:self.visible ? @"showoverlay" : @"dismissoverlay"
                                                        targetSign:[self sign]
                                                            detail:nil];
    [self.context.eventEmitter dispatchCustomEvent:event];
  }
  
  self.view.hidden = !self.visible;
  
  // find nested scroll view
  if (self.nestScrollViewID) {
    UIView *rootView = [((LynxView*)self.context.rootView) viewWithIdSelector:self.nestScrollViewID];
    if ([self checkNestedScrollView:(UIScrollView *)rootView]) {
      self.nestScrollView = (UIScrollView *)rootView;
    } else {
      self.nestScrollView = [self findNestedScrollView:rootView.subviews];
    }
  } else {
    self.nestScrollView = nil;
  }
  
}

- (BOOL)blockNativeEvent:(UIGestureRecognizer*)gestureRecognizer {
  return !self.allowPanGesture;
}

/**
 *  The LynxUI of Overlay itself will not respond to any gesture, the logic is removed to BDXLynxOverlayLightContainer
 */
- (BOOL)shouldHitTest:(CGPoint)point withEvent:(nullable UIEvent*)event {
    return NO;
}

- (BOOL)IsViewVisible {
    return _visible;
}

#pragma mark - LYNX_PROPS

LYNX_PROP_SETTER("visible", setVisible, BOOL) {
  if (value && !self.visible) {
    self.willBecomeVisible = YES;
  }
  self.visible = value;
}

LYNX_PROP_SETTER("allow-pan-gesture", setAllowPanGesture, BOOL) {
  self.allowPanGesture = value;
}

LYNX_PROP_SETTER("mode", setMode, NSString *) {
  if ([value isEqualToString:@"page"]) {
    self.mode = BDXLynxOverlayLightModePage;
  } else if ([value isEqualToString:@"top"]) {
    self.mode = BDXLynxOverlayLightModeTopController;
  } else if (NSClassFromString(value)) {
    self.mode = BDXLynxOverlayLightModeCustom;
    self.customViewControllerClass = NSClassFromString(value);
  } else {
    self.mode = BDXLynxOverlayLightModeWindow;
  } 
}

LYNX_PROP_SETTER("level", setLevel, NSInteger) {
  self.level = value;
}

LYNX_PROP_SETTER("events-pass-through", setEventPassthrough, BOOL) {
  self.eventPassThrough = value;
}

LYNX_PROP_SETTER("nest-scroll", setNestScroll, NSString *) {
  self.nestScrollViewID = value;
}

#pragma mark - BDXLynxOverlayLightViewDelegate

- (BOOL)forbidPanGesture {
  return !self.allowPanGesture;
}

- (BOOL)eventPassed {
  return self.eventPassThrough;
}

- (NSInteger)getSign {
  return self.sign;
}

- (void)requestClose:(NSDictionary *)info {
  LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"onRequestClose"
                                                      targetSign:[self sign]
                                                          detail:nil];
  [self.context.eventEmitter dispatchCustomEvent:event];
    [self.context.observer notifyLayout:NULL];
}

- (LynxUI*)overlayRootUI {
  return self;
}

/**
 *  Expose pan gesture to lepus
 */
- (void)overlayMoved:(CGPoint)point state:(UIGestureRecognizerState)state velocity:(CGPoint)velocity{
  NSInteger eventState = BDLynxOverlayTouchEventUnknown;
  switch (state) {
    case UIGestureRecognizerStateBegan:
      eventState = BDLynxOverlayTouchEventBegan;
      break;
    case UIGestureRecognizerStateChanged:
      eventState = BDLynxOverlayTouchEventChanged;
      break;
    case UIGestureRecognizerStateEnded:
      eventState = BDLynxOverlayTouchEventEnded;
      break;
    default:
      break;
  }
  LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"overlaymoved"
                                                                targetSign:[self sign]
                                                          detail:@{
    @"x" : @(point.x),
    @"y" : @(point.y),
    @"vx": @(velocity.x),
    @"vy": @(velocity.y),
    @"state" : @(eventState)
  }];
  [self.context.eventEmitter dispatchCustomEvent:event];
  [self.context.observer notifyLayout:NULL];
}


#pragma mark - Internal


- (UIScrollView *)findNestedScrollView:(NSArray<__kindof UIView *> *)subviews {
  NSArray<UIView *> *reverseSubview = [[subviews reverseObjectEnumerator] allObjects];

  // use BFS, to make sure that the top-most scrollview is the target one
  for (UIView *child in reverseSubview) {
    if ([self checkNestedScrollView:(UIScrollView *)child]) {
      return (UIScrollView *)child;
    }
  }
  
  for (UIView *child in reverseSubview) {
    UIScrollView *ret = [self findNestedScrollView:child.subviews];
    if (ret) {
      return ret;
    }
  }
  
  return nil;
}

- (BOOL)checkNestedScrollView:(UIScrollView *)scrollview {
  if (![scrollview isKindOfClass:UIScrollView.class]) {
    return NO;
  }
  // a vertical scrollview is needed
  if (scrollview.alwaysBounceHorizontal || scrollview.contentSize.width > scrollview.bounds.size.width) {
    return NO;
  }
  return YES;
}


- (UIView *)windowContainer {
  return UIApplication.sharedApplication.keyWindow;
}

- (UIViewController *)customViewController {
  if (![_customViewController isKindOfClass:self.customViewControllerClass]) {
    _customViewController = nil;
    UIResponder *responder = self.view;
    while (responder && ![responder isKindOfClass:self.customViewControllerClass]) {
      responder = responder.nextResponder;
    }
    _customViewController = (UIViewController *)responder;
  }
  return _customViewController;
}

- (void)dealloc {
  
  [[BDXLynxOverlayGlobalManager sharedInstance] destoryOverlayView:self.view atLevel:self.level withMode:self.mode customViewController:self.customViewController];
  
  // Overlay's view is attached to the global container, so, remove it manually when dealloc
  [self.view removeFromSuperview];
}

LYNX_PROPS_GROUP_DECLARE(
	LYNX_PROP_DECLARE("ios-not-adjust-top-margin", setIosNotAdjustTopMargin, BOOL),
	LYNX_PROP_DECLARE("ios-not-adjust-left-margin", setIosNotAdjustLeftMargin, BOOL))

/**
 * @name: ios-not-adjust-left-margin
 * @description: On iOS, if we are trying to open a new UIViewController with animation, the overlay's container may have a left offset in the UIWindow's coordinate. This property is designed to disable the left margin adjustment.
 * @category: different
 * @standardAction: offline
 * @supportVersion: 2.8
 * @resolveVersion: 3.0
**/
LYNX_PROP_DEFINE("ios-not-adjust-left-margin", setIosNotAdjustLeftMargin, BOOL) {
  self.notAdjustLeftMargin = value;
}

/**
 * @name: ios-not-adjust-top-margin
 * @description: On iOS, if we are trying to open a new UIViewController with animation, the overlay's container may have a top offset in the UIWindow's coordinate. This property is designed to disable the top margin adjustment.
 * @category: different
 * @standardAction: offline
 * @supportVersion: 2.10
 * @resolveVersion: 3.0
**/
LYNX_PROP_DEFINE("ios-not-adjust-top-margin", setIosNotAdjustTopMargin, BOOL) {
	self.notAdjustTopMargin = value;
}

@end
