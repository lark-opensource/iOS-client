//  Copyright © 2022 Lynx. All rights reserved.

#import <XCTest/XCTest.h>
#import "LynxPerformanceUtils.h"

@interface LynxPerformanceUtilsUnitTest : XCTestCase

@end

@implementation LynxPerformanceUtilsUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testMemoryStatus {
  NSDictionary* memoryStatus = [LynxPerformanceUtils memoryStatus];
  XCTAssertNotNil(memoryStatus[@"extra_memory_log"]);
  int memoryAvailableSize = [memoryStatus[@"memory_available_size"] intValue];
  XCTAssertNotEqual(memoryAvailableSize, 0);
  int memoryTotalSize = [memoryStatus[@"memory_total_size"] intValue];
  XCTAssertNotEqual(memoryTotalSize, 0);
}

@end
