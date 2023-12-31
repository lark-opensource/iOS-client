//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <XCTest/XCTest.h>
#import "BDXLynxOverlayGlobalManager.h"
#import "BDXLynxOverlayLight.h"
#import "LynxPropsProcessor.h"
#import "LynxUIView.h"
#import <Lynx/LynxUI.h>

@interface MockOverlayView : UIView

@property (nonatomic, strong) id uiDelegate;

@end

@implementation MockOverlayView

@end

@interface BDXLynxOverlayLight (Test)

@property (nonatomic, assign) BOOL visible;
@property (nonatomic, assign) BOOL eventPassThrough;
@property (nonatomic, assign) BOOL allowPanGesture;
@property (nonatomic, assign) BDXLynxOverlayLightMode mode;
@property (nonatomic, assign) NSInteger level;
@property (nonatomic, assign) BOOL notAdjustLeftMargin;
@property (nonatomic, assign) BOOL notAdjustTopMargin;

@end

@interface BDXLynxOverlayGlobalManager (Test)

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableDictionary<NSNumber *, UIView *> *> *levelContainers;

@end

@interface BDXLynxOverlayGlobalManagerUnitTest : XCTestCase

@end

@implementation BDXLynxOverlayGlobalManagerUnitTest

- (void)setUp {
  
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testShowAndDisplay {
  UIView *overlayView = [[MockOverlayView alloc] init];
  UIView *overlayController = [[UIView alloc] init];

  
  UIView *container = [BDXLynxOverlayGlobalManager.sharedInstance showOverlayView:overlayView atLevel:2 withMode:BDXLynxOverlayLightModeCustom customViewController:overlayController];
  
  XCTAssert(container == overlayController);
  
  UIView *levelContainer = overlayView.superview;
  
  XCTAssert(levelContainer.superview == overlayController);
  
  [BDXLynxOverlayGlobalManager getAllVisibleOverlay];
  
  XCTAssert([BDXLynxOverlayGlobalManager.sharedInstance.levelContainers count] == 1);

  [BDXLynxOverlayGlobalManager.sharedInstance destoryOverlayView:overlayView atLevel:2 withMode:BDXLynxOverlayLightModeCustom customViewController:overlayController];
  
  XCTAssert(overlayView.superview == nil);
  
  XCTAssert([BDXLynxOverlayGlobalManager.sharedInstance.levelContainers count] == 0);
  
  [overlayView removeFromSuperview];
  overlayView = nil;
  
  [BDXLynxOverlayGlobalManager getAllVisibleOverlay];
  
}

- (void)testOverlay {
  BDXLynxOverlayLight *overlay = [[BDXLynxOverlayLight alloc] initWithView:nil];
  [overlay insertChild:[[LynxUIView alloc] initWithView:nil] atIndex:0];
  [LynxPropsProcessor updateProp:@(YES) withKey:@"visiblity" forUI:overlay];
  [overlay propsDidUpdate];
  [overlay updateFrame:UIScreen.mainScreen.bounds withPadding:UIEdgeInsetsZero border:UIEdgeInsetsZero withLayoutAnimation:NO];
  [overlay onNodeReady];
}

- (void)testOverlayProps {
  BDXLynxOverlayLight *overlay = [[BDXLynxOverlayLight alloc] init];
  XCTAssert(overlay.notAdjustTopMargin);
  XCTAssert(overlay.notAdjustLeftMargin);
  XCTAssert(!overlay.visible);
  XCTAssert(overlay.eventPassThrough);
  XCTAssert(overlay.level == 1);
  XCTAssert(!overlay.allowPanGesture);
  XCTAssert(overlay.mode == 0);

  
  [LynxPropsProcessor updateProp:@(NO) withKey:@"ios-not-adjust-left-margin" forUI:overlay];
  [LynxPropsProcessor updateProp:@(NO) withKey:@"ios-not-adjust-top-margin" forUI:overlay];
  [LynxPropsProcessor updateProp:@(YES) withKey:@"visible" forUI:overlay];
  [LynxPropsProcessor updateProp:@(NO) withKey:@"events-pass-through" forUI:overlay];
  [LynxPropsProcessor updateProp:@(2) withKey:@"level" forUI:overlay];
  [LynxPropsProcessor updateProp:@(YES) withKey:@"allow-pan-gesture" forUI:overlay];
  [LynxPropsProcessor updateProp:@"top" withKey:@"mode" forUI:overlay];

  XCTAssert(!overlay.notAdjustTopMargin);
  XCTAssert(!overlay.notAdjustLeftMargin);
  XCTAssert(overlay.visible);
  XCTAssert(!overlay.eventPassThrough);
  XCTAssert(overlay.level != 1);
  XCTAssert(overlay.allowPanGesture);
  XCTAssert(overlay.mode != 0);
}



@end
