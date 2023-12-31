//
//  FirstTests.m
//  FirstTests
//
//  Created by ZengHao on 09/12/2018.
//  Copyright (c) 2018 ZengHao. All rights reserved.
//

@import XCTest;

@interface FirstTests : XCTestCase

@end

@implementation FirstTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    XCTAssert(YES, @"Good for \"%s\"", __PRETTY_FUNCTION__);
}

@end

