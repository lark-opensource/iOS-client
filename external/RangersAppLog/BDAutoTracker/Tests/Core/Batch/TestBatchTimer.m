//
//  TestBatchTimer.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/11.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <RangersAppLog/BDAutoTrackBatchTimer.h>
#import <RangersAppLog/BDTrackerCoreConstants.h>
#import <RangersAppLog/BDAutoTrackSwizzle.h>
#import <RangersAppLog/BDAutoTrackNotifications.h>
#import <RangersAppLog/BDAutoTrackService.h>

@interface BDAutoTrackBatchTimer (Test)
- (void)endBackgroundTask;
- (void)onDidBecomeActive;
@end

@interface TestBDAutoTrackBatchRequest : BDAutoTrackService
@property (nonatomic, strong)  XCTestExpectation *expectation;
@end

@implementation TestBDAutoTrackBatchRequest

- (void)sendTrackDataFrom:(NSInteger)from {
    if (from == BDAutoTrackTriggerSourceTimer) {
        [self.expectation fulfill];
    }
}

@end

@interface TestBatchTimer : XCTestCase

@property (nonatomic, strong) id requestMock;
@property (nonatomic, strong) TestBDAutoTrackBatchRequest *request;
@property (nonatomic, strong) BDAutoTrackBatchTimer *timer;
@property (nonatomic, copy) NSString *appID;

@end

@implementation TestBatchTimer

- (void)setUp {
    self.appID = [NSString stringWithFormat:@"%u",arc4random()];
    self.timer = [[BDAutoTrackBatchTimer alloc] initWithAppID:self.appID];
    self.request = [TestBDAutoTrackBatchRequest new];
    self.request.expectation = nil;
    self.timer.request = self.request;
    self.requestMock = OCMPartialMock(self.request);
}

- (void)tearDown {
    [self.requestMock stopMocking];
    self.timer = nil;
    self.request = nil;
}

- (void)testInterval {
    BDAutoTrackBatchTimer *timer = self.timer;
    CFTimeInterval batchInterval = 0.2;
    XCTestExpectation *expectation = [self expectationWithDescription:@"testTimer"];
    expectation.expectedFulfillmentCount = 6;
    self.request.expectation = expectation;
    [timer updateTimerInterval:batchInterval];
    [self waitForExpectations:@[expectation] timeout:expectation.expectedFulfillmentCount * batchInterval + 0.2];
}

- (void)testLaunch {
    NSString *appID = self.appID;
    NSDictionary *userInfo = @{kBDAutoTrackNotificationAppID:appID};
    OCMExpect([self.requestMock sendTrackDataFrom:BDAutoTrackTriggerSourceInitApp]);
    [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationActiveSuccess
                                                        object:nil
                                                      userInfo:userInfo];
    OCMVerifyAllWithDelay(self.requestMock, 0.2);
}

- (void)testActiveFinishAppIDWrong {
    NSDictionary *userInfo = @{kBDAutoTrackAPPID:@""};
    static IMP imp = nil;
    __block NSInteger index = 0;
    XCTAssertEqual(index, 0);
    /// 验证onDidBecomeActive不会被执行
    imp = bd_swizzle_instance_methodWithBlock([BDAutoTrackBatchTimer class], @selector(onDidBecomeActive), ^(BDAutoTrackBatchTimer *_self){
        index++;
        if (imp) {
            ((void ( *)(id, SEL))imp)(_self, @selector(onDidBecomeActive));
        }
    });

    [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationActiveSuccess
                                                        object:nil
                                                      userInfo:userInfo];
    XCTAssertEqual(index, 0);
}

- (void)testSkipLaunch {
    NSString *appID = self.appID;
    NSDictionary *userInfo = @{kBDAutoTrackAPPID:appID};
    BDAutoTrackBatchTimer *timer = self.timer;
    timer.skipLaunch = YES;
    timer.batchInterval = 0.2;
    OCMExpect([self.requestMock sendTrackDataFrom:BDAutoTrackTriggerSourceTimer]);
    [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationActiveSuccess object:nil userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    OCMVerifyAllWithDelay(self.requestMock, 0.3);
}

- (void)testForeground {
    OCMExpect([self.requestMock sendTrackDataFrom:BDAutoTrackTriggerSourceEnterForground]);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
    OCMVerifyAllWithDelay(self.requestMock, 1.2);
}

- (void)testBackground {
    OCMExpect([self.requestMock sendTrackDataFrom:BDAutoTrackTriggerSourceEnterBackground]);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    OCMVerifyAllWithDelay(self.requestMock, 0.2);
}

- (void)testActive {
    OCMExpect([self.requestMock sendTrackDataFrom:BDAutoTrackTriggerSourceInitApp]);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    OCMVerifyAllWithDelay(self.requestMock, 0.2);
}

- (void)testTimer {
    BDAutoTrackBatchTimer *timer = self.timer;
    timer.batchInterval = 0.2;
    XCTestExpectation *expectation = [self expectationWithDescription:@"testTimer"];
    expectation.expectedFulfillmentCount = 6;
    self.request.expectation = expectation;
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];

    [self waitForExpectations:@[expectation] timeout:expectation.expectedFulfillmentCount * timer.batchInterval + 0.2];
}

- (void)testBgTask {
    BDAutoTrackBatchTimer *timer = self.timer;
    timer.backgroundTimeout = 2;
    id mock = OCMPartialMock(timer);
    OCMExpect([timer endBackgroundTask]);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    OCMVerifyAllWithDelay(mock, 2.1);
}

- (void)testTerminate {
    [[self.requestMock reject] ignoringNonObjectArgs];
    /// Terminate first
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillTerminateNotification
                                                        object:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification
                                                        object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification
                                                        object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification
                                                        object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationActiveSuccess
                                                        object:nil];
    OCMVerifyAllWithDelay(self.requestMock, 4);
}

@end
