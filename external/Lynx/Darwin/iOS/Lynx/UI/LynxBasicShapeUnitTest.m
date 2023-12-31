//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <XCTest/XCTest.h>
#import "LynxBasicShape.h"
#import "LynxCSSType.h"

@interface LynxBasicShapeUnitTest : XCTestCase

@end

@implementation LynxBasicShapeUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testCreateBasicShapeInset {
  NSNumber* type = [NSNumber numberWithInt:LynxBasicShapeTypeInset];
  NSArray* array = @[ type, @30, @1 ];
  LynxBasicShape* shape = LBSCreateBasicShapeFromArray(array);
  XCTAssertNil(shape);
  // rect
  array = @[ type, @30, @1, @30, @1, @30, @1, @30, @1 ];
  shape = LBSCreateBasicShapeFromArray(array);
  XCTAssertNotNil(shape);
  // rounded corner
  array = @[
    type, @30, @1,  @30, @1,  @30, @1,  @30, @1,  @30, @1,  @30, @1,
    @30,  @1,  @30, @1,  @30, @1,  @30, @1,  @30, @1,  @30, @1
  ];
  shape = LBSCreateBasicShapeFromArray(array);
  XCTAssertNotNil(shape);
  // super ellipse corner
  array = @[
    type, @30, @1, @30, @1, @30, @1, @30, @1, @3,  @3, @30, @1, @30,
    @1,   @30, @1, @30, @1, @30, @1, @30, @1, @30, @1, @30, @1
  ];
  shape = LBSCreateBasicShapeFromArray(array);
  XCTAssertNotNil(shape);
}

- (void)testPerformanceExample {
  // This is an example of a performance test case.
  [self measureBlock:^{
      // Put the code you want to measure the time of here.
  }];
}

@end
