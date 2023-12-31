//
//  TestBatchSchedule.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/11.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackBatchSchedule.h>

@interface TestBatchSchedule : XCTestCase

@end

@implementation TestBatchSchedule

- (BDAutoTrackBatchSchedule *)createSchedule {
    BDAutoTrackBatchSchedule *schedule = [[BDAutoTrackBatchSchedule alloc] initWithAppID:@"0"];
    schedule.scheduleInterval = 0.1;
    schedule.scheduleIntervalMin = 0.1;

    return schedule;
}

- (void)testActionInSchedule {
    BDAutoTrackBatchSchedule *schedule = [self createSchedule];
    for (NSInteger index = 0; index < 10; index++) {
        XCTAssertTrue([schedule actionInSchedule]);
    }
    for (NSInteger index = 0; index < 10; index++) {
        XCTAssertFalse([schedule actionInSchedule]);
    }
    CFTimeInterval interval = schedule.scheduleInterval * 2;
    XCTestExpectation *expectation = [self expectationWithDescription:@"testActionInSchedule"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (NSInteger index = 0; index < 10; index++) {
            XCTAssertTrue([schedule actionInSchedule]);
        }
        for (NSInteger index = 0; index < 10; index++) {
            XCTAssertFalse([schedule actionInSchedule]);
        }
        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout:interval + 0.3];
}

- (void)testDescendOnce {
    /// 降级1次
    BDAutoTrackBatchSchedule *schedule = [self createSchedule];
    [schedule scheduleWithHTTPCode:500];
    XCTAssertTrue([schedule actionInSchedule]);
    XCTAssertFalse([schedule actionInSchedule]);
    XCTestExpectation *expectation = [self expectationWithDescription:@"testDescendCount"];
    CFTimeInterval interval = schedule.scheduleInterval;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue([schedule actionInSchedule]);
        XCTAssertFalse([schedule actionInSchedule]);
        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout:interval + 0.3];
}

- (void)testDescendInterval {
    BDAutoTrackBatchSchedule *schedule = [[BDAutoTrackBatchSchedule alloc] initWithAppID:@"0"];
    [schedule scheduleWithHTTPCode:500];
    XCTAssertTrue([schedule actionInSchedule]);
    XCTAssertFalse([schedule actionInSchedule]);

    schedule = [[BDAutoTrackBatchSchedule alloc] initWithAppID:@"0"];
    XCTAssertGreaterThan(schedule.scheduleInterval, schedule.scheduleIntervalMin);
}

- (void)testDescendMax {
    BDAutoTrackBatchSchedule *schedule = [[BDAutoTrackBatchSchedule alloc] initWithAppID:@"0"];
    [schedule scheduleWithHTTPCode:500];
    XCTAssertTrue([schedule actionInSchedule]);
    XCTAssertFalse([schedule actionInSchedule]);
    [schedule scheduleWithHTTPCode:500];
    [schedule scheduleWithHTTPCode:500];
    [schedule scheduleWithHTTPCode:500];
    XCTAssertEqualWithAccuracy(schedule.scheduleInterval, 16.0 * 60, 0.1);
    [schedule scheduleWithHTTPCode:500];
    XCTAssertEqualWithAccuracy(schedule.scheduleInterval, 16.0 * 60, 0.1);
}

- (void)testAscend {
    /// 已经是max了，升级无望
    BDAutoTrackBatchSchedule *schedule = [self createSchedule];
    [schedule scheduleWithHTTPCode:200];
    [schedule scheduleWithHTTPCode:200];
    [schedule scheduleWithHTTPCode:200];
    [schedule scheduleWithHTTPCode:200];
    [schedule scheduleWithHTTPCode:200];
    [schedule scheduleWithHTTPCode:200];
    for (NSInteger index = 0; index < 10; index++) {
        XCTAssertTrue([schedule actionInSchedule]);
    }
    for (NSInteger index = 0; index < 10; index++) {
        XCTAssertFalse([schedule actionInSchedule]);
    }
    CFTimeInterval interval = schedule.scheduleInterval;
    XCTestExpectation *expectation = [self expectationWithDescription:@"testDescendCount"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (NSInteger index = 0; index < 10; index++) {
            XCTAssertTrue([schedule actionInSchedule]);
        }
        for (NSInteger index = 0; index < 10; index++) {
            XCTAssertFalse([schedule actionInSchedule]);
        }
        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout:interval + 0.3];
}

- (void)testDAscend {
    BDAutoTrackBatchSchedule *schedule = [self createSchedule];
    [schedule scheduleWithHTTPCode:500];
    XCTAssertTrue([schedule actionInSchedule]);
    XCTAssertFalse([schedule actionInSchedule]);
    /// 需要5次成功
    [schedule scheduleWithHTTPCode:200];
    [schedule scheduleWithHTTPCode:200];
    XCTAssertFalse([schedule actionInSchedule]);
    [schedule scheduleWithHTTPCode:200];
    [schedule scheduleWithHTTPCode:200];


    CFTimeInterval interval = schedule.scheduleInterval;
    XCTestExpectation *expectation = [self expectationWithDescription:@"testDAscend"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        /// 两次成功 间隔恢复，但是只能发送一次
        [schedule scheduleWithHTTPCode:200];
        XCTAssertTrue([schedule actionInSchedule]);
        XCTAssertFalse([schedule actionInSchedule]);

        [expectation fulfill];
    });


    [self waitForExpectations:@[expectation] timeout:interval + 0.3];
}

@end
