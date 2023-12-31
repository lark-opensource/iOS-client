//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <XCTest/XCTest.h>
#import "BDXLynxViewPagerLight.h"
#import "BDXLynxViewPagerItemLight.h"
#import <Lynx/LynxUI.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/LynxUI+Internal.h>
#import "LynxPropsProcessor.h"

@interface LynxUIContext (ViewPagerUnitTest)
@property(nonatomic) LynxEventEmitter* eventEmitter;
@end

typedef void (^onSendEvent)(NSString *name, NSDictionary *event);

@interface LynxEventEmitterViewPagerUnitTest : LynxEventEmitter
@property (nonatomic, copy) onSendEvent callback;
@end

@implementation LynxEventEmitterViewPagerUnitTest
- (void)sendCustomEvent:(LynxCustomEvent *)event {
  [super sendCustomEvent:event];
  if (self.callback) {
    self.callback(event.eventName, event.params);
  }
}
@end



@interface BDXLynxViewPagerLight (Test)
- (void)selectTab:(NSDictionary *)params withResult:(LynxUIMethodCallbackBlock)callback;
@property (nonatomic, assign) NSUInteger emitTargetChangesOnlyDuringScroll;
@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, assign) CGFloat pagerChangeEpsilon;

@end

@interface BDXLynxViewPagerLightUnitTest : XCTestCase
@property (nonatomic, strong) BDXLynxViewPagerLight *viewPagerLite;
@end

@implementation BDXLynxViewPagerLightUnitTest

- (void)setUp {
  self.viewPagerLite = [[BDXLynxViewPagerLight alloc] init];
  BDXLynxViewPagerItemLight *item1 = [[BDXLynxViewPagerItemLight alloc] init];
  [self.viewPagerLite insertChild:item1 atIndex:0];
  BDXLynxViewPagerItemLight *item2 = [[BDXLynxViewPagerItemLight alloc] init];
  [self.viewPagerLite insertChild:item2 atIndex:1];
  BDXLynxViewPagerItemLight *item3 = [[BDXLynxViewPagerItemLight alloc] init];
  [self.viewPagerLite insertChild:item3 atIndex:2];
  [item1 updateFrame:UIScreen.mainScreen.bounds
         withPadding:UIEdgeInsetsZero
              border:UIEdgeInsetsZero
 withLayoutAnimation:NO];
  [item2 updateFrame:UIScreen.mainScreen.bounds
         withPadding:UIEdgeInsetsZero
              border:UIEdgeInsetsZero
 withLayoutAnimation:NO];
  [item3 updateFrame:UIScreen.mainScreen.bounds
         withPadding:UIEdgeInsetsZero
              border:UIEdgeInsetsZero
 withLayoutAnimation:NO];
  [self.viewPagerLite updateFrame:UIScreen.mainScreen.bounds
                      withPadding:UIEdgeInsetsZero
                           border:UIEdgeInsetsZero
              withLayoutAnimation:NO];
  [self.viewPagerLite propsDidUpdate];
  [self.viewPagerLite layoutDidFinished];
  [self.viewPagerLite finishLayoutOperation];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testEPSILON {
  XCTAssertNotNil(self.viewPagerLite.view);
  
  XCTAssert(self.viewPagerLite.pagerChangeEpsilon == 1.0/UIScreen.mainScreen.scale);
  
  [LynxPropsProcessor updateProp:@(0.1f) withKey:@"ios-pager-change-epsilon" forUI:self.viewPagerLite];

  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  UICollectionView *liteView = [self.viewPagerLite performSelector:@selector(viewpager)];
#pragma clang diagnostic pop
  XCTAssert(liteView.contentOffset.x == 0);
  XCTestExpectation *expectation =
       [self expectationWithDescription:@"Testing select tab works correctly"];
  [self.viewPagerLite selectTab:@{
    @"index" : @(2),
    @"smooth" : @(YES),
  } withResult:^(int code, id  _Nullable data) {
    XCTAssert(liteView.contentOffset.x == 2 * UIScreen.mainScreen.bounds.size.width);
    XCTAssert(self.viewPagerLite.emitTargetChangesOnlyDuringScroll == -1);
      XCTAssert(self.viewPagerLite.currentIndex == 2);
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.viewPagerLite selectTab:@{
        @"index" : @(0),
        @"smooth" : @(NO),
      } withResult:^(int code, id  _Nullable data) {
        XCTAssert(self.viewPagerLite.emitTargetChangesOnlyDuringScroll == -1);
        [expectation fulfill];
      }];
      XCTAssert(self.viewPagerLite.emitTargetChangesOnlyDuringScroll == -1);
    });
  }];
  XCTAssertNotNil(self.viewPagerLite.view);

  [self waitForExpectationsWithTimeout:3
                                handler:^(NSError *_Nullable error) {
                                  XCTAssert(liteView.contentOffset.x == 0);
      XCTAssert(self.viewPagerLite.currentIndex == 0);
                                }];
}

- (void)testSelectTab {
  XCTAssertNotNil(self.viewPagerLite.view);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  UICollectionView *liteView = [self.viewPagerLite performSelector:@selector(viewpager)];
#pragma clang diagnostic pop
  XCTAssert(liteView.contentOffset.x == 0);
  XCTestExpectation *expectation =
       [self expectationWithDescription:@"Testing select tab works correctly"];
  [self.viewPagerLite selectTab:@{
    @"index" : @(2),
    @"smooth" : @(YES),
  } withResult:^(int code, id  _Nullable data) {
    XCTAssert(liteView.contentOffset.x == 2 * UIScreen.mainScreen.bounds.size.width);
    XCTAssert(self.viewPagerLite.emitTargetChangesOnlyDuringScroll == -1);
      XCTAssert(self.viewPagerLite.currentIndex == 2);
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.viewPagerLite selectTab:@{
        @"index" : @(0),
        @"smooth" : @(NO),
      } withResult:^(int code, id  _Nullable data) {
        XCTAssert(self.viewPagerLite.emitTargetChangesOnlyDuringScroll == -1);
        [expectation fulfill];
      }];
      XCTAssert(self.viewPagerLite.emitTargetChangesOnlyDuringScroll == -1);
    });
  }];
  XCTAssertNotNil(self.viewPagerLite.view);

  [self waitForExpectationsWithTimeout:3
                                handler:^(NSError *_Nullable error) {
                                  XCTAssert(liteView.contentOffset.x == 0);
      XCTAssert(self.viewPagerLite.currentIndex == 0);
                                }];
}



- (void)testSelectTabRtl {
  BDXLynxViewPagerLight *viewPagerLite = [[BDXLynxViewPagerLight alloc] init];
  BDXLynxViewPagerItemLight *item1 = [[BDXLynxViewPagerItemLight alloc] init];
  [viewPagerLite insertChild:item1 atIndex:0];
  BDXLynxViewPagerItemLight *item2 = [[BDXLynxViewPagerItemLight alloc] init];
  [viewPagerLite insertChild:item2 atIndex:1];
  BDXLynxViewPagerItemLight *item3 = [[BDXLynxViewPagerItemLight alloc] init];
  [viewPagerLite insertChild:item3 atIndex:2];
  [item1 updateFrame:UIScreen.mainScreen.bounds
         withPadding:UIEdgeInsetsZero
              border:UIEdgeInsetsZero
 withLayoutAnimation:NO];
  [item2 updateFrame:UIScreen.mainScreen.bounds
         withPadding:UIEdgeInsetsZero
              border:UIEdgeInsetsZero
 withLayoutAnimation:NO];
  [item3 updateFrame:UIScreen.mainScreen.bounds
         withPadding:UIEdgeInsetsZero
              border:UIEdgeInsetsZero
 withLayoutAnimation:NO];
  viewPagerLite.directionType = LynxDirectionRtl;

  [viewPagerLite updateFrame:UIScreen.mainScreen.bounds
                      withPadding:UIEdgeInsetsZero
                           border:UIEdgeInsetsZero
              withLayoutAnimation:NO];
  
  [viewPagerLite propsDidUpdate];
  [viewPagerLite layoutDidFinished];
  [viewPagerLite finishLayoutOperation];
  
  
  XCTAssertNotNil(viewPagerLite.view);
  UICollectionView *liteView = [viewPagerLite performSelector:@selector(viewpager)];
  XCTAssert(liteView.contentOffset.x == 2 * UIScreen.mainScreen.bounds.size.width);
  XCTestExpectation *expectation =
       [self expectationWithDescription:@"Testing select tab works correctly"];
  [viewPagerLite selectTab:@{
    @"index" : @(2),
    @"smooth" : @(YES),
  } withResult:^(int code, id  _Nullable data) {
    XCTAssert(liteView.contentOffset.x == 0);
    XCTAssert(viewPagerLite.emitTargetChangesOnlyDuringScroll == -1);
      XCTAssert(viewPagerLite.currentIndex == 0);
    dispatch_async(dispatch_get_main_queue(), ^{
      [viewPagerLite selectTab:@{
        @"index" : @(0),
        @"smooth" : @(NO),
      } withResult:^(int code, id  _Nullable data) {
        XCTAssert(viewPagerLite.emitTargetChangesOnlyDuringScroll == -1);
        XCTAssert(liteView.contentOffset.x == 2 * UIScreen.mainScreen.bounds.size.width);
        [expectation fulfill];
      }];
      XCTAssert(viewPagerLite.emitTargetChangesOnlyDuringScroll == -1);
    });
  }];
  XCTAssertNotNil(viewPagerLite.view);

  [self waitForExpectationsWithTimeout:3
                                handler:^(NSError *_Nullable error) {
                                  XCTAssert(liteView.contentOffset.x == 2 * UIScreen.mainScreen.bounds.size.width);
      XCTAssert(viewPagerLite.currentIndex == 2);
                                }];
}


- (void)testRTL {
  
  BDXLynxViewPagerLight *viewPagerLite = [[BDXLynxViewPagerLight alloc] init];
  BDXLynxViewPagerItemLight *item1 = [[BDXLynxViewPagerItemLight alloc] init];
  [viewPagerLite insertChild:item1 atIndex:0];
  BDXLynxViewPagerItemLight *item2 = [[BDXLynxViewPagerItemLight alloc] init];
  [viewPagerLite insertChild:item2 atIndex:1];
  BDXLynxViewPagerItemLight *item3 = [[BDXLynxViewPagerItemLight alloc] init];
  [viewPagerLite insertChild:item3 atIndex:2];
  [item1 updateFrame:UIScreen.mainScreen.bounds
         withPadding:UIEdgeInsetsZero
              border:UIEdgeInsetsZero
 withLayoutAnimation:NO];
  [item2 updateFrame:UIScreen.mainScreen.bounds
         withPadding:UIEdgeInsetsZero
              border:UIEdgeInsetsZero
 withLayoutAnimation:NO];
  [item3 updateFrame:UIScreen.mainScreen.bounds
         withPadding:UIEdgeInsetsZero
              border:UIEdgeInsetsZero
 withLayoutAnimation:NO];
  viewPagerLite.directionType = LynxDirectionRtl;

  [viewPagerLite updateFrame:UIScreen.mainScreen.bounds
                      withPadding:UIEdgeInsetsZero
                           border:UIEdgeInsetsZero
              withLayoutAnimation:NO];
  
  [viewPagerLite propsDidUpdate];
  [viewPagerLite layoutDidFinished];
  [viewPagerLite finishLayoutOperation];
  
  LynxUIContext *uiContext = [[LynxUIContext alloc] init];
  LynxEventEmitterViewPagerUnitTest *emitter = [[LynxEventEmitterViewPagerUnitTest alloc] init];
  uiContext.eventEmitter = emitter;
  viewPagerLite.context = uiContext;
  __block NSInteger index = 0;
  __block CGFloat offset = 0.0;
  emitter.callback = ^(NSString *name, NSDictionary *event) {
    if ([name isEqualToString:@"change"]) {
      NSInteger curIndex = [event[@"index"] integerValue];
      XCTAssert(curIndex >= index);
      index = curIndex;
    } else if ([name isEqualToString:@"offsetchange"]) {
      CGFloat curOffset = [event[@"offset"] floatValue];
      XCTAssert(curOffset >= offset);
      offset = curOffset;
    }
  };
  [viewPagerLite propsDidUpdate];
  [viewPagerLite layoutDidFinished];
  [viewPagerLite finishLayoutOperation];
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  UICollectionView *liteView = [viewPagerLite performSelector:@selector(viewpager)];
#pragma clang diagnostic pop
  XCTAssert(liteView.contentOffset.x == 2 * UIScreen.mainScreen.bounds.size.width);
  
  XCTAssertNotNil(viewPagerLite.view);
  
  while (liteView.contentOffset.x >= 0) {
    CGFloat current = liteView.contentOffset.x;
    current -= 10.0 / 3.0;
    [liteView setContentOffset:CGPointMake(current, 0)];
  }
  
}

@end
