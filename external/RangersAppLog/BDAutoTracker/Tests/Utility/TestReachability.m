//
//  TestReachability.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/8.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackNetworkConnection.h>
#import <RangersAppLog/BDAutoTrackReachability.h>
#import <RangersAppLog/BDAutoTrackDeviceHelper.h>

@interface TestReachability : XCTestCase

@property (nonatomic, strong) BDAutoTrackReachability *reachability;

@end

@implementation TestReachability

- (void)setUp {
    self.reachability = [BDAutoTrackReachability defaultReachability];
    [BDAutoTrackNetworkConnection sharedInstance];
}

- (void)testNetworkConnected {
    XCTAssertTrue([BDAutoTrackReachability isNetworkConnected]);
}

- (void)testSimulator {
    NSString *decivceModel = bd_device_decivceModel();
    if ([decivceModel containsString:@"Simulator"]) {
        XCTAssertNil([BDAutoTrackReachability carrierName]);
        XCTAssertNil([BDAutoTrackReachability carrierMCC]);
        XCTAssertNil([BDAutoTrackReachability carrierMNC]);
    }
}

- (void)testConnection {
    XCTAssertNotNil([BDAutoTrackNetworkConnection sharedInstance].connectMethodName);
    XCTAssertNotEqual([BDAutoTrackNetworkConnection sharedInstance].connection, BDAutoTrackNetworkNone);
}

@end
