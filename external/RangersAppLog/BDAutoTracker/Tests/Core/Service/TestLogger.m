//
//  TestLogger.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/12.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <RangersAppLog/BDAutoTrackService.h>
#import <RangersAppLog/BDAutoTrackServiceCenter.h>

@interface TestLogger : XCTestCase

@end

@implementation TestLogger

- (void)setUp {
    [[BDAutoTrackServiceCenter defaultCenter] unregisterAllServices];
}

- (void)testExample {

}

@end
