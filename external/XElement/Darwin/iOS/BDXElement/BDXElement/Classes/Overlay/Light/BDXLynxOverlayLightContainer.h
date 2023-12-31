//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>
#import <Lynx/LynxEventHandler.h>
#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDXLynxOverlayLightMode) {
  BDXLynxOverlayLightModeWindow = 0,        // Attach to Window
  BDXLynxOverlayLightModePage,      // Attach to NavigationController
  BDXLynxOverlayLightModeTopController, // Attach to TopController
  BDXLynxOverlayLightModeCustom, // Attach to custom ViewController
};

@protocol BDXLynxOverlayLightViewDelegate <NSObject>
- (BOOL)forbidPanGesture;
- (BOOL)eventPassed;
- (void)requestClose:(NSDictionary *)info;
- (void)overlayMoved:(CGPoint)point state:(UIGestureRecognizerState)state velocity:(CGPoint)velocity;
- (LynxUI*)overlayRootUI;
- (UIScrollView *)nestScrollView;
- (NSInteger)getSign;

@end


/**
 * BDXLynxOverlayLightContainer is the root view of Overlay.
 * It recognizes gestures, and sent touch events to Lepus.
 */
@interface BDXLynxOverlayLightContainer : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, strong) LynxEventHandler *eventHandler;
@property (nonatomic, weak) id<BDXLynxOverlayLightViewDelegate> uiDelegate;
@end

NS_ASSUME_NONNULL_END
