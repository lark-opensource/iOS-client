
//  Copyright © 2022 Lynx. All rights reserved.

#import <XCTest/XCTest.h>
#import "LynxVersionUtils.h"

@interface LynxVersionUtilsUnitTest : XCTestCase

@end

@implementation LynxVersionUtilsUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testConvertNSStringToUIColor {
  XCTAssertEqual([LynxVersionUtils compareLeft:@"1.0.1" withRight:@"2.1.1"], -1);
  XCTAssertEqual([LynxVersionUtils compareLeft:@"1.0.1" withRight:@"0.1.1"], 1);
  XCTAssertEqual([LynxVersionUtils compareLeft:@"1.0.1" withRight:@"0.11.1"], 1);
  XCTAssertEqual([LynxVersionUtils compareLeft:@"1.0" withRight:@"1.0.0"], 0);
  XCTAssertEqual([LynxVersionUtils compareLeft:@"1.0.0" withRight:@"1.0.0"], 0);
}

@end
