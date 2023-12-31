//
//  BDAutoTrackBaseTable.m
//  Applog
//
//  Created by bob on 2019/1/28.
//

#import "BDAutoTrackBaseTable.h"
#import "BDAutoTrackDB.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackUtility.h"
#import "RangersLog.h"
#import "NSDictionary+VETyped.h"
#import "BDTrackerErrorBuilder.h"


static const NSUInteger AppLogEventSizeLimit     = 50 * 1024; // 50 Kb

@interface BDAutoTrackBaseTable ()

@property (nonatomic, copy) NSString *tableName;
@property (nonatomic, strong) BDAutoTrackDatabaseQueue *databaseQueue;

@end


@implementation BDAutoTrackBaseTable


- (instancetype)initWithTableName:(NSString *)tableName
                    databaseQueue:(BDAutoTrackDatabaseQueue *)databaseQueue {
    self = [super init];
    if (self) {
        self.tableName = tableName;
        self.databaseQueue = databaseQueue;
        [self checkDBFile];
    }
    
    return self;
}

- (void)deleteAll
{
    
    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM %@;", self.tableName];
    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        [db executeUpdate:deleteSQL];
        
    }];
}

/// 执行建表SQL
- (void)checkDBFile {
    NSString *createSQL = [self createTableSql];
    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        [db executeUpdate:createSQL];
        db.shouldCacheStatements = YES;
    }];
    
    NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSince1970];
    //alter table columns
    NSArray *columns = [self columnsForTable];
    
    if (![columns containsObject:@"time"]) {
        NSString *alterStatement = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN time INTEGER NOT NULL DEFAULT 0", self.tableName];
        [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
            if ([db executeUpdate:alterStatement]) {
                [db executeUpdate:[NSString stringWithFormat:@"update %@ set time = %lld WHERE time = 0;",self.tableName, (long long)(currentTimeInterval*1000)]];
            }
        }];
    }
    
    if (![columns containsObject:@"priority"]) {
        NSString *alterStatement = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN priority REAL NOT NULL DEFAULT 0", self.tableName];
        [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
            [db executeUpdate:alterStatement];
        }];
    }
    
    //remove expired data
//    NSTimeInterval earliestTimeInterval = (currentTimeInterval - 1000*60*60*24*7); // 7 days
//    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
//        NSString *statement = [NSString stringWithFormat:@"DELETE FROM %@ WHERE time <= %lld;", self.tableName,(long long)earliestTimeInterval];
//        [db executeUpdate:statement];
//    }];
    
    
}

- (NSArray *)columnsForTable {
    NSMutableArray *columns = [[NSMutableArray alloc] init];
    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        BDAutoTrackResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"PRAGMA table_info(%@)", self.tableName]];
        while ([resultSet next]) {
            [columns addObject:[resultSet stringForColumn:@"name"]];
        }
        [resultSet close];
    }];
    return columns;
}

- (bool)insertTrack:(NSDictionary *)track trackID:(NSString *)trackID  withError:(NSError **)outErr {
    return [self insertTrack:track trackID:trackID options:nil withError:outErr];
}

/// insert a track into the table (埋点入库)
/// Execute INSERT SQL
/// caller: - [DatabaseService insertTable: track: trackID:]
/// @param track Dic 埋点数据
/// @param trackID track_id. 若未指定则生成一个随机的UUID.
/// @return YES if SQL is performed successfully, else NO.
- (bool)insertTrack:(NSDictionary *)track
            trackID:(NSString *)trackID
            options:(nullable NSDictionary *)options
          withError:(NSError **)outErr {
    // 如果没有传入trackID，则trackID默认为一个新UUID
    if (![trackID isKindOfClass:[NSString class]] || trackID.length < 1) {
        trackID = [[NSUUID UUID] UUIDString];
    }
    
    NSInteger localTimeMS = [[track objectForKey:@"local_time_ms"] integerValue];

    // JSON 序列化
    NSData *jsonData;
    __block NSError *err;
#ifdef DEBUG
    if (@available(iOS 13.0, *)) {
        jsonData = [NSJSONSerialization dataWithJSONObject:track
                                                      options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys | NSJSONWritingWithoutEscapingSlashes
                                                        error:nil];
    } else {
        jsonData = [NSJSONSerialization dataWithJSONObject:track
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:nil];
    }
#else
    jsonData = [NSJSONSerialization dataWithJSONObject:track
                                               options:0
                                                 error:&err];
#endif
    if (err) {
        if (outErr) {
            *outErr  =err;
        }
        return NO;
    }
    
    // 大日志处理：日志超过 50K 则丢弃，然后上报一个内部事件
    if (jsonData.length > AppLogEventSizeLimit) {
        NSMutableDictionary *errorTrack = [track mutableCopy];
        NSString *event = [errorTrack vetyped_stringForKey:kBDAutoTrackEventType] ?: @"";
        NSDictionary *param = @{@"event_name":event,@"reason":@"event param too large"};
        [errorTrack setValue:param forKey:kBDAutoTrackEventData];
        [errorTrack setValue:@"sdk_bad_event_warning" forKey:kBDAutoTrackEventType];
        
        jsonData = [NSJSONSerialization dataWithJSONObject:errorTrack
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:nil];
    }

    // 将JSON Data转为JSON String
    NSString *entireLogString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (entireLogString.length <= 0) {
        if (outErr) {
            *outErr = [[[BDTrackerErrorBuilder builder] withCode:1001] build];
        }
        return NO;
    }
    
    // 执行SQL语句
    NSString *sql = [self insertSql];
    NSInteger priority = [[options objectForKey:@"priority"] integerValue];
    __block BOOL success = NO;
    __block NSError *sqliteError;
    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        success = [db executeUpdate:sql values:@[trackID, entireLogString,@(localTimeMS),@(priority)] error:&sqliteError];
        
    }];
    if (sqliteError) {
        if (outErr) {
            *outErr = sqliteError;
        }
    }
    return success;

}

/// remove many tracks from the table, specified by `trackIDs`.
/// Execute DELETE SQL.
/// caller: - [BDAutoTrackBatchService removeTracks]
/// @param trackIDs List<Str> 要删除的 track_id
- (void)removeTracksByID:(NSArray<NSString *> *)trackIDs {
    if (![trackIDs isKindOfClass:[NSArray class]] || trackIDs.count < 1) {
        return;
    }
    
    NSString *tableName = [self tableName];
    
    NSMutableArray<NSString *> *binds = [NSMutableArray new];
    NSUInteger count = trackIDs.count;
    for (NSUInteger index = 0; index < count; index++ ) {
        [binds addObject:@"?"];
    }
    
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE track_id IN (%@);", tableName, [binds componentsJoinedByString:@","]];

    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        [db executeUpdate:sql values:trackIDs error:nil];
    }];
}

- (void)downgradeTracksByID:(NSArray<NSString *> *)trackIDs {
    if (![trackIDs isKindOfClass:[NSArray class]] || trackIDs.count < 1) {
        return;
    }
    
    NSString *tableName = [self tableName];
    NSMutableArray<NSString *> *binds = [NSMutableArray new];
    NSUInteger count = trackIDs.count;
    for (NSUInteger index = 0; index < count; index++ ) {
        [binds addObject:@"?"];
    }
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ set priority = 0 WHERE track_id IN (%@);", tableName, [binds componentsJoinedByString:@","]];
    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        [db executeUpdate:sql values:trackIDs error:nil];
    }];
}

/// SELECT Query. 获取最多200条埋点数据。
/// caller: - [BDAutoTrackDatabaseService allTracks]
/// caller: bd_db_allTableNames()
/// @return List<Dic> 埋点数据组成的数组
- (NSArray<NSDictionary *> *)allTracks:(nullable NSDictionary *)options {
    NSMutableArray *result = [NSMutableArray array];
    
    //0 + 99
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ limit 200;", self.tableName];
    
    BOOL specifyPriority = [options.allKeys containsObject:@"priority"];
    if (specifyPriority) {
        // 99 only
        NSInteger priority = [[options objectForKey:@"priority"] integerValue];
        query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE priority = %ld limit 200;", self.tableName, (long)priority];
    }
    
    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        BDAutoTrackResultSet *dbResult = [db executeQuery:query];

        while ([dbResult next]) {
            @autoreleasepool {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];

                NSString *paramsJSONString = [dbResult stringForColumn:kBDAutoTrackTableColumnEntireLog];
                NSDictionary *entireLogDict = nil;
                @try {
                    entireLogDict = bd_JSONValueForString(paramsJSONString);
                } @catch (__unused NSException *e) {
                }
                if ([entireLogDict isKindOfClass:[NSDictionary class]] && entireLogDict.count > 0) {
                    [dict addEntriesFromDictionary:entireLogDict];
                }
                [dict setValue:[dbResult stringForColumn:kBDAutoTrackTableColumnTrackID] forKey:kBDAutoTrackTableColumnTrackID];
                [result addObject:dict];
            }
        }
        [dbResult close];
    }];

    return result;
}

/// 创建表SQL语句。字段：
///  track_id 整型 主键列
///  entire_log 字符串
- (NSString *)createTableSql {
        return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ \
                (\
                track_id    VARCHAR(100),                   \
                entire_log  NVARCHAR(2000),                 \
                time        INTEGER NOT NULL DEFAULT 0,     \
                priority    REAL NOT NULL DEFAULT 0,        \
                PRIMARY KEY(track_id))", self.tableName];
}

- (NSString *)insertSql {
    return [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (track_id, entire_log, time, priority) VALUES(?, ?, ?, ?)", self.tableName];
}


- (NSUInteger)count
{
    NSString *statement = [NSString stringWithFormat:@"SELECT count(1) FROM %@;", self.tableName];
    __block NSUInteger count = 0;
    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        BDAutoTrackResultSet *dbResult = [db executeQuery:statement];
        if ([dbResult next]) {
            count = [dbResult longForColumnIndex:0];
        }
        [dbResult close];
    }];
    return count;
}

@end
