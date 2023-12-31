#import <XCTest/XCTest.h>
#import "UIScrollView+Lynx.h"

@interface UIScrollView_LynxUnitTest : XCTestCase

@end

@implementation UIScrollView_LynxUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
  sleep(0.8);
}

- (void)testScrollToTargetContentOffsetForbid {
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
  [scrollView setContentSize:CGSizeMake(300 * 3, 100)];
  [scrollView scrollToTargetContentOffset:CGPointMake(200, 0)
                                 behavior:LynxScrollViewTouchBehaviorForbid
                                 duration:0.3
                                 interval:0
                                 complete:^BOOL(BOOL scrollEnabledAtStart) {
                                   XCTAssert(scrollView.contentOffset.x == 200);
                                   return scrollEnabledAtStart;
                                 }];
  XCTAssert(!scrollView.scrollEnabled);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Testing scroll ends"];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  [self waitForExpectations:@[ expectation ] timeout:3];
  XCTAssert(scrollView.scrollEnabled);
}

- (void)testScrollToTargetContentOffsetStop {
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
  [scrollView setContentSize:CGSizeMake(300 * 3, 100)];
  [scrollView scrollToTargetContentOffset:CGPointMake(200, 0)
                                 behavior:LynxScrollViewTouchBehaviorStop
                                 duration:0.3
                                 interval:0
                                 complete:^BOOL(BOOL scrollEnabledAtStart) {
                                   XCTAssert(scrollView.contentOffset.x == 200);
                                   return scrollEnabledAtStart;
                                 }];
  XCTAssert(scrollView.scrollEnabled);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Testing scroll ends"];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  [self waitForExpectations:@[ expectation ] timeout:3];
  XCTAssert(scrollView.scrollEnabled);
}

- (void)testSetContentOffsetForbid {
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
  [scrollView setContentSize:CGSizeMake(300 * 3, 100)];
  [scrollView setContentOffset:CGPointMake(200, 0)
      behavior:LynxScrollViewTouchBehaviorForbid
      duration:0.3
      interval:0
      progress:^CGPoint(double timeProgress, double distProgress, CGPoint contentOffset) {
        return contentOffset;
      }
      complete:^BOOL(BOOL scrollEnabledAtStart) {
        XCTAssert(scrollView.contentOffset.x == 200);
        return scrollEnabledAtStart;
      }];
  XCTAssert(!scrollView.scrollEnabled);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Testing scroll ends"];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  [self waitForExpectations:@[ expectation ] timeout:3];
  XCTAssert(scrollView.scrollEnabled);
}

- (void)testSetContentOffsetStop {
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
  [scrollView setContentSize:CGSizeMake(300 * 3, 100)];
  [scrollView setContentOffset:CGPointMake(200, 0)
      behavior:LynxScrollViewTouchBehaviorStop
      duration:0.3
      interval:0
      progress:^CGPoint(double timeProgress, double distProgress, CGPoint contentOffset) {
        return contentOffset;
      }
      complete:^BOOL(BOOL scrollEnabledAtStart) {
        XCTAssert(scrollView.contentOffset.x == 200);
        return scrollEnabledAtStart;
      }];
  XCTAssert(scrollView.scrollEnabled);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Testing scroll ends"];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  [self waitForExpectations:@[ expectation ] timeout:3];
  XCTAssert(scrollView.scrollEnabled);
}

@end
