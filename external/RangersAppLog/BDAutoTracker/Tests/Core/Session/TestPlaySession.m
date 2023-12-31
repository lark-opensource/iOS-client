//
//  TestPlaySession.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/11.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <RangersAppLog/BDAutoTrackPlaySessionHandler.h>
#import <RangersAppLog/BDAutoTrack+Private.h>
#import <RangersAppLog/BDAutoTrackTimer.h>

@interface BDAutoTrackPlaySessionHandler (Test)

- (NSUInteger)loadSessionNo;
- (void)playSessionEvent;

@end

@interface TestPlaySession : XCTestCase

@property (nonatomic, strong) BDAutoTrackPlaySessionHandler *playSession;
@property (nonatomic, strong) id track;

@end

@implementation TestPlaySession

- (void)setUp {
    self.playSession = [BDAutoTrackPlaySessionHandler new];
    self.playSession.playSessionInterval = 1;
    self.track = OCMClassMock([BDAutoTrack class]);
}

- (void)tearDown {
    [self.track stopMocking];
}

- (void)testSessionNo {
    NSUInteger no = [self.playSession loadSessionNo];
    XCTAssertGreaterThan(no, 0);
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSessionNo"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSUInteger next = [self.playSession loadSessionNo];
        XCTAssertEqual(no + 1, next);
        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout:0.3];
}

- (void)testPlaySession {
    OCMExpect([self.track trackPlaySessionEventWithData:[OCMArg any]]);
    [self.playSession startPlaySessionWithTime:@"test_time"];
    OCMVerifyAllWithDelay(self.track, 2);
}

- (void)testStopPlaySession {
    [self.playSession startPlaySessionWithTime:@"test"];
    OCMExpect([self.track trackPlaySessionEventWithData:[OCMArg any]]);
    [self.playSession stopPlaySession];
    OCMVerifyAllWithDelay(self.track, 2);
}

- (void)testStopAndPlaySession {
    [self.playSession stopPlaySession];
    OCMReject([self.track trackPlaySessionEventWithData:[OCMArg any]]);
    [self.playSession playSessionEvent];
    OCMVerifyAll(self.track);
}

- (void)testPlaySessions {
    id timer = OCMPartialMock([BDAutoTrackTimer sharedInstance]);
    OCMExpect([timer scheduledDispatchTimerWithName:[OCMArg any]
                                       timeInterval:self.playSession.playSessionInterval
                                              queue:dispatch_get_main_queue()
                                            repeats:YES
                                             action:[OCMArg any]]);
    [self.playSession startPlaySessionWithTime:@"test_time"];
    OCMVerifyAll(timer);
    [timer stopMocking];
}

@end
