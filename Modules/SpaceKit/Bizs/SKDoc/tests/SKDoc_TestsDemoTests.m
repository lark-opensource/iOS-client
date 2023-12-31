//
//  SKDoc_TestsDemoTests.m
//  SKDoc_TestsDemoTests
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface SKDoc_TestsDemoTests : XCTestCase

@end

@implementation SKDoc_TestsDemoTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDemo {
#if DEBUG
    NSLog(@"[apm] testDemo start");
    NSLog(@"[apm] testDemo end");
#endif
}

@end
