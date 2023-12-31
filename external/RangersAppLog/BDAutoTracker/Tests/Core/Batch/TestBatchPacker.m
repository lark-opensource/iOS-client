//
//  TestBatchPacker.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/16.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackRegisterService.h>
#import <RangersAppLog/BDAutoTrackBatchData.h>
#import <RangersAppLog/BDAutoTrackBatchPacker.h>
#import <RangersAppLog/BDTrackerCoreConstants.h>
#import <RangersAppLog/BDAutoTrackTables.h>
#import <RangersAppLog/BDAutoTrackDatabaseService.h>
#import <RangersAppLog/BDAutoTrackDB.h>
#import <RangersAppLog/BDAutoTrackBaseTable.h>
#import <RangersAppLog/BDAutoTrackLocalConfigService.h>
#import "AppLogTestTool.h"

@interface TestBatchPacker : XCTestCase
@property (nonatomic, copy) NSString *appID;
@end

@implementation TestBatchPacker

- (void)setUp {
    [super setUp];
    self.appID = @"0";
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:self.appID launchOptions:nil];
    config.channel = @"App Store";
    config.appName = @"dp_tob_sdk_test2";
    config.appID = self.appID;
    BDAutoTrackLocalConfigService *settings = [[BDAutoTrackLocalConfigService alloc] initWithConfig:config];
    [settings registerService];
}

- (void)testPackRawTracks {
    NSString *session = @"session";
    NSArray *rawTracks = @[@{kBDAutoTrackTableColumnTrackID:@"testid",
                             kBDAutoTrackEventSessionID:session,
                             },
                           ];
    NSString *tableName = BDAutoTrackTableTerminate;
    /// terminate and session
    BDAutoTrackBatchItem *result = bd_batchPackRawTracks(rawTracks, tableName, session);
    XCTAssertNotNil(result);
    XCTAssertEqual(result.trackID.count, 0);
    XCTAssertEqual(result.trackData.count, 0);

    /// terminate not this session
    rawTracks = @[@{kBDAutoTrackTableColumnTrackID:@"testid",
                    kBDAutoTrackEventSessionID:@"test",
                    },
                  ];
    result = bd_batchPackRawTracks(rawTracks, tableName, session);
    XCTAssertNotNil(result);
    XCTAssertEqual(result.trackID.count, 1);
    XCTAssertEqual(result.trackData.count, 1);

    /// not terminate
    rawTracks = @[@{kBDAutoTrackTableColumnTrackID:@"testid",
                    kBDAutoTrackEventSessionID:@"test",
                    },
                  ];
    tableName = BDAutoTrackTableLaunch;
    result = bd_batchPackRawTracks(rawTracks, tableName, session);
    XCTAssertNotNil(result);
    XCTAssertEqual(result.trackID.count, 1);
    XCTAssertEqual(result.trackData.count, 1);
}

- (NSDictionary<NSString *, NSArray *> *)generateTracks:(NSArray<NSString *> *)tableNames
                                                  count:(NSInteger)count {
    NSMutableDictionary<NSString *, NSArray *> *allTracks = [NSMutableDictionary new];

    [tableNames enumerateObjectsUsingBlock:^(NSString *tableName, NSUInteger idx, BOOL *stop) {
        NSInteger index = count;
        NSMutableArray *tracks = [NSMutableArray new];
        while (index-->0) {
            NSDictionary *track = @{kBDAutoTrackTableColumnTrackID:[NSString stringWithFormat:@"%@_%zd",tableName, index],
                                    kBDAutoTrackEventSessionID:@"test",
                                    };
            [tracks addObject:track];
        }

        [allTracks setValue:tracks forKey:tableName];
    }];


    return allTracks;
}

- (void)testPackAllTracks {
    NSUInteger maxCountPerTask = 50;

    NSDictionary<NSString *, NSArray *> *allTracks = [self generateTracks:@[@"Test"]
                                                                    count:maxCountPerTask - 2];
    BDAutoTrackBatchData *tasks = nil;
    
    tasks = bd_batchPackAllTracks(allTracks, maxCountPerTask);
    XCTAssertEqual(tasks.maxEventCount, maxCountPerTask - 2);
    [tasks.sendingTrackID.allValues enumerateObjectsUsingBlock:^(NSArray * obj, NSUInteger idx, BOOL *stop) {
        XCTAssertLessThanOrEqual(obj.count, maxCountPerTask);
    }];
    
    
    allTracks = [self generateTracks:@[@"Test"]
                               count:maxCountPerTask];
    tasks = bd_batchPackAllTracks(allTracks, maxCountPerTask);
    XCTAssertEqual(tasks.maxEventCount, maxCountPerTask);
    [tasks.sendingTrackID.allValues enumerateObjectsUsingBlock:^(NSArray * obj, NSUInteger idx, BOOL *stop) {
        XCTAssertLessThanOrEqual(obj.count, maxCountPerTask);
    }];
    
    allTracks = [self generateTracks:@[@"Test"]
                               count:maxCountPerTask + 10];
    tasks = bd_batchPackAllTracks(allTracks, maxCountPerTask);
    XCTAssertEqual(tasks.maxEventCount, maxCountPerTask + 10);
    [tasks.sendingTrackID.allValues enumerateObjectsUsingBlock:^(NSArray * obj, NSUInteger idx, BOOL *stop) {
        XCTAssertLessThanOrEqual(obj.count, maxCountPerTask);
    }];
    
    allTracks = [self generateTracks:@[@"Test", @"test-2"]
                               count:maxCountPerTask - 1];
    tasks = bd_batchPackAllTracks(allTracks, maxCountPerTask);
    XCTAssertEqual(tasks.maxEventCount, maxCountPerTask - 1);
    [tasks.sendingTrackID.allValues enumerateObjectsUsingBlock:^(NSArray * obj, NSUInteger idx, BOOL *stop) {
        XCTAssertLessThanOrEqual(obj.count, maxCountPerTask);
    }];
    
    allTracks = [self generateTracks:@[@"Test", @"test-2"]
                               count:maxCountPerTask + 10];
    tasks = bd_batchPackAllTracks(allTracks, maxCountPerTask);
    XCTAssertEqual(tasks.maxEventCount, maxCountPerTask + 10);
    [tasks.sendingTrackID.allValues enumerateObjectsUsingBlock:^(NSArray * obj, NSUInteger idx, BOOL *stop) {
        XCTAssertLessThanOrEqual(obj.count, maxCountPerTask);
    }];
}

@end
