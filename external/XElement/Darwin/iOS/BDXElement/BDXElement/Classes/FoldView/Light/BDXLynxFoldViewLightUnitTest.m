//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <XCTest/XCTest.h>
#import "BDXLynxFoldViewLight.h"
#import "BDXLynxFoldViewHeaderLight.h"
#import "BDXLynxFoldViewToolBarLight.h"
#import "BDXLynxFoldViewSlotLight.h"
#import <Lynx/LynxUI.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/LynxUI+Internal.h>

@interface BDXLynxFoldViewLightUnitTest : XCTestCase

@end

@implementation BDXLynxFoldViewLightUnitTest


- (void)setUp {
  
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testAdjustContentOffset {
  BDXLynxFoldViewLight *foldview = [[BDXLynxFoldViewLight alloc] init];
  [foldview updateFrame:CGRectMake(0, 0, 200, 800) withPadding:UIEdgeInsetsZero border:UIEdgeInsetsZero withLayoutAnimation:NO];
  
  BDXLynxFoldViewHeaderLight *header = [[BDXLynxFoldViewHeaderLight alloc] init];
  [header updateFrame:CGRectMake(0, 0, 200, 200) withPadding:UIEdgeInsetsZero border:UIEdgeInsetsZero withLayoutAnimation:NO];
  
  BDXLynxFoldViewSlotLight *slot = [[BDXLynxFoldViewSlotLight alloc] init];
  [slot updateFrame:CGRectMake(0, 0, 200, 700) withPadding:UIEdgeInsetsZero border:UIEdgeInsetsZero withLayoutAnimation:NO];
  
  BDXLynxFoldViewToolBarLight *toolbar = [[BDXLynxFoldViewToolBarLight alloc] init];
  [toolbar updateFrame:CGRectMake(0, 0, 200, 100) withPadding:UIEdgeInsetsZero border:UIEdgeInsetsZero withLayoutAnimation:NO];

  [foldview insertChild:header atIndex:0];
  [foldview insertChild:slot atIndex:1];
  [foldview insertChild:toolbar atIndex:2];
  
  [foldview finishLayoutOperation];
  
  
  UIScrollView *scrollView = (UIScrollView *)foldview.view.subviews.firstObject;
  XCTAssert(scrollView.contentOffset.y == 0);

  [scrollView setContentOffset:CGPointMake(0, 300)];
  
  XCTAssert(scrollView.contentOffset.y == 100);
  
  [header updateFrame:CGRectMake(0, 0, 200, 150) withPadding:UIEdgeInsetsZero border:UIEdgeInsetsZero withLayoutAnimation:NO];


  [foldview finishLayoutOperation];
  
  XCTAssert(scrollView.contentOffset.y == 50);

}


@end
