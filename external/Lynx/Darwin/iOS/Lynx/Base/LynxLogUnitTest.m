//
//  LynxLogUnitTest.m
//  LynxExampleTests
//
//  Copyright © 2021 Lynx. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LynxLog.h"

@interface LynxLogUnitTest : XCTestCase

@end

@implementation LynxLogUnitTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testLynxLog {
  // This is an example of a functional test case.
  // Use XCTAssert and related functions to verify your tests produce the correct results.
  LLog(@"TODO(): LogInfo - add unittest in their own unittest file");
  LLogWarn(@"TODO(): LogWarn - add unittest in their own unittest file");
  LLogError(@"TODO(): LogError - add unittest in their own unittest file");
  LLogFatal(@"TODO(): LogFatal - add unittest in their own unittest file");
  LLogReport(@"TODO(): LogReport - add unittest in their own unittest file");
}

@end
