//
//  TestRgisterRequest.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/14.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackNetworkRequest.h>
#import <RangersAppLog/BDAutoTrackRegisterRequest.h>
#import <RangersAppLog/BDAutoTrackRegisterService.h>
#import <OCMock/OCMock.h>
#import <RangersAppLog/BDAutoTrackNotifications.h>
#import <RangersAppLog/BDAutoTrackReachability.h>
#import <RangersAppLog/BDAutoTrackNetworkRequest.h>
#import <RangersAppLog/BDAutoTrackParamters.h>
#import <RangersAppLog/BDAutoTrackLocalConfigService.h>

#import "AppLogTestTool.h"

@interface TestRgisterRequest : XCTestCase

@end

@implementation TestRgisterRequest


- (void)testNoNetwork {
    BDAutoTrackRegisterRequest *request = [[BDAutoTrackRegisterRequest alloc] initWithAppID:@"0" next:nil];
    id mock = OCMPartialMock(request);
    id network = OCMClassMock([BDAutoTrackReachability class]);
    OCMStub([network isNetworkConnected]).andReturn(NO);
    OCMReject([mock handleResponse:[OCMArg any]]);
    [request startRequestWithRetry:1];
    OCMVerifyAllWithDelay(mock, 4);
}

- (void)testNetworkChange {
    BDAutoTrackRegisterRequest *request = [[BDAutoTrackRegisterRequest alloc] initWithAppID:@"0" next:nil];
    id mock = OCMPartialMock(request);
    id network = OCMClassMock([BDAutoTrackReachability class]);
    OCMExpect([network isNetworkConnected]).andReturn(NO);
    [request startRequestWithRetry:3];
    OCMExpect([mock startRequestWithRetry:1]);
    OCMExpect([network isNetworkConnected]).andReturn(YES);
    [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackReachabilityDidChangeNotification object:nil];

    OCMVerifyAll(mock);
    [network stopMocking];
}

- (void)testRequestForeground {
    BDAutoTrackRegisterRequest *request = [[BDAutoTrackRegisterRequest alloc] initWithAppID:@"0" next:nil];
    id mock = OCMPartialMock(request);
    OCMStub([mock handleResponse:[OCMArg any]]).andReturn(NO);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
    OCMExpect([mock startRequestWithRetry:1]);
    OCMVerifyAllWithDelay(mock, 4);
}

@end
