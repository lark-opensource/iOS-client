
//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <XCTest/XCTest.h>
#import "BDXLynxSwiperCollectionView.h"
#import "BDXLynxSwiperCellLayout.h"
#import <Lynx/LynxUI.h>
#import <Lynx/LynxUIMethodProcessor.h>



@interface BDXLynxSwiperCollectionViewUnitTest : XCTestCase
@end

@implementation BDXLynxSwiperCollectionViewUnitTest

- (void)setUp {
  
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testScroll {
  BDXLynxSwiperTransformLayout *layout = [[BDXLynxSwiperTransformLayout alloc] init];
  BDXLynxSwiperCollectionView *collectionView = [[BDXLynxSwiperCollectionView alloc]initWithFrame:CGRectMake(0, 0, 300, 100) collectionViewLayout:layout];
  collectionView.touchBehavior = LynxScrollViewTouchBehaviorForbid;
  [collectionView setContentSize:CGSizeMake(300*3, 100)];
  collectionView.customDuration = 200;
  collectionView.scrollEnableFromLynx = NO;
  collectionView.scrollEnabled = NO;
  [collectionView setContentOffset:CGPointMake(100, 0) animated:YES];
  XCTAssert(!collectionView.scrollEnabled);
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Testing scroll ends"];
  collectionView.scrollEnableFromLynx = YES;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  [self waitForExpectations:@[ expectation ] timeout:3];
  XCTAssert(collectionView.scrollEnabled);
  XCTAssert(collectionView.contentOffset.x == 100);
}

- (void)testDecelerate {
  BDXLynxSwiperTransformLayout *layout = [[BDXLynxSwiperTransformLayout alloc] init];
  BDXLynxSwiperCollectionView *collectionView = [[BDXLynxSwiperCollectionView alloc]initWithFrame:CGRectMake(0, 0, 300, 100) collectionViewLayout:layout];
  collectionView.touchBehavior = LynxScrollViewTouchBehaviorForbid;
  [collectionView setContentSize:CGSizeMake(300*3, 100)];
  collectionView.customDuration = 200;
  collectionView.scrollEnableFromLynx = YES;
  collectionView.scrollEnabled = YES;
  [collectionView decelerateToContentOffset:CGPointMake(100, 0) duration:200];
  XCTAssert(!collectionView.scrollEnabled);
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Testing scroll ends"];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  [self waitForExpectations:@[ expectation ] timeout:3];
  XCTAssert(collectionView.scrollEnabled);
  XCTAssert(collectionView.contentOffset.x == 100);
}

- (void)testBehavior {
  BDXLynxSwiperTransformLayout *layout = [[BDXLynxSwiperTransformLayout alloc] init];
  BDXLynxSwiperCollectionView *collectionView = [[BDXLynxSwiperCollectionView alloc]initWithFrame:CGRectMake(0, 0, 300, 100) collectionViewLayout:layout];
  XCTAssert(collectionView.touchBehavior == LynxScrollViewTouchBehaviorNone);
  collectionView.touchBehavior = LynxScrollViewTouchBehaviorStop;
  XCTAssert(collectionView.touchBehavior == LynxScrollViewTouchBehaviorStop);
  collectionView.touchBehavior = LynxScrollViewTouchBehaviorStop;
  [collectionView setContentSize:CGSizeMake(300*3, 100)];
  collectionView.customDuration = 200;
  collectionView.scrollEnableFromLynx = NO;
  [collectionView setContentOffset:CGPointMake(100, 0) animated:YES];
  XCTAssert(collectionView.scrollEnabled);
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Testing scroll ends"];
  collectionView.scrollEnableFromLynx = YES;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  [self waitForExpectations:@[ expectation ] timeout:3];
  XCTAssert(collectionView.scrollEnabled);
  XCTAssert(collectionView.contentOffset.x == 100);
}

@end
