//
//  TestDatabase.m
//  BDTuring_Tests
//
//  Created by bob on 2019/9/18.
//  Copyright © 2019 Bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <fmdb/FMDB.h>
#import <BDTuring/BDTuringDatabaseTable.h>
#import <BDTuring/BDTuringUtility.h>
#import <BDTuring/NSObject+BDTuring.h>

@interface TestDatabase : XCTestCase

@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, strong) BDTuringDatabaseTable *table;

@end

@implementation TestDatabase

- (void)setUp {
    NSString *file = turing_sdkDatabaseFile();
    self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:file];
    self.table = [[BDTuringDatabaseTable alloc] initWithTableName:@"test_table"
                                                    databaseQueue:self.databaseQueue];
}

- (void)tearDown {
    self.table = nil;
    [self.databaseQueue close];
    self.databaseQueue = nil;
}

- (void)testInsert {
    NSDictionary *allTracks = [self.table allTracks];
    if (allTracks.count > 0) {
        [self.table removeAllTracks];
    }
    allTracks = [self.table allTracks];
    XCTAssertNotNil(allTracks);
    XCTAssertEqual(allTracks.count, 0);

    NSDictionary *track = @{@"Test":@"Track"};
    [self.table insertTrack:[track turing_JSONRepresentation]];
    allTracks = [self.table allTracks];
    XCTAssertNotNil(allTracks);
    XCTAssertGreaterThanOrEqual(allTracks.count, 1);

    NSString *read = allTracks.allValues.lastObject;
    XCTAssertEqualObjects([track turing_JSONRepresentation], read);
    /// remove
    [self.table removeAllTracks];

    allTracks = [self.table allTracks];
    XCTAssertNotNil(allTracks);
    XCTAssertEqual(allTracks.count, 0);
}

@end
