//
//  TestScheme.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/24.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackSchemeHandler.h>
#import <RangersAppLog/BDAutoTrack.h>
#import <OCMock/OCMock.h>


@interface TestSchemeHandler : NSObject<BDAutoTrackSchemeHandler>

@end

@implementation TestSchemeHandler

- (BOOL)handleURL:(NSURL *)URL appID:(NSString *)appID scene:(nullable id)scene {
    return NO;
}

@end

@interface TestScheme : XCTestCase
@property (nonatomic, copy) NSString *appID;
@end

@implementation TestScheme

- (void)setUp {
    self.appID = @"0";
}

- (void)testEvent {
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:self.appID launchOptions:nil];
    config.channel = @"App Store";
    config.appName = @"dp_tob_sdk_test2";
    config.appID = self.appID;

    BDAutoTrack *track = [BDAutoTrack trackWithConfig:config];
    id trackMock = OCMPartialMock(track);
    NSURL *URL = [NSURL URLWithString:@"https://baidu.com/v1/?test=1"];
    [[BDAutoTrackSchemeHandler sharedHandler] handleURL:URL appID:self.appID scene:nil];
    OCMVerify([trackMock eventV3:[OCMArg any] params:[OCMArg any]]);
}

- (void)testHandler {
    TestSchemeHandler *handler = [TestSchemeHandler new];
    id mock = OCMPartialMock(handler);
    [[BDAutoTrackSchemeHandler sharedHandler] registerHandler:handler];
    NSURL *URL = [NSURL URLWithString:@"https://baidu.com/v1/?test=1"];
    [[BDAutoTrackSchemeHandler sharedHandler] handleURL:URL appID:self.appID scene:nil];
    OCMVerify([mock handleURL:URL appID:self.appID scene:nil]);

    TestSchemeHandler *handler1 = [TestSchemeHandler new];
    id mock1 = OCMPartialMock(handler1);
    [[BDAutoTrackSchemeHandler sharedHandler] registerHandler:handler1];
    [[BDAutoTrackSchemeHandler sharedHandler] unregisterHandler:handler1];
    [[BDAutoTrackSchemeHandler sharedHandler] handleURL:URL appID:self.appID scene:nil];
    OCMReject([mock1 handleURL:URL appID:self.appID scene:nil]);
}


@end
