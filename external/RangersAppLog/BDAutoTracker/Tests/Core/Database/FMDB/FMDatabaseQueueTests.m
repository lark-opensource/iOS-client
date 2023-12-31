//
//  BDAutoTrackDatabaseQueueTests.m
//  fmdb
//
//  Created by Graham Dennis on 24/11/2013.
//
//

#import "FMDBTempDBTests.h"

@interface BDAutoTrackDatabaseQueueTests : FMDBTempDBTests

@property BDAutoTrackDatabaseQueue *queue;

@end

@implementation BDAutoTrackDatabaseQueueTests

+ (void)populateDatabase:(BDAutoTrackDatabase *)db
{
    [db executeUpdate:@"create table easy (a text)"];
    
    [db executeUpdate:@"create table qfoo (foo text)"];
    [db executeUpdate:@"insert into qfoo values ('hi')"];
    [db executeUpdate:@"insert into qfoo values ('hello')"];
    [db executeUpdate:@"insert into qfoo values ('not')"];
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.queue = [BDAutoTrackDatabaseQueue databaseQueueWithPath:self.databasePath];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testQueuePath
{
    XCTAssertEqualObjects(self.queue.path, self.databasePath);
    XCTAssertNotEqual(SQLITE_OPEN_READONLY, self.queue.openFlags);
}

- (void)testQueueSelect
{
    [self.queue inDatabase:^(BDAutoTrackDatabase *adb) {
        int count = 0;
        BDAutoTrackResultSet *rsl = [adb executeQuery:@"select * from qfoo where foo like 'h%'"];
        while ([rsl next]) {
            count++;
        }
        
        XCTAssertEqual(count, 2);
        
        count = 0;
        rsl = [adb executeQuery:@"select * from qfoo where foo like ?", @"h%"];
        while ([rsl next]) {
            count++;
        }
        
        XCTAssertEqual(count, 2);
    }];
}

- (void)testReadOnlyQueue
{
    BDAutoTrackDatabaseQueue *queue2 = [BDAutoTrackDatabaseQueue databaseQueueWithPath:self.databasePath flags:SQLITE_OPEN_READONLY];
    XCTAssertNotNil(queue2);

    {
        [queue2 inDatabase:^(BDAutoTrackDatabase *db2) {
            BDAutoTrackResultSet *rs1 = [db2 executeQuery:@"SELECT * FROM qfoo"];
            XCTAssertNotNil(rs1);

            [rs1 close];
            
            XCTAssertFalse(([db2 executeUpdate:@"insert into easy values (?)", [NSNumber numberWithInt:3]]), @"Insert should fail because this is a read-only database");
        }];
        
        [queue2 close];
        
        // Check that when we re-open the database, it's still read-only
        [queue2 inDatabase:^(BDAutoTrackDatabase *db2) {
            BDAutoTrackResultSet *rs1 = [db2 executeQuery:@"SELECT * FROM qfoo"];
            XCTAssertNotNil(rs1);
            
            [rs1 close];
            
            XCTAssertFalse(([db2 executeUpdate:@"insert into easy values (?)", [NSNumber numberWithInt:3]]), @"Insert should fail because this is a read-only database");
        }];
    }
}

- (void)testStressTest
{
    size_t ops = 16;
    
    dispatch_queue_t dqueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_apply(ops, dqueue, ^(size_t nby) {
        
        // just mix things up a bit for demonstration purposes.
        if (nby % 2 == 1) {
            [NSThread sleepForTimeInterval:.01];
            
            [self.queue inTransaction:^(BDAutoTrackDatabase *adb, BOOL *rollback) {
                BDAutoTrackResultSet *rsl = [adb executeQuery:@"select * from qfoo where foo like 'h%'"];
                while ([rsl next]) {
                    ;// whatever.
                }
            }];
            
        }
        
        if (nby % 3 == 1) {
            [NSThread sleepForTimeInterval:.01];
        }
        
        [self.queue inTransaction:^(BDAutoTrackDatabase *adb, BOOL *rollback) {
            XCTAssertTrue([adb executeUpdate:@"insert into qfoo values ('1')"]);
            XCTAssertTrue([adb executeUpdate:@"insert into qfoo values ('2')"]);
            XCTAssertTrue([adb executeUpdate:@"insert into qfoo values ('3')"]);
        }];
    });
    
    [self.queue close];
    
    [self.queue inDatabase:^(BDAutoTrackDatabase *adb) {
        XCTAssertTrue([adb executeUpdate:@"insert into qfoo values ('1')"]);
    }];
}

- (void)testTransaction
{
    [self.queue inDatabase:^(BDAutoTrackDatabase *adb) {
        [adb executeUpdate:@"create table transtest (a integer)"];
        XCTAssertTrue([adb executeUpdate:@"insert into transtest values (1)"]);
        XCTAssertTrue([adb executeUpdate:@"insert into transtest values (2)"]);
        
        int rowCount = 0;
        BDAutoTrackResultSet *ars = [adb executeQuery:@"select * from transtest"];
        while ([ars next]) {
            rowCount++;
        }
        
        XCTAssertEqual(rowCount, 2);
    }];
    
    [self.queue inTransaction:^(BDAutoTrackDatabase *adb, BOOL *rollback) {
        XCTAssertTrue([adb executeUpdate:@"insert into transtest values (3)"]);
        
        if (YES) {
            // uh oh!, something went wrong (not really, this is just a test
            *rollback = YES;
            return;
        }
        
        XCTFail(@"This shouldn't be reached");
    }];
    
    [self.queue inDatabase:^(BDAutoTrackDatabase *adb) {
        
        int rowCount = 0;
        BDAutoTrackResultSet *ars = [adb executeQuery:@"select * from transtest"];
        while ([ars next]) {
            rowCount++;
        }
        
        XCTAssertFalse([adb hasOpenResultSets]);
        
        XCTAssertEqual(rowCount, 2);
    }];

}

@end
