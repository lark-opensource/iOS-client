//
//  TestDatabase.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/9.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RangersAppLog/BDAutoTrackBaseTable.h>
#import <RangersAppLog/BDAutoTrackDB.h>
#import <RangersAppLog/BDTrackerCoreConstants.h>
#import <RangersAppLog/BDAutoTrackDatabaseService.h>

@interface BDAutoTrackBaseTable ()
- (bool)insertTrack:(NSDictionary *)track trackID:(NSString *)trackID;
@end

@interface TestDatabase : XCTestCase

@property (nonatomic, strong) BDAutoTrackDatabaseQueue *databaseQueue;
@property (nonatomic, strong) BDAutoTrackBaseTable *table;

@end

@implementation TestDatabase

- (void)setUp {
    NSString *file = bd_databaseFilePathForAppID(@"0");
    self.databaseQueue = [[BDAutoTrackDatabaseQueue alloc] initWithPath:file];
    self.table = [[BDAutoTrackBaseTable alloc] initWithTableName:@"test_table" databaseQueue:self.databaseQueue];
}

- (void)tearDown {
    self.table = nil;
    [self.databaseQueue close];
    self.databaseQueue = nil;
}

- (void)testDataBaseFileName {
    NSString *appID1 = @"112233";
    XCTAssertEqualObjects(bd_databaseFilePathForAppID(appID1), bd_databaseFilePathForAppID(appID1));

    NSString *appID2 = @"112234";
    XCTAssertNotEqualObjects(bd_databaseFilePathForAppID(appID1), bd_databaseFilePathForAppID(appID2));
}

- (void)testInsert {
    NSArray<NSDictionary *> *allTracks = [self.table allTracks];
    if (allTracks.count > 0) {
        NSMutableArray<NSString *> *trackIDs = [NSMutableArray new];
        for (NSDictionary *track in allTracks) {
            NSString *trackID = [track objectForKey:kBDAutoTrackTableColumnTrackID];
            [trackIDs addObject:trackID];
        }
        [self.table removeTracksByID:trackIDs];
    }
    allTracks = [self.table allTracks];
    XCTAssertNotNil(allTracks);
    XCTAssertEqual(allTracks.count, 0);

    NSDictionary *track = @{@"Test":@"Track"};
    bool insertSuccess = [self.table insertTrack:track trackID:nil];
    XCTAssertTrue(insertSuccess);
    
    allTracks = [self.table allTracks];
    XCTAssertNotNil(allTracks);
    XCTAssertGreaterThanOrEqual(allTracks.count, 1);

    NSDictionary *read = allTracks.lastObject;
    NSMutableDictionary *readWithoutID = [read mutableCopy];
    [readWithoutID removeObjectForKey:kBDAutoTrackTableColumnTrackID];
    XCTAssertEqualObjects(track, readWithoutID);
    NSString *trackID = [read objectForKey:kBDAutoTrackTableColumnTrackID];
    XCTAssertNotNil(trackID);
    /// remove
    [self.table removeTracksByID:@[trackID]];

    allTracks = [self.table allTracks];
    XCTAssertNotNil(allTracks);
    XCTAssertEqual(allTracks.count, 0);
}

- (void)testInsertWithID {
    NSArray<NSDictionary *> *allTracks = [self.table allTracks];
    if (allTracks.count > 0) {
        NSMutableArray<NSString *> *trackIDs = [NSMutableArray new];
        for (NSDictionary *track in allTracks) {
            NSString *trackID = [track objectForKey:kBDAutoTrackTableColumnTrackID];
            [trackIDs addObject:trackID];
        }
        [self.table removeTracksByID:trackIDs];
    }

    allTracks = [self.table allTracks];
    XCTAssertNotNil(allTracks);
    XCTAssertEqual(allTracks.count, 0);

    NSMutableDictionary *track = [@{@"Test":@"Track"} mutableCopy];
    NSString *trackID = @"test_id";
    bool insertSuccess = [self.table insertTrack:track trackID:trackID];
    XCTAssertTrue(insertSuccess);

    allTracks = [self.table allTracks];
    XCTAssertNotNil(allTracks);
    XCTAssertGreaterThanOrEqual(allTracks.count, 1);
    [track setValue:trackID forKey:kBDAutoTrackTableColumnTrackID];
    NSDictionary *read = allTracks.lastObject;
    XCTAssertEqualObjects(track, read);
    NSString *trackIDRead = [read objectForKey:kBDAutoTrackTableColumnTrackID];
    XCTAssertNotNil(trackIDRead);
    XCTAssertEqualObjects(trackID, trackIDRead);
    /// remove
    [self.table removeTracksByID:@[trackID]];

    allTracks = [self.table allTracks];
    XCTAssertNotNil(allTracks);
    XCTAssertEqual(allTracks.count, 0);
}

@end
