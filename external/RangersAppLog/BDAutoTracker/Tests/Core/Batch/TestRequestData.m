//
//  TestRequestData.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/10.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackBatchData.h>
#import <RangersAppLog/BDAutoTrackBatchService.h>
#import <RangersAppLog/BDTrackerCoreConstants.h>

@interface TestRequestData : XCTestCase

@end

@implementation TestRequestData

- (void)testBatchDataAutoTrackEnabled {
    BDAutoTrackBatchData *data = [BDAutoTrackBatchData new];
    data.autoTrackEnabled = YES;
    NSDictionary *testEvent1 = @{@"Test1":@"test1"};
    NSDictionary *testEvent2 = @{@"Test2":@"test2"};
    NSArray *events = @[testEvent1, testEvent2];
    data.sendingTrackData = @{BDAutoTrackTableUIEvent:events};

    [data filterData];
    XCTAssertNotNil(data.realSentData);
    NSArray *realEvents = [data.realSentData objectForKey:BDAutoTrackTableEventV3];
    XCTAssertEqualObjects(realEvents,events);
}

- (void)testBatchDataAutoTrackNotEnabled {
    BDAutoTrackBatchData *data = [BDAutoTrackBatchData new];
    data.autoTrackEnabled = NO;
    NSDictionary *testEvent1 = @{@"Test1":@"test1"};
    NSDictionary *testEvent2 = @{@"Test2":@"test2"};
    NSArray *events = @[testEvent1, testEvent2];
    data.sendingTrackData = @{BDAutoTrackTableUIEvent:events};
    [data filterData];
    XCTAssertNotNil(data.realSentData);
    XCTAssertEqual(data.realSentData.count, 0);
}

- (void)testBatchData {
    BDAutoTrackBatchData *data = [BDAutoTrackBatchData new];
    data.autoTrackEnabled = NO;
    NSDictionary *testEvent1 = @{@"Test1":@"test1"};
    NSDictionary *testEvent2 = @{@"Test2":@"test2"};
    NSArray *events = @[testEvent1, testEvent2];
    data.sendingTrackData = @{BDAutoTrackTableEventV3:events};
    [data filterData];
    XCTAssertNotNil(data.realSentData);
    XCTAssertEqual(data.realSentData.count, 1);
    NSArray *realEvents = data.realSentData.allValues.firstObject;
    XCTAssertNotNil(realEvents);
    XCTAssertEqualObjects(realEvents,events);
}

@end
