//
//  TestBatchService.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/16.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <RangersAppLog/BDAutoTrackRegisterService.h>
#import <RangersAppLog/BDAutoTrackDatabaseService.h>
#import <RangersAppLog/BDAutoTrackBatchService.h>
#import <RangersAppLog/BDAutoTrackBatchTimer.h>
#import <RangersAppLog/BDAutoTrackServiceCenter.h>
#import <RangersAppLog//BDAutoTrackBatchData.h>
#import <RangersAppLog//BDTrackerCoreConstants.h>
#import <RangersAppLog//BDAutoTrackReachability.h>
#import <RangersAppLog/BDAutoTrackLocalConfigService.h>

#import "AppLogTestTool.h"

@interface BDAutoTrackBatchService (Test)
@property (nonatomic, strong) BDAutoTrackBatchTimer *batchTimer;
- (void)sendTrackDataInternalFirstTime:(BOOL)first ;
- (void)handleBatchSendCallback:(NSDictionary *)responseDict
                      firstTime:(BOOL)first
                           task:(nullable BDAutoTrackBatchData *)sendingTask;
@end

@interface TestBatchService : XCTestCase
@property (nonatomic, copy) NSString *appID;
@end

@implementation TestBatchService

- (void)setUp {
    [super setUp];
    self.appID = @"0";
}

- (void)testTimer {
    BDAutoTrackBatchService *batch = [[BDAutoTrackBatchService alloc] initWithAppID:self.appID];
    [batch registerService];
    bd_batchUpdateTimer(3, YES, self.appID);
    id batchmock = OCMPartialMock(batch);
    OCMReject([batchmock sendTrackDataFrom:BDAutoTrackTriggerSourceInitApp]);
    OCMVerifyAllWithDelay(batchmock, 4);
}

- (void)testBlackList {
    NSDictionary *responseDict = @{kBDAutoTrackMagicTag :BDAutoTrackMagicTag,
                                   kBDAutoTrackMessage  :BDAutoTrackMessageSuccess,
                                   @"blocklist":@{@"v1":@[],
                                                  @"v3":@[@"test_blackList"],
                                   },};

    BDAutoTrackBatchService *batch = [[BDAutoTrackBatchService alloc] initWithAppID:self.appID];
    [batch registerService];
    XCTAssertFalse(bd_batchIsEventInBlockList(@"test_blackList", self.appID));
    [batch handleBatchSendCallback:responseDict firstTime:YES task:nil];
    XCTAssertTrue(bd_batchIsEventInBlockList(@"test_blackList", self.appID));
}

@end
