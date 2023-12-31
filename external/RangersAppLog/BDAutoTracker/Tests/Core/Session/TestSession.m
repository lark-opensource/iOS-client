//
//  TestSession.m
//  BDAutoTracker_Tests
//
//  Created by 陈奕 on 2019/8/9.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import <RangersAppLog/BDAutoTrack.h>
#import <RangersAppLog/BDAutoTrack+Private.h>
#import <RangersAppLog/BDAutoTrackSessionHandler.h>
#import <RangersAppLog/BDTrackerCoreConstants.h>

@interface TestSession : XCTestCase

@property (nonatomic, strong) id track;

@end

@implementation TestSession

- (void)setUp {
    self.track = OCMClassMock([BDAutoTrack class]);
}

- (void)tearDown {
    [self.track stopMocking];
}

- (void)teststartSession {
    OCMExpect([self.track trackLaunchEventWithData:[OCMArg any]]);
    OCMExpect([self.track trackTerminateEventWithData:[OCMArg any]]);
    [[BDAutoTrackSessionHandler sharedHandler] startSessionWithIDChange:YES];
    OCMVerifyAll(self.track);
    XCTAssertNotNil([BDAutoTrackSessionHandler sharedHandler].sessionID);
    XCTAssertGreaterThan([BDAutoTrackSessionHandler sharedHandler].sessionID.length, 0);

    XCTAssertEqual([BDAutoTrackSessionHandler sharedHandler].previousLaunchs.count, [BDAutoTrackSessionHandler sharedHandler].previousTerminates.count);
}

- (void)testBackground {
    [[BDAutoTrackSessionHandler sharedHandler] startSessionWithIDChange:YES];
    NSString *old = [BDAutoTrackSessionHandler sharedHandler].sessionID;
    XCTAssertNotNil(old);
    XCTAssertGreaterThan(old.length, 0);
    XCTAssertEqual([BDAutoTrackSessionHandler sharedHandler].previousLaunchs.count, [BDAutoTrackSessionHandler sharedHandler].previousTerminates.count);
    
    OCMExpect([self.track trackTerminateEventWithData:[OCMArg any]]);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    OCMVerifyAll(self.track);
    NSString *nID = [BDAutoTrackSessionHandler sharedHandler].sessionID;
    XCTAssertNotNil(nID);
    XCTAssertGreaterThan(nID.length, 0);
    XCTAssertNotEqualObjects(old, nID);
    XCTAssertEqual([BDAutoTrackSessionHandler sharedHandler].previousLaunchs.count, [BDAutoTrackSessionHandler sharedHandler].previousTerminates.count);
}

- (void)testForeground {
    [[BDAutoTrackSessionHandler sharedHandler] startSessionWithIDChange:YES];
    NSString *oldSessionID = [BDAutoTrackSessionHandler sharedHandler].sessionID;
    XCTAssertNotNil(oldSessionID);
    XCTAssertGreaterThan(oldSessionID.length, 0);
    XCTAssertEqual([BDAutoTrackSessionHandler sharedHandler].previousLaunchs.count, [BDAutoTrackSessionHandler sharedHandler].previousTerminates.count);

    OCMExpect([self.track trackLaunchEventWithData:[OCMArg any]]);
    OCMExpect([self.track trackTerminateEventWithData:[OCMArg any]]);

    /// 需要先切后台
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
    NSString *nSessionID = [BDAutoTrackSessionHandler sharedHandler].sessionID;
    XCTAssertNotNil(nSessionID);
    XCTAssertGreaterThan(nSessionID.length, 0);
    XCTAssertNotEqualObjects(nSessionID, oldSessionID);
    OCMVerifyAll(self.track);
    XCTAssertEqual([BDAutoTrackSessionHandler sharedHandler].previousLaunchs.count, [BDAutoTrackSessionHandler sharedHandler].previousTerminates.count);
}

- (void)testBecomeActive {
    [[BDAutoTrackSessionHandler sharedHandler] startSessionWithIDChange:YES];
    OCMExpect([self.track trackUIEventWithData:[OCMArg any]]);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    OCMVerifyAll(self.track);
}

- (void)testTerminate {
    [[BDAutoTrackSessionHandler sharedHandler] startSessionWithIDChange:YES];
    NSString *old = [BDAutoTrackSessionHandler sharedHandler].sessionID;
    XCTAssertNotNil(old);
    XCTAssertGreaterThan(old.length, 0);
    XCTAssertEqual([BDAutoTrackSessionHandler sharedHandler].previousLaunchs.count, [BDAutoTrackSessionHandler sharedHandler].previousTerminates.count);
    
    /// 需要先切前台
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
    
    OCMExpect([self.track trackTerminateEventWithData:[OCMArg any]]);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillTerminateNotification object:nil];
    OCMVerifyAll(self.track);

    NSString *nID = [BDAutoTrackSessionHandler sharedHandler].sessionID;
    XCTAssertNotNil(nID);
    XCTAssertGreaterThan(nID.length, 0);
    XCTAssertNotEqualObjects(old, nID);
    XCTAssertEqual([BDAutoTrackSessionHandler sharedHandler].previousLaunchs.count, [BDAutoTrackSessionHandler sharedHandler].previousTerminates.count);
}

- (void)testResignActive {
    [[BDAutoTrackSessionHandler sharedHandler] startSessionWithIDChange:YES];
    OCMReject([self.track trackUIEventWithData:[OCMArg any]]);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:nil];
    OCMVerifyAll(self.track);
}

- (void)testWithoutResignActive {
    [[BDAutoTrackSessionHandler sharedHandler] startSessionWithIDChange:YES];
    OCMReject([self.track trackUIEventWithData:[OCMArg any]]);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    OCMVerifyAll(self.track);
}

@end
