//
//  HeimdallrDemoTests.m
//  HeimdallrDemoTests
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDDynamicCall.h"
#import "HMDSwizzle.h"

@interface HMDWatchdogProtectTrackerTest : XCTestCase

@end

@implementation HMDWatchdogProtectTrackerTest

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
