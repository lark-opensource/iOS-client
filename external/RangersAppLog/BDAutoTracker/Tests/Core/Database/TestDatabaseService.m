//
//  TestDatabaseService.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/14.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackDatabaseService.h>
#import <RangersAppLog/BDAutoTrackServiceCenter.h>
#import <RangersAppLog/BDTrackerCoreConstants.h>

@interface TestDatabaseService : XCTestCase

@property (nonatomic, copy) NSString *appID;

@end

@implementation TestDatabaseService

- (void)setUp {
    [[BDAutoTrackServiceCenter defaultCenter] unregisterAllServices];
    self.appID = @"0";

    BDAutoTrackDatabaseService *database = [[BDAutoTrackDatabaseService alloc] initWithAppID:self.appID];
    [database registerService];
}

- (void)testCeateTable {
    XCTAssertNotNil(bd_databaseCeateTable(@"test_create", self.appID));
    NSArray *allTableName = [bd_databaseServiceForAppID(self.appID) allTableNames];
    XCTAssertNotNil(allTableName);
    XCTAssertFalse([allTableName containsObject:@"test_create"]);
}

- (void)testServiceAvailable {
    XCTAssertNotNil(bd_standardServices(BDAutoTrackServiceNameDatabase, self.appID));
    XCTAssertNotNil(bd_databaseServiceForAppID(self.appID));
}

- (void)testAllTableNames {
    NSArray *allTableName = [bd_databaseServiceForAppID(self.appID) allTableNames];
    XCTAssertNotNil(allTableName);
    XCTAssertGreaterThanOrEqual(allTableName.count, 4);

    NSString *tableName = @"test_table_name";
    NSString *trackID = [NSUUID UUID].UUIDString;
    bd_databaseInsertTrack(tableName, @{}, trackID, self.appID);

    allTableName = [bd_databaseServiceForAppID(self.appID) allTableNames];
    XCTAssertTrue([allTableName containsObject:tableName]);
    
    NSDictionary *allTracks = [bd_databaseServiceForAppID(self.appID) allTracksForBatchReport];
    XCTAssertNotNil(allTracks);
    NSArray *tracks = [allTracks objectForKey:tableName];
    XCTAssertNotNil(tracks);
    NSMutableArray *trackIDs = [NSMutableArray new];
    [tracks enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        NSString *trackID = [obj objectForKey:kBDAutoTrackTableColumnTrackID];
        [trackIDs addObject:trackID];
    }];
    XCTAssertTrue([trackIDs containsObject:trackID]);
}

- (void)testTracks {
    NSString *tableName = @"test_table_insert";
    NSString *trackID = [NSUUID UUID].UUIDString;
    bd_databaseInsertTrack(tableName, @{}, trackID, self.appID);

    NSArray *allTableName = [bd_databaseServiceForAppID(self.appID) allTableNames];
    XCTAssertTrue([allTableName containsObject:tableName]);
    /// not effect
    bd_databaseRemoveTracks(@{}, self.appID);

    NSDictionary *allTracks = [bd_databaseServiceForAppID(self.appID) allTracksForBatchReport];
    XCTAssertNotNil(allTracks);
    NSArray *tracks = [allTracks objectForKey:tableName];
    XCTAssertNotNil(tracks);
    NSMutableArray *trackIDs = [NSMutableArray new];
    [tracks enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        NSString *trackID = [obj objectForKey:kBDAutoTrackTableColumnTrackID];
        [trackIDs addObject:trackID];
    }];
    XCTAssertTrue([trackIDs containsObject:trackID]);

    bd_databaseRemoveTracks(@{tableName:trackIDs}, self.appID);
    allTracks = [bd_databaseServiceForAppID(self.appID) allTracksForBatchReport];
    XCTAssertNotNil(allTracks);
    tracks = [allTracks objectForKey:tableName];
    XCTAssertNil(tracks);
}

@end
