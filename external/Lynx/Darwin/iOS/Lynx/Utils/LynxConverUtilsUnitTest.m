//  Copyright © 2022 Lynx. All rights reserved.

#import <XCTest/XCTest.h>
#import "LynxConvertUtils.h"

@interface LynxConverUtilsUnitTest : XCTestCase

@end

@implementation LynxConverUtilsUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testConvertToJsonData {
  NSDictionary *dictionary = @{
    @"helloString" : @"Hello, World!",
    @"magicNumber" : @42,
    @"bool" : @(YES),
  };
  XCTAssertEqualObjects([LynxConvertUtils convertToJsonData:dictionary],
                        @"{\"bool\":true,\"helloString\":\"Hello, World!\",\"magicNumber\":42}");
}

@end
