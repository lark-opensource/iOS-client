//
//  BDAutoTrackMonitorStore.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/24.
//

#import "BDAutoTrackMonitorStore.h"
#import "BDAutoTrackDatabaseQueue.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackDatabase.h"
#import "RangersLog.h"
#import "BDAutoTrackMetricsCollector.h"
#import "BDAutoTrack.h"



@implementation BDAutoTrackMonitorStore {
    
    BDAutoTrackDatabaseQueue *database;
    BOOL    _databaseEnabled;
    
    NSMutableArray *_memoryCache;
    
}

static NSString *gLaunchID;
static BOOL hitSampling;

+ (void)load
{
    gLaunchID = [[NSUUID UUID] UUIDString];
    hitSampling = YES;
}


+ (instancetype)sharedStore {
    static BDAutoTrackMonitorStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [BDAutoTrackMonitorStore new];
    });
    return store;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _memoryCache = [NSMutableArray array];
    database = [[BDAutoTrackDatabaseQueue alloc] initWithPath:[self databasePath]];
    [self initDatabase];
}

- (NSString *)databasePath
{
    NSString *libPath =  bd_trackerLibraryPath();
    return [libPath stringByAppendingPathComponent:@"monitor.dat"];
}

- (void)initDatabase
{
    NSAssert(![NSThread isMainThread], @"Can not run in main thread.");
    NSString *statement =
    @"CREATE TABLE IF NOT EXISTS SDK_MONITOR ("
    "metricsId  INTEGER PRIMARY KEY AUTOINCREMENT,"
    "launchId   TEXT NOT NULL,"
    "appId      TEXT NOT NULL,"
    "name       TEXT NOT NULL,"
    "category   TEXT NOT NULL,"
    "metrics    BOLB NOT NULL,"
    "procId     TEXT,"
    "procState  INTEGER DEFAULT 0,"
    "remark     TEXT"
    ");";

    [database inDatabase:^(BDAutoTrackDatabase *db) {
        NSError *error;
        BOOL success = [db executeUpdate:statement values:nil error:&error];
        if (success) {
            self->_databaseEnabled = YES;
        } else {
            RL_ERROR(nil, @"Monitor", @"database init failure due to CREATE TABLE. (%d - %@)",error.code, error.localizedDescription);
        }
    }];
    
}



#pragma mark - Public

+ (void)sampling:(NSUInteger)monitorSamplingRate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hitSampling = ([gLaunchID hash] % 100) < monitorSamplingRate;
    });
}

- (void)enqueue:(NSArray<BDAutoTrackMetrics *> *)metricsList
{
    // 未命中采样时，埋点不采集
    if (!hitSampling) {
        return;
    }
    if ([metricsList count] == 0) {
        return;
    }
    static NSString *statement = @"INSERT INTO SDK_MONITOR (launchId,appId,name,category,metrics,remark,procId) VALUES (?,?,?,?,?,?,?);";
    [database inTransaction:^(BDAutoTrackDatabase *db, BOOL *rollback) {
        [metricsList enumerateObjectsUsingBlock:^(BDAutoTrackMetrics * _Nonnull metrics, NSUInteger idx, BOOL * _Nonnull stop) {
            NSError *error;
            metrics.launchId = gLaunchID;
            if(![db executeUpdate:statement values:[metrics transformSQLiteParameters] error:&error]) {
            }
        }];
    }];
}


- (void)updateProcess:(NSString *)procId
{
    if (procId.length == 0) {
        return;
    }
    static NSString *statement = @"UPDATE SDK_MONITOR set procState = 1 where procId = ?;";
    [database inTransaction:^(BDAutoTrackDatabase *db, BOOL *rollback) {
        if([db executeUpdate:statement values:@[procId?:@""] error:nil]) {
        }
    }];
}

- (void)dequeue:(NSString *)appId usingBlock:(BOOL (^)(NSArray<BDAutoTrackMetrics *> *metricsList))block
{
    if (!block) {
        return;
    }
    NSString *statement = [NSString stringWithFormat:@"SELECT * FROM SDK_MONITOR where appId = ? and launchId <> ? order by metricsId asc LIMIT 200;"];
    
    BOOL isClear = NO;
    int errorCount = 0;
    do {
        NSMutableArray *metricsList = [NSMutableArray arrayWithCapacity:200];
        __block NSInteger maxMetricsId = 0;
        [self->database inDatabase:^(BDAutoTrackDatabase *db) {
            NSError *error;
            BDAutoTrackResultSet *rs = [db executeQuery:statement values:@[appId,gLaunchID] error:&error];
            while ([rs next]) {
                @try {
                    
                    NSData *metricsData = [rs dataForColumn:@"metrics"];
                    if (metricsData) {
                        BDAutoTrackMetrics *metrics = [NSKeyedUnarchiver unarchiveObjectWithData:metricsData];
                        if (metrics && [metrics.name length] > 0) {
                            metrics.processId = [rs stringForColumn:@"procId"];
                            metrics.processState = [rs intForColumn:@"procState"];
                            [metricsList addObject:metrics];
                        }
                    }
                    maxMetricsId = [rs intForColumn:@"metricsId"];
                    
                }@catch(...){};
            }
            [rs close];
        }];
        
        
        BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:appId];
        
        RL_DEBUG(tracker, @"Monitor", @"load data from cache...[%d]",metricsList.count);
        if (metricsList.count < 200) {
            isClear = YES;
        }
        if (metricsList.count > 0 && block) {
            
            if (block(metricsList)) {
                RL_DEBUG(tracker, @"Monitor", @"remove data cache...[%d]",metricsList.count);
                NSString *deleteStatement = @"DELETE FROM SDK_MONITOR where appId = ? and metricsId <= ?;";
                [self->database inDatabase:^(BDAutoTrackDatabase *db) {
                    NSError *error;
                    if(![db executeUpdate:deleteStatement values:@[appId,@(maxMetricsId)] error:&error]) {
                        RL_ERROR(tracker, @"Monitor", @"delete from cache failure due to SQLiteError %@(%d)", error.localizedDescription,error.code);
                    }
                }];
            } else {
                errorCount ++;
                if (errorCount >= 3) {
                    isClear = YES;
                }
            }
        }
        
    } while(!isClear);
    
    [self->database inDatabase:^(BDAutoTrackDatabase *db) {
        [db executeUpdate:@"VACUUM"];
    }];
    
}


#pragma mark - Queue

@end
