//
//  BDXLynxOverlayView.m
//  AWEABTest
//
//  Created by Lizhen Hu on 2020/4/28.
//

#import "BDXLynxOverlayView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxEventHandler.h>
#import <Lynx/LynxTouchHandler.h>
#import <Lynx/LynxRootUI.h>
#import <Lynx/LynxViewVisibleHelper.h>

@protocol BDXLynxOverlayContentViewDelegate <NSObject>

- (void)requestClose:(NSDictionary *)info;
- (LynxUI*)overlayRootUI;

@end

@interface BDXLynxOverlayContainerView : UIView
@end

@implementation BDXLynxOverlayContainerView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self) {
        // To free our touch handler from being blocked, dispatch endEditing asynchronously.
        __weak BDXLynxOverlayContainerView* weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf endEditing:true];
        });
    }
    return view == self ? nil : view;
}

@end

@interface BDXLynxOverlayContentView : UIView

@property (nonatomic, strong) LynxEventHandler *eventHandler;
@property (nonatomic, assign) BOOL eventsPassThrough;
@property (nonatomic, weak) id<BDXLynxOverlayContentViewDelegate> delegate;

@end

@implementation BDXLynxOverlayContentView

- (void)ensureEventHandler {
    if (self.eventHandler != nil) {
        return;
    }
    LynxUI* rootUI = self.delegate.overlayRootUI;
    self.eventHandler = [[LynxEventHandler alloc] initWithRootView:self withRootUI:rootUI];
    [self.eventHandler updateUiOwner:nil eventEmitter:rootUI.context.eventEmitter];
    
    UIScreenEdgePanGestureRecognizer *edgePanRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleEdgePanGesture:)];
    edgePanRecognizer.edges = UIRectEdgeLeft;
    [self addGestureRecognizer:edgePanRecognizer];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    [self ensureEventHandler];
    UIView *view = [super hitTest:point withEvent:event];
    if (self.eventsPassThrough && view == self) {
        return nil;
    } else {
        id<LynxEventTarget> touchTarget = [self.eventHandler hitTest:point withEvent:event];
        if (![view isKindOfClass:[UITextField class]] && ![view isKindOfClass:[UITextView class]] && ![touchTarget ignoreFocus]) {
            __weak BDXLynxOverlayContentView* weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf endEditing:true];
            });
        }
        // If target eventThrough, return nil to let event through LynxView.
        if ([touchTarget eventThrough]) {
            return nil;
        } else {
            return view;
        }
    }
}

- (void)handleEdgePanGesture:(UIScreenEdgePanGestureRecognizer *)recognizer {
    if(recognizer.state == UIGestureRecognizerStateRecognized) {
        if([self.delegate respondsToSelector:@selector(requestClose:)]) {
            [self.delegate requestClose:@{}];
        }
    }
}

@end


@interface BDXLynxOverlayView () <BDXLynxOverlayContentViewDelegate,LynxViewVisibleHelper>

@property (nonatomic, assign) BOOL statusBarTranslucent;
@property (nonatomic, assign) BOOL eventsPassThrough;
@property (nonatomic, strong) BDXLynxOverlayContainerView *containerView;
@property (nonatomic, strong) BDXLynxOverlayContentView *contentView;

@end

@implementation BDXLynxOverlayView {
    BOOL _visible;
    enum LynxEventPropStatus _eventThrough;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("overlay")
#else
LYNX_REGISTER_UI("overlay")
#endif

LYNX_PROPS_GROUP_DECLARE(LYNX_PROP_DECLARE("event-through", setEventThrough, BOOL))


LYNX_PROP_SETTER("visible", visible, BOOL)
{
    if (requestReset) {
        value = NO;
    }
    _visible = value;
    [self operateContainer:value];
}

LYNX_PROP_SETTER("status-bar-translucent", statusBarTranslucent, BOOL)
{
    self.statusBarTranslucent = value;
}

LYNX_PROP_SETTER("events-pass-through", eventsPassThrough, BOOL)
{
    self.eventsPassThrough = value;
}

LYNX_PROP_DEFINE("event-through", setEventThrough, BOOL) {
  // If requestReset, the _eventThrough will be kLynxEventPropDisable.
  if (requestReset) {
      _eventThrough = kLynxEventPropDisable;
      return;
  }
  _eventThrough = value ? kLynxEventPropEnable : kLynxEventPropDisable;
}

- (BOOL)eventThrough {
  // If _eventThrough == Enable, return true. Otherwise, return false.
  if (_eventThrough == kLynxEventPropEnable) {
      return true;
  }
  return false;
}

- (instancetype)initWithView:(UIView *)view
{
    self = [super initWithView:view];
    if (self) {
        self.statusBarTranslucent = YES;
        self.eventsPassThrough = YES;
        _visible = NO;
        _eventThrough = kLynxEventPropDisable;
    }
    return self;
}

- (void)dealloc
{
    [self operateContainer:NO];
}

- (UIView *)createView
{
    self.contentView.delegate = self;
    [self operateContainer:_visible];
    return self.contentView;
}

#pragma mark - BDXLynxOverlayContentViewDelegate
- (void)requestClose:(NSDictionary *)info {
    if (self.context != nil && self.context.rootUI != nil) {
        [self.context.rootUI.lynxView sendGlobalEvent:@"onRequestClose" withParams:@[]];
    }
}

- (LynxUI*)overlayRootUI {
    return self;
}

- (void)operateContainer:(BOOL)visible {
    if (self.contentView.superview != self.containerView) {
        [self.containerView addSubview:self.contentView];
    }
    if (visible) {
        UIWindow *keyWindow = UIApplication.sharedApplication.keyWindow;
        self.containerView.frame = keyWindow.bounds;
        if (self.containerView.superview != keyWindow) {
            [keyWindow addSubview:self.containerView];
        }
        if (UIAccessibilityIsVoiceOverRunning()) {
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.containerView);
        }
    } else {
        [self.containerView removeFromSuperview];
    }
    self.containerView.accessibilityViewIsModal = visible;
}

- (void)layoutDidFinished {
    [super layoutDidFinished];
    BDXLynxOverlayContentView *contentView = self.contentView;
    contentView.frame = ({
        CGRect frame = contentView.frame;
        frame.origin.y = self.statusBarTranslucent ? 0 : UIApplication.sharedApplication.statusBarFrame.size.height;
        frame;
    });
    [self operateContainer:_visible];
}

- (BOOL)shouldHitTest:(CGPoint)point withEvent:(nullable UIEvent*)event {
    return NO;
}

- (void)setEventsPassThrough:(BOOL)eventsPassThrough
{
    _eventsPassThrough = eventsPassThrough;
    self.contentView.eventsPassThrough = eventsPassThrough;
}

- (BDXLynxOverlayContainerView *)containerView
{
    if (!_containerView) {
        _containerView = [[BDXLynxOverlayContainerView alloc] initWithFrame:UIApplication.sharedApplication.keyWindow.bounds];
    }
    return _containerView;
}

- (BDXLynxOverlayContentView *)contentView
{
    if (!_contentView) {
        _contentView = [[BDXLynxOverlayContentView alloc] init];
    }
    return _contentView;
}

- (BOOL)IsViewVisible {
    return _visible;
}

@end
