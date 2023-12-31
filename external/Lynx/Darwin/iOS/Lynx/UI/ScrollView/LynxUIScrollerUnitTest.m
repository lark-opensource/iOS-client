// Copyright 2023 The Lynx Authors. All rights reserved.

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "LynxBounceView.h"
#import "LynxPropsProcessor.h"
#import "LynxUI+Internal.h"
#import "LynxUIOwner.h"
#import "LynxUIScroller.h"
#import "LynxUIScrollerUnitTestUtils.h"
#import "LynxUIView.h"

@interface LynxUIScrollerUnitTest : XCTestCase
@end

@implementation LynxUIScrollerUnitTest

- (void)testScrollX {
  LynxUIMockContext *mockContext =
      [LynxUIUnitTestUtils initUIMockContextWithUI:[[LynxUIScroller alloc] init]];
  [mockContext.mockUI updateFrame:CGRectMake(0, 0, 428.0f, 100.0f)
                      withPadding:UIEdgeInsetsZero
                           border:UIEdgeInsetsZero
              withLayoutAnimation:NO];
  XCTAssertNotNil(mockContext.mockUI.view);
  [LynxPropsProcessor updateProp:@1 withKey:@"scroll-x" forUI:mockContext.mockUI];
  [mockContext.mockUI propsDidUpdate];
  [LynxUIScrollerUnitTestUtils mockChildren:10
                                    context:mockContext
                                    scrollY:NO
                                       size:CGSizeMake(100, 100)];
  UIScrollView *scrollView = (UIScrollView *)mockContext.mockUI.view;
  XCTAssertEqual(scrollView.contentSize.width, 1000.0f);
  XCTAssertEqual(scrollView.contentSize.height, 100.0f);
}

- (void)testScrollY {
  LynxUIMockContext *mockContext =
      [LynxUIUnitTestUtils initUIMockContextWithUI:[[LynxUIScroller alloc] init]];
  [mockContext.mockUI updateFrame:CGRectMake(0, 0, 428.0f, 100.0f)
                      withPadding:UIEdgeInsetsZero
                           border:UIEdgeInsetsZero
              withLayoutAnimation:NO];
  XCTAssertNotNil(mockContext.mockUI.view);
  [LynxPropsProcessor updateProp:@1 withKey:@"scroll-y" forUI:mockContext.mockUI];
  [mockContext.mockUI propsDidUpdate];
  [LynxUIScrollerUnitTestUtils mockChildren:10
                                    context:mockContext
                                    scrollY:YES
                                       size:CGSizeMake(100, 100)];
  UIScrollView *scrollView = (UIScrollView *)mockContext.mockUI.view;
  XCTAssertEqual(scrollView.contentSize.width, 428.0f);
  XCTAssertEqual(scrollView.contentSize.height, 1000.0f);
}

- (void)testDoubleSideBounceViewScrollX {
  LynxUIMockContext *mockContext =
      [LynxUIUnitTestUtils initUIMockContextWithUI:[[LynxUIScroller alloc] init]];
  [mockContext.mockUI updateFrame:CGRectMake(0, 0, 428.0f, 100.0f)
                      withPadding:UIEdgeInsetsZero
                           border:UIEdgeInsetsZero
              withLayoutAnimation:NO];
  XCTAssertNotNil((UIScrollView *)mockContext.mockUI.view);

  [LynxPropsProcessor updateProp:@1 withKey:@"scroll-x" forUI:mockContext.mockUI];
  [mockContext.mockUI propsDidUpdate];

  [self subTestDoubleSideBounceViewScrollX:mockContext];
}

- (void)testDoubleSideBounceViewScrollXRTL {
  LynxUIMockContext *mockContext =
      [LynxUIUnitTestUtils initUIMockContextWithUI:[[LynxUIScroller alloc] init]];
  [mockContext.mockUI updateFrame:CGRectMake(0, 0, 428.0f, 100.0f)
                      withPadding:UIEdgeInsetsZero
                           border:UIEdgeInsetsZero
              withLayoutAnimation:NO];
  XCTAssertNotNil((UIScrollView *)mockContext.mockUI.view);
  mockContext.mockUI.directionType = LynxDirectionRtl;

  [LynxPropsProcessor updateProp:@1 withKey:@"scroll-x" forUI:mockContext.mockUI];
  [mockContext.mockUI propsDidUpdate];

  [self subTestDoubleSideBounceViewScrollX:mockContext];
}

- (void)subTestDoubleSideBounceViewScrollX:(LynxUIMockContext *)mockContext {
  NSInteger childCount = 10;
  [LynxUIScrollerUnitTestUtils mockChildren:childCount
                                    context:mockContext
                                    scrollY:NO
                                       size:CGSizeMake(100.0f, 100.0f)];
  [LynxUIScrollerUnitTestUtils mockBounceView:mockContext
                                    direction:@"left"
                        triggerBounceDistance:0.0f
                                         size:CGSizeMake(100.0f, 100.0f)];
  [LynxUIScrollerUnitTestUtils mockBounceView:mockContext
                                    direction:@"right"
                        triggerBounceDistance:0.0f
                                         size:CGSizeMake(100.0f, 100.0f)];

  NSArray *bounceUIArray = ((LynxUIScroller *)mockContext.mockUI).bounceUIArray;
  for (NSInteger i = 0; i < (NSInteger)bounceUIArray.count; i++) {
    XCTAssertEqual([LynxBounceView class], [[bounceUIArray objectAtIndex:i] class]);
    LynxBounceView *bounceView = [bounceUIArray objectAtIndex:i];
    if (bounceView.direction == LynxBounceViewDirectionRight) {
      XCTAssertEqual(bounceView.view.frame.origin.x, 1000.0f);
    } else if (bounceView.direction == LynxBounceViewDirectionLeft) {
      XCTAssertEqual(bounceView.view.frame.origin.x, -100.0f);
    }
  }
}

- (void)testDoubleSideBounceViewScrollY {
  LynxUIMockContext *mockContext =
      [LynxUIUnitTestUtils initUIMockContextWithUI:[[LynxUIScroller alloc] init]];
  [mockContext.mockUI updateFrame:CGRectMake(0, 0, 428.0f, 100.0f)
                      withPadding:UIEdgeInsetsZero
                           border:UIEdgeInsetsZero
              withLayoutAnimation:NO];
  XCTAssertNotNil(mockContext.mockUI.view);
  NSInteger childCount = 10;
  [LynxPropsProcessor updateProp:@1 withKey:@"scroll-y" forUI:mockContext.mockUI];
  [mockContext.mockUI propsDidUpdate];

  [LynxUIScrollerUnitTestUtils mockChildren:childCount
                                    context:mockContext
                                    scrollY:YES
                                       size:CGSizeMake(100.0f, 100.0f)];
  [LynxUIScrollerUnitTestUtils mockBounceView:mockContext
                                    direction:@"top"
                        triggerBounceDistance:0.0f
                                         size:CGSizeMake(100.0f, 100.0f)];
  [LynxUIScrollerUnitTestUtils mockBounceView:mockContext
                                    direction:@"bottom"
                        triggerBounceDistance:0.0f
                                         size:CGSizeMake(100.0f, 100.0f)];

  NSArray *bounceUIArray = ((LynxUIScroller *)mockContext.mockUI).bounceUIArray;
  for (NSInteger i = 0; i < (NSInteger)bounceUIArray.count; i++) {
    XCTAssertEqual([LynxBounceView class], [[bounceUIArray objectAtIndex:i] class]);
    LynxBounceView *bounceView = [bounceUIArray objectAtIndex:i];
    if (bounceView.direction == LynxBounceViewDirectionTop) {
      XCTAssertEqual(bounceView.view.frame.origin.y, -100.0f);
    } else if (bounceView.direction == LynxBounceViewDirectionBottom) {
      XCTAssertEqual(bounceView.view.frame.origin.y, 1000.0f);
    }
  }
}

- (void)testScrollToBounces {
  // testcases:
  //@[
  //   direction,
  //   scrollToPosition,
  //   triggerBounceDistance,
  //   correct @"bounceDistance" result
  //]
  NSArray<NSArray *> *testCases = @[
    @[
      @"left", NSStringFromCGPoint(CGPointMake(-10, 0)), [NSNumber numberWithFloat:0.0f],
      [NSNumber numberWithFloat:-10.0f]
    ],
    @[
      @"right", NSStringFromCGPoint(CGPointMake(10 * 100.0f - 428.0 + 10, 0)),
      [NSNumber numberWithFloat:0.0f], [NSNumber numberWithFloat:10.0f]
    ],
    @[
      @"top", NSStringFromCGPoint(CGPointMake(0, -10.0)), [NSNumber numberWithFloat:0.0f],
      [NSNumber numberWithFloat:-10.0f]
    ],
    @[
      @"bottom", NSStringFromCGPoint(CGPointMake(0, 10 * 100.0f - 100.0f + 10)),
      [NSNumber numberWithFloat:0.0f], [NSNumber numberWithFloat:10.0f]
    ],
  ];

  for (NSInteger i = 0; i < (NSInteger)testCases.count; i++) {
    NSString *direction = [[testCases objectAtIndex:i] objectAtIndex:0];
    CGPoint position = CGPointFromString([[testCases objectAtIndex:i] objectAtIndex:1]);
    CGFloat distance = ((NSNumber *)[[testCases objectAtIndex:i] objectAtIndex:2]).floatValue;
    CGFloat correctDistance =
        ((NSNumber *)[[testCases objectAtIndex:i] objectAtIndex:3]).floatValue;

    [self scrollToBouncesSubTests:direction
                   scrollPosition:position
            triggerBounceDistance:distance
                  correctDistance:correctDistance];
  }
}

- (void)scrollToBouncesSubTests:(NSString *)direction
                 scrollPosition:(CGPoint)position
          triggerBounceDistance:(CGFloat)distance
                correctDistance:(CGFloat)correctDistance {
  NSInteger childCount = 10;
  LynxUIMockContext *mockContext =
      [LynxUIUnitTestUtils initUIMockContextWithUI:[[LynxUIScroller alloc] init]];
  [mockContext.mockUI updateFrame:CGRectMake(0, 0, 428.0f, 100.0f)
                      withPadding:UIEdgeInsetsZero
                           border:UIEdgeInsetsZero
              withLayoutAnimation:NO];
  XCTAssertNotNil(mockContext.mockUI.view);

  if ([direction isEqualToString:@"left"] || [direction isEqualToString:@"right"]) {
    [LynxPropsProcessor updateProp:@1 withKey:@"scroll-x" forUI:mockContext.mockUI];
    [mockContext.mockUI propsDidUpdate];
    [LynxUIScrollerUnitTestUtils mockChildren:childCount
                                      context:mockContext
                                      scrollY:NO
                                         size:CGSizeMake(100.0f, 100.0f)];
  } else {
    [LynxPropsProcessor updateProp:@1 withKey:@"scroll-y" forUI:mockContext.mockUI];
    [mockContext.mockUI propsDidUpdate];
    [LynxUIScrollerUnitTestUtils mockChildren:childCount
                                      context:mockContext
                                      scrollY:YES
                                         size:CGSizeMake(100.0f, 100.0f)];
  }

  [LynxUIScrollerUnitTestUtils mockBounceView:mockContext
                                    direction:direction
                        triggerBounceDistance:distance
                                         size:CGSizeMake(100.0f, 100.0f)];
  [mockContext.mockUI.view setContentOffset:position];

  XCTAssertNotNil(
      ((LynxEventEmitterUnitTestHelper *)mockContext.mockUI.context.eventEmitter).event);
  LynxCustomEvent *event =
      ((LynxEventEmitterUnitTestHelper *)mockContext.mockUI.context.eventEmitter).event;
  NSDictionary *detail = event.params;

  XCTAssert(
      [detail[@"bounceDistance"] isEqualToNumber:[NSNumber numberWithInteger:correctDistance]]);
  XCTAssert([detail[@"triggerDistance"] isEqualToNumber:[NSNumber numberWithInteger:distance]]);
  XCTAssert([detail[@"direction"] isEqualToString:direction]);
}
@end
