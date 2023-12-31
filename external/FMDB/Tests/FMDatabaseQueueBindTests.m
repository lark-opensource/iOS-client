//
//  FMDatabaseQueueBindTests.m
//  FMDB-Unit-Tests
//
//  Created by bob on 2020/5/9.
//

#import "FMDBTempDBTests.h"
#import "FMDatabaseQueue.h"

#if FMDB_SQLITE_STANDALONE
#import <sqlite3/sqlite3.h>
#else
#import <sqlite3.h>
#endif

@interface FMDatabaseQueueBindTests : FMDBTempDBTests

@property FMDatabaseQueue *queue;
@property FMResultSet *insert;
@property FMResultSet *delete;

@end

@implementation FMDatabaseQueueBindTests

+ (void)populateDatabase:(FMDatabase *)db
{
    [db executeUpdate:@"create table IF NOT EXISTS bd_tracker (track_id text, entire_log text, PRIMARY KEY(track_id))"];
}

- (void)setUp
{
    [super setUp];
    self.queue = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
//        db.shouldCacheStatements = YES;
    }];
    __block FMResultSet *insert;
    __block FMResultSet *delete;
    /// prepare
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = @"DELETE From bd_tracker WHERE track_id = ?";
        delete = [db prepare:sql];
        XCTAssert(delete, @"DELETE statement not prepared %@", [db lastErrorMessage]);
    }];
    
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = @"INSERT OR REPLACE INTO bd_tracker (track_id, entire_log) values (?,?)";
        insert = [db prepare:sql];
        XCTAssert(insert, @"INSERT statement not prepared %@", [db lastErrorMessage]);
    }];
    
    self.insert = insert;
    self.delete = delete;
}

- (NSArray<NSDictionary *> *)valuesToTest {
    NSMutableArray<NSDictionary *> *values = [NSMutableArray new];
    
    for (NSUInteger index = 0; index < 200; index++) {
        NSDictionary *event = @{
            @"event":@"event_name",
            @"param":@{
                    @"date":@"current"
            }
        };
        NSData *data = [NSJSONSerialization dataWithJSONObject:event
                                                   options:0
                                                     error:nil];
        
        
        NSString *entireLogString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
        NSDictionary *track = @{
            @"track_id":[NSUUID UUID].UUIDString,
            @"track":entireLogString,
        };
        [values addObject:track];
    }
    
    return values;
}

- (void)oldStyle {
    NSArray<NSDictionary *> *values = [self valuesToTest];
    
    /// insert
    for (NSDictionary *value in values) {
        NSString *trackID = [value objectForKey:@"track_id"];
        NSString *event = [value objectForKey:@"track"];
        [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
            NSString *sql = @"INSERT OR REPLACE INTO bd_tracker (track_id, entire_log) values (?,?)";
            [db executeUpdate:sql values:@[trackID, event] error:nil];
        }];
    }
    
    NSMutableArray<NSString *> *trackIDs = [NSMutableArray new];
    NSMutableArray<NSString *> *result = [NSMutableArray new];
    /// select
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *query = @"SELECT * from bd_tracker";
        FMResultSet *dbResult = [db executeQuery:query];
        while ([dbResult next]) {
            NSString *paramsJSONString = [dbResult stringForColumn:@"entire_log"];
            NSString *trackID = [dbResult stringForColumn:@"track_id"];
            [trackIDs addObject:trackID];
            [result addObject:paramsJSONString];
        }
    }];
    
    XCTAssertEqual(trackIDs.count, values.count);
    
    /// delete
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM bd_tracker WHERE track_id IN ("];
    NSString *sep = @"";
    for (NSString *trackID in trackIDs) {
        [sql appendFormat:@"%@'%@'", sep, trackID];
        sep = @",";
    }
    [sql appendString:@")"];
    
    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:sql];
    }];
}

- (void)bindStyle {
    NSArray<NSDictionary *> *values = [self valuesToTest];
    /// insert
    for (NSDictionary *value in values) {
        NSString *trackID = [value objectForKey:@"track_id"];
        NSString *event = [value objectForKey:@"track"];
        FMResultSet *insert = self.insert;
        [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
            [insert bindWithArray:@[trackID, event]];
            [insert step];
        }];
    }
    
    NSMutableArray<NSString *> *trackIDs = [NSMutableArray new];
    NSMutableArray<NSString *> *result = [NSMutableArray new];
    /// select
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *query = @"SELECT * from bd_tracker";
        FMResultSet *dbResult = [db executeQuery:query];
        while ([dbResult next]) {
            NSString *paramsJSONString = [dbResult stringForColumn:@"entire_log"];
            NSString *trackID = [dbResult stringForColumn:@"track_id"];
            [trackIDs addObject:trackID];
            [result addObject:paramsJSONString];
        }
    }];
    
    XCTAssertEqual(trackIDs.count, values.count);
    
    /// delete
    FMResultSet *delete = self.delete;
    [self.queue inTransaction:^(FMDatabase * db, BOOL * _Nonnull rollback) {
        for (NSString *value in trackIDs) {
            [delete bindWithArray:@[value]];
            [delete step];
        }
    }];
}

- (void)tearDown
{
    [self.queue close];
    [self.insert close];
    [self.delete close];
}

- (void)testPerformanceOld
{
    [self measureBlock:^{
        for (NSUInteger index = 0; index < 10; index++) {
            [self oldStyle];
        }
    }];
}

- (void)testPerformanceBind
{
    [self measureBlock:^{
        for (NSUInteger index = 0; index < 10; index++) {
            [self bindStyle];
        }
    }];
}

@end
