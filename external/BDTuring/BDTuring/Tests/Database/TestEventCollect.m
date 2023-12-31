//
//  TestEventCollect.m
//  BDTuring_Tests
//
//  Created by bob on 2020/4/9.
//  Copyright © 2020 Bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <fmdb/FMDB.h>
#import <BDTuring/BDTuringDatabaseTable.h>
#import <BDTuring/BDTuringUtility.h>
#import <BDTuring/NSObject+BDTuring.h>
#import <BDTuring/BDTuringEventService.h>
#import <BDTuring/BDAccountSealEvent.h>
#import <BDTuring/BDTuringConfig.h>

@interface TestEventCollect : XCTestCase

@end

@implementation TestEventCollect

- (void)testSealEvent {
    [[BDAccountSealEvent sharedInstance] fetchAndCleanEvents];
    [[BDAccountSealEvent sharedInstance] collectEvent:@"test" data:@{}];
    NSArray *events = [[BDAccountSealEvent sharedInstance] fetchAndCleanEvents];
    XCTAssertEqual(events.count, 1);
    events = [[BDAccountSealEvent sharedInstance] fetchAndCleanEvents];
    XCTAssertEqual(events.count, 0);
}

- (void)testSaveSealEvent {
    [[BDAccountSealEvent sharedInstance] fetchAndCleanEvents];
    [[BDAccountSealEvent sharedInstance] loadDataForConfig:[BDTuringConfig new]];
    [[BDAccountSealEvent sharedInstance] saveEventData:@[@"Test"]];
    [[BDAccountSealEvent sharedInstance] loadDataForConfig:[BDTuringConfig new]];
    XCTestExpectation *expect = [XCTestExpectation new];
    expect.expectedFulfillmentCount = 1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSArray *events = [[BDAccountSealEvent sharedInstance] fetchAndCleanEvents];
        XCTAssertEqual(events.count, 1);
        [expect fulfill];
    });
    
    
    [self waitForExpectations:@[expect] timeout:0.2];
}

@end
