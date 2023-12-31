//
//  TestBaseRequest.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/15.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackRequest.h>
#import <RangersAppLog/BDAutoTrackNetworkRequest.h>
#import <OCMock/OCMock.h>

@interface TestBaseRequest : XCTestCase

@property (nonatomic, copy) NSString *appID;

@end

@implementation TestBaseRequest

- (void)setUp {
    self.appID = @"-1";
}


@end
