#import <sqlite3.h>

#import "TTClearCacheRule.h"
#import "TTDownloadManager.h"
#import "TTDownloadSliceTaskConfig.h"
#import "TTDownloadSqliteStorage.h"
#import "TTDownloadTaskConfig.h"
#import "TTDownloadTrackModel.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const SQL_CREATE_DOWNLOAD_TASK_CONFIG = @"CREATE TABLE IF NOT EXISTS DownloadTaskConfig ("
"MAIN_URL_MD5 TEXT PRIMARY KEY,"
"MAIN_URL TEXT,"
"SECOND_URL TEXT,"
"FILE_STORAGE_NAME TEXT,"
"FILE_MD5 TEXT,"
"SLICE_COUNT INTEGER,"
"DOWNLOAD_STATUS INTEGER);";
/**
 *This table store task's all of parameters.It store as json format,which can adapt all kinds of case.
 *For example, we can add or delete a parameter at any time.And to improve performance,we reserve 8 column
 *to store the frequent change parameter.
 */
NSString *const SQL_CREATE_DOWNLOAD_TASK_PARAMETERS = @"CREATE TABLE IF NOT EXISTS DownloadTaskParameters ("
"MAIN_URL_MD5 TEXT PRIMARY KEY,"
"RESTORE_TIMES_REMAIN INTEGER,"
"VERSION_TYPE INTEGER,"
"PARAMETER_JSON TEXT,"
"COLUMN1 INTEGER,"
"COLUMN2 INTEGER,"
"COLUMN3 INTEGER,"
"COLUMN4 INTEGER,"
"COLUMN5 INTEGER,"
"COLUMN6 INTEGER,"
"COLUMN7 TEXT,"
"COLUMN8 TEXT);";

NSString *const SQL_CREATE_DOWNLOAD_SLICE_TASK_CONFIG = @"CREATE TABLE IF NOT EXISTS DownloadSliceTaskConfig ("
"MAIN_URL_MD5 TEXT,"
"SLICE_NUMBER INTEGER,"
"SLICE_NAME TEXT,"
"SLICE_SIZE INTEGER,"
"PRIMARY KEY(MAIN_URL_MD5,SLICE_NUMBER));";

NSString *const SQL_CREATE_SUB_SLICE_INFO = @"CREATE TABLE IF NOT EXISTS SubSliceInfo ("
"MAIN_URL_MD5 TEXT,"
"SLICE_NUMBER INTEGER,"
"SUB_SLICE_NUMBER INTEGER,"
"RANGE_START INTEGER,"
"RANGE_END INTEGER,"
"SUB_SLICE_NAME TEXT,"
"SLICE_STATUS INTEGER,"
"COLUMN1 INTEGER,"
"COLUMN2 INTEGER,"
"COLUMN3 INTEGER,"
"COLUMN4 INTEGER,"
"COLUMN5 TEXT,"
"COLUMN6 TEXT,"
"PRIMARY KEY(MAIN_URL_MD5,SLICE_NUMBER,SUB_SLICE_NUMBER));";

NSString *const SQL_CREATE_DOWNLOAD_TRACK_MODEL = @"CREATE TABLE IF NOT EXISTS DownloadTrackModel ("
"DOWNLOAD_ID TEXT,"
"MAIN_URL_MD5 TEXT,"
"TRACK_PARAM TEXT,"
"PRIMARY KEY(DOWNLOAD_ID,MAIN_URL_MD5));";

NSString *const SQL_CREATE_CACHE_CLEAR_INFO = @"CREATE TABLE IF NOT EXISTS DownloadCacheClearInfo ("
"CLEAR_ID TEXT PRIMARY KEY,"
"CLEAR_RULE_OBJ_JSON TEXT,"
"COLUMN1 INTEGER,"
"COLUMN2 TEXT)";

NSString *const DOWNLOAD_TASK_CONFIG_COLUMN = @"MAIN_URL_MD5, MAIN_URL, SECOND_URL, FILE_STORAGE_NAME, FILE_MD5, SLICE_COUNT, DOWNLOAD_STATUS";

NSString *const DOWNLOAD_TASK_PARAMETERS_COLUMN = @"MAIN_URL_MD5, RESTORE_TIMES_REMAIN, VERSION_TYPE, PARAMETER_JSON, COLUMN1, COLUMN2, COLUMN3, COLUMN4, COLUMN5, COLUMN6, COLUMN7, COLUMN8";

NSString *const DOWNLOAD_SLICE_TASK_CONFIG_COLUMN = @"MAIN_URL_MD5, SLICE_NUMBER, SLICE_NAME, SLICE_SIZE";

NSString *const SUB_SLICE_INFO_COLUMN = @"MAIN_URL_MD5, SLICE_NUMBER, SUB_SLICE_NUMBER, RANGE_START, RANGE_END, SUB_SLICE_NAME, SLICE_STATUS, COLUMN1, COLUMN2, COLUMN3, COLUMN4, COLUMN5, COLUMN6";

NSString *const DOWNLOAD_TRACK_MODEL_COLUMN = @"DOWNLOAD_ID, MAIN_URL_MD5, TRACK_PARAM";

NSString *const CACHE_CLEAR_INFO_COLUMN = @"CLEAR_ID, CLEAR_RULE_OBJ_JSON, COLUMN1, COLUMN2";

static const uint32_t kDownloaderCacheCapacityMaxDefault = 50000U;
static const uint32_t kDownloaderCacheClearOnceCount = 2000U;

typedef NS_ENUM(int8_t, Strategy) {
    DATA_BASE_DELETE = 1,
    DATA_BASE_MAX,
};

@interface TTDownloadSqliteStorage () {
    sqlite3 *sqlite;
    NSLock  *sqliteLock;
}
@end

@implementation TTDownloadSqliteStorage

- (instancetype)init {
    self = [super init];
    
    if (self) {
        sqliteLock = [[NSLock alloc] init];
        [self openDataBase];
    }
    
    return self;
}

- (void)dealloc {
    DLLOGD(@"dlLog:dealloc:file=%s ,function=%s", __FILE__, __FUNCTION__);
    if (sqlite) {
        sqlite3_close(sqlite);
        sqlite = nil;
    }
}

- (void)openDataBase {
    NSString *downloadDBPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                                stringByAppendingPathComponent:@"ttnet_downloader_db.sqlite"];
    /**
     * Disaster recovery mode. Support delete database.
     */
    if (DATA_BASE_DELETE == [[TTDownloadManager shareInstance] getTncConfig].tncDataBaseStrategy) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:downloadDBPath error:&error]) {
            DLLOGD(@"delete database failed error=%@", error.description);
            /**
             * Try delete again.
             */
            error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:downloadDBPath error:&error];
            if (error) {
                DLLOGD(@"delete database failed again error=%@", error.description);
            }
        }
        
    }
    
    int result = sqlite3_open([downloadDBPath fileSystemRepresentation], &sqlite);
    
    if (result == SQLITE_OK) {
        [self createTable];
    } else {
        sqlite3_close(sqlite);
        sqlite = nil;
        DLLOGD(@"downloader open download db fail");
    }
}

- (void)createTable {
    NSError *error = nil;
    if (![self executeSQL:SQL_CREATE_DOWNLOAD_TASK_CONFIG error:&error isDisableLock:NO]) {
        DLLOGD(@"error %@", error);
    }
    error = nil;
    if (![self executeSQL:SQL_CREATE_DOWNLOAD_SLICE_TASK_CONFIG error:&error isDisableLock:NO]) {
        DLLOGD(@"error %@", error);
    }
    error = nil;
    if (![self executeSQL:SQL_CREATE_DOWNLOAD_TRACK_MODEL error:&error isDisableLock:NO]) {
        DLLOGD(@"error %@", error);
    }
    error = nil;
    if (![self executeSQL:SQL_CREATE_DOWNLOAD_TASK_PARAMETERS error:&error isDisableLock:NO]) {
        DLLOGD(@"error %@", error);
    }
    error = nil;
    if (![self executeSQL:SQL_CREATE_SUB_SLICE_INFO error:&error isDisableLock:NO]) {
        DLLOGD(@"error %@", error);
    }
    error = nil;
    if (![self executeSQL:SQL_CREATE_CACHE_CLEAR_INFO error:&error isDisableLock:NO]) {
        DLLOGD(@"error %@", error);
    }
}

#pragma mark - ClearCache

- (BOOL)insertOrUpdateClearCacheRule:(TTClearCacheRule *)rule
                               error:(NSError **)error1 {
    return [self inTransaction:^(BOOL *rollback, NSError **error) {
        NSString *ruleJson = rule ? [rule toJSONString] : nil;
        NSString *sqlString = [NSString stringWithFormat:@"INSERT OR REPLACE INTO DownloadCacheClearInfo(%@) "
                               "VALUES ('%@','%@',%d,'%@')",
                               CACHE_CLEAR_INFO_COLUMN,
                               [TTNetworkUtil getNONEmptyString:rule.clearId],
                               [TTNetworkUtil getNONEmptyString:ruleJson],
                               0,
                               [TTNetworkUtil getNONEmptyString:nil]];
        if (![self executeSQL:sqlString error:error isDisableLock:NO]) {
            *rollback = YES;
            return;
        }
    } error:error1 isDisableLock:NO];
}

- (BOOL)deleteClearCacheRule:(TTClearCacheRule *)rule
                       error:(NSError **)error1 {
    return [self inTransaction:^(BOOL *rollback, NSError **error) {
        NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM DownloadCacheClearInfo WHERE CLEAR_ID = '%@'", rule.clearId];
        if (![self executeSQL:sqlString error:error isDisableLock:NO]) {
            *rollback = YES;
            return;
        }
    } error:error1 isDisableLock:NO];
}

- (NSMutableDictionary<NSString *, TTClearCacheRule *> *)getAllClearCacheRule:(NSError **)error1 {
    NSMutableDictionary<NSString *, TTClearCacheRule *> *clearRuleDic = [NSMutableDictionary dictionary];

    @try {
        NSString *querySql = @"SELECT CLEAR_RULE_OBJ_JSON from DownloadCacheClearInfo";
        
        [sqliteLock lock];
        sqlite3_stmt *stmt = nil;
        int result = sqlite3_prepare_v2(sqlite, querySql.UTF8String, -1, &stmt, nil);
        if (result != SQLITE_OK) {
            DLLOGD(@"downloader querySql failed:%@", querySql);
            NSString *log = [NSString stringWithFormat:@"getAllClearCacheRule:sqlite3_prepare_v2 failed,result=%d", result];
            *error1 = [self makeErrorInfo:log result:result];
            return nil;
        }
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            DOWNLOADER_AUTO_RELEASE_POOL_BEGIN
            NSString *ruleJson = [self getStringColumn:stmt index:0];
            TTClearCacheRule *rule = [[TTClearCacheRule alloc] initWithString:ruleJson error:nil];
            if (rule) {
                rule.isTncSet = NO;
                [clearRuleDic setObject:rule forKey:rule.clearId];
            }
            DOWNLOADER_AUTO_RELEASE_POOL_END
        }
        sqlite3_finalize(stmt);
    } @catch (NSException *exception) {
        NSString *log = [NSString stringWithFormat:@"getAllClearCacheRule:exception:name=%@,reason=%@", exception.name, exception.reason];
        *error1 = [self makeErrorInfo:log result:-1];
    } @finally {
        [sqliteLock unlock];
    }
    return clearRuleDic;
}

#pragma mark - TTDownloadTaskConfig
/**
 *Query DownloadTaskConfig by url.
 */
- (BOOL)queryDownloadTaskConfigWithUrlSync:(NSString *)url
                   downloadTaskResultBlock:(DownloadTaskResultBlock)downloadTaskResultBlock
                                     error:(NSError **)error1 {
    NSString *queryDTC = [NSString stringWithFormat:@"SELECT %@ from DownloadTaskConfig where MAIN_URL = '%@'", DOWNLOAD_TASK_CONFIG_COLUMN, url];
    
    NSString *queryDSTC =
    [[NSString stringWithFormat:@"SELECT %@ from DownloadSliceTaskConfig", DOWNLOAD_SLICE_TASK_CONFIG_COLUMN] stringByAppendingString:@" where MAIN_URL_MD5 = '%@'"];
    
    NSString *querySubSliceInfo =
    [[NSString stringWithFormat:@"SELECT %@ from SubSliceInfo", SUB_SLICE_INFO_COLUMN] stringByAppendingString:@" where MAIN_URL_MD5 = '%@'"];
    
    NSString *queryParameters = [[NSString stringWithFormat:@"SELECT %@ from DownloadTaskParameters", DOWNLOAD_TASK_PARAMETERS_COLUMN] stringByAppendingString:@" where MAIN_URL_MD5 = '%@'"];
    
    NSMutableDictionary *configs = [self queryDownloadTaskConfigImpl:queryDTC
                                                           queryDSTC:queryDSTC
                                                   querySubSliceInfo:querySubSliceInfo
                                                          parameters:queryParameters
                                                      querySingleDTC:YES
                                                               error:error1];
    
    if (configs) {
        downloadTaskResultBlock([configs objectForKey:url]);
        return YES;
    } else {
        downloadTaskResultBlock(nil);
        return NO;
    }
}

/**
 * Get all of DownloadTaskConfig
 */
- (BOOL)queryAllDownloadTaskConfigSync:(AllDownloadTaskResultBlock)allDownloadTaskResultBlock
                                 error:(NSError **)error1 {
    NSString *queryDTC = [NSString stringWithFormat:@"SELECT %@ from DownloadTaskConfig", DOWNLOAD_TASK_CONFIG_COLUMN];
    
    NSString *queryDSTC = [NSString stringWithFormat:@"SELECT %@ from DownloadSliceTaskConfig", DOWNLOAD_SLICE_TASK_CONFIG_COLUMN];

    NSString *querySubSliceInfo =
    [NSString stringWithFormat:@"SELECT %@ from SubSliceInfo", SUB_SLICE_INFO_COLUMN];
    
    NSString *queryParameters = [NSString stringWithFormat:@"SELECT %@ from DownloadTaskParameters", DOWNLOAD_TASK_PARAMETERS_COLUMN];
    
    NSMutableDictionary *allTTDownloadTaskConfig = [self queryDownloadTaskConfigImpl:queryDTC
                                                                           queryDSTC:queryDSTC
                                                                   querySubSliceInfo:querySubSliceInfo
                                                                          parameters:queryParameters
                                                                      querySingleDTC:NO
                                                                               error:error1];
    if (allTTDownloadTaskConfig) {
        allDownloadTaskResultBlock(allTTDownloadTaskConfig);
        return YES;
    } else {
        allDownloadTaskResultBlock(nil);
        return NO;
    }
}

- (uint32_t)getCacheCapacityMax {
    uint32_t cacheCapacityMax = [[TTDownloadManager shareInstance] getTncConfig].tncDLCacheCapacityMax;
    return cacheCapacityMax > 0 ? cacheCapacityMax : kDownloaderCacheCapacityMaxDefault;
}

- (uint32_t)getCacheClearOnceCount {
    uint32_t cacheClearOnceCount = [[TTDownloadManager shareInstance] getTncConfig].tncDLCacheClearOnceCount;
    return cacheClearOnceCount > 0 ? cacheClearOnceCount : kDownloaderCacheClearOnceCount;
}

- (void)clearInvalidCache:(NSArray *)taskConfigArray taskConfigDic:(NSMutableDictionary *)taskConfigDic {
    uint32_t cacheCapacityMax = [self getCacheCapacityMax];
    
    if (taskConfigArray.count <= cacheCapacityMax) {
        return;
    }

    uint32_t cacheClearOnceCount = [self getCacheClearOnceCount];
    for (int i = 0; (i < (taskConfigArray.count - cacheCapacityMax)) && (i < cacheClearOnceCount); ++i) {
        @autoreleasepool {
            TTDownloadTaskConfig *config = [taskConfigArray objectAtIndex:i];
            if ([self deleteDownloadTaskConfigSyncOnSingleThread:config error:nil]) {
                [taskConfigDic removeObjectForKey:config.urlKey];
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:[TTDownloadManager.shareInstance.appSupportPath stringByAppendingPathComponent:config.fileStorageDir] error:&error]) {
                    DLLOGD(@"delete failed,error=%@", error.description);
                }
            }
        }
    }
}

- (NSMutableDictionary *)queryDownloadTaskConfigImpl:(NSString *)queryDTC
                                           queryDSTC:(NSString *)queryDSTC
                                   querySubSliceInfo:(NSString *)querySubSliceInfo
                                          parameters:(NSString *)queryParameters
                                      querySingleDTC:(BOOL)querySingleDTC
                                               error:(NSError **)error1 {
    NSMutableDictionary *ttDTCForKeyUrl = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *ttDTCForKeyMd5 = [[NSMutableDictionary alloc] init];

    @try {
        [sqliteLock lock];
        sqlite3_stmt *stmt = nil;
        int result = sqlite3_prepare_v2(sqlite, queryDTC.UTF8String, -1, &stmt, nil);
        if (result != SQLITE_OK) {
            NSString *log = [NSString stringWithFormat:@"queryDownloadTaskConfigImpl:sqlite3_prepare_v2:1:result=%d,", result];
            *error1 = [self makeErrorInfo:log result:result];
            DLLOGD(@"downloader downloadTask sqlite3_prepare error sql:%@", queryDTC);
            return nil;
        }
        
        NSMutableArray<TTDownloadTaskConfig *> *taskConfigArray = [[NSMutableArray alloc] init];
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            DOWNLOADER_AUTO_RELEASE_POOL_BEGIN
            TTDownloadTaskConfig *ttDTC = [[TTDownloadTaskConfig alloc] init];
            ttDTC.fileStorageDir = [self getStringColumn:stmt index:0];
            ttDTC.urlKey = [self getStringColumn:stmt index:1];
            ttDTC.secondUrl = [self getStringColumn:stmt index:2];
            ttDTC.fileStorageName = [self getStringColumn:stmt index:3];
            ttDTC.md5Value = [self getStringColumn:stmt index:4];
            ttDTC.sliceTotalNeedDownload = sqlite3_column_int(stmt, 5);
            DLLOGD(@"queryDownloadTaskConfigImpl:ttDTC.sliceTotalNeedDownload=%d", ttDTC.sliceTotalNeedDownload);
            ttDTC.downloadStatus = sqlite3_column_int(stmt, 6);
            [ttDTCForKeyUrl setObject:ttDTC forKey:ttDTC.urlKey];
            [ttDTCForKeyMd5 setObject:ttDTC forKey:ttDTC.fileStorageDir];
            [taskConfigArray addObject:ttDTC];
            DOWNLOADER_AUTO_RELEASE_POOL_END
        }
        sqlite3_finalize(stmt);
        
        [self clearInvalidCache:taskConfigArray taskConfigDic:ttDTCForKeyUrl];
        [taskConfigArray removeAllObjects];
        
        if (querySingleDTC) {
            if (ttDTCForKeyUrl.count > 0) {
                NSArray *array                  = [ttDTCForKeyUrl allValues];
                TTDownloadTaskConfig *singleDTC = [array firstObject];
                if (!singleDTC) {
                    return nil;
                }
                queryDSTC = [NSString stringWithFormat:queryDSTC, singleDTC.fileStorageDir];
                querySubSliceInfo = [NSString stringWithFormat:querySubSliceInfo, singleDTC.fileStorageDir];
                queryParameters = [NSString stringWithFormat:queryParameters, singleDTC.fileStorageDir];
            } else {
                return nil;
            }
        }
        
        result = sqlite3_prepare_v2(sqlite, queryDSTC.UTF8String, -1, &stmt, nil);
        if (result != SQLITE_OK) {
            DLLOGD(@"downloader downloadSliceTask sqlite3_prepare error sql:%@", queryDSTC);
            NSString *log = [NSString stringWithFormat:@"queryDownloadTaskConfigImpl:sqlite3_prepare_v2:2:result=%d,", result];
            *error1 = [self makeErrorInfo:log result:result];
            return nil;
        }
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            DOWNLOADER_AUTO_RELEASE_POOL_BEGIN
            TTDownloadSliceTaskConfig *ttDSTC = [[TTDownloadSliceTaskConfig alloc] init];
            NSString *urlKeyMd5 = [self getStringColumn:stmt index:0];
            ttDSTC.sliceNumber = sqlite3_column_int(stmt, 1);
            ttDSTC.sliceTempStorageName = [self getStringColumn:stmt index:2];
            ttDSTC.sliceTotalLength = sqlite3_column_int64(stmt, 3);
            TTDownloadTaskConfig *ttDTC = [ttDTCForKeyMd5 objectForKey:urlKeyMd5];
            
            if (ttDTC) {
                ttDSTC.urlKey = ttDTC.urlKey;
                ttDSTC.secondUrl = ttDTC.secondUrl;
                [ttDTC.downloadSliceTaskConfigArray addObject:ttDSTC];
            }
            DOWNLOADER_AUTO_RELEASE_POOL_END
        }
        sqlite3_finalize(stmt);
        
        
        /**
         *Read sub slice information.If it's nil,will dispose as old code.
         */
        result = sqlite3_prepare_v2(sqlite, querySubSliceInfo.UTF8String, -1, &stmt, nil);
        if (result != SQLITE_OK) {
            NSString *log = [NSString stringWithFormat:@"queryDownloadTaskConfigImpl:sqlite3_prepare_v2:3:result=%d,", result];
            *error1 = [self makeErrorInfo:log result:result];
            DLLOGD(@"downloader downloadSliceTask sqlite3_prepare error sql:%@", queryDSTC);
        }
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            DOWNLOADER_AUTO_RELEASE_POOL_BEGIN
            TTDownloadSubSliceInfo *subSlice = [[TTDownloadSubSliceInfo alloc] init];
            subSlice.fileStorageDir = [self getStringColumn:stmt index:0];
            subSlice.sliceNumber = sqlite3_column_int(stmt, 1);
            subSlice.subSliceNumber = sqlite3_column_int(stmt, 2);
            subSlice.rangeStart = sqlite3_column_int64(stmt, 3);
            subSlice.rangeEnd = sqlite3_column_int64(stmt, 4);
            subSlice.subSliceName = [self getStringColumn:stmt index:5];
            subSlice.sliceStatus = sqlite3_column_int(stmt, 6);
            TTDownloadTaskConfig *ttDTC = [ttDTCForKeyMd5 objectForKey:subSlice.fileStorageDir];
            
            if (ttDTC) {
                /**
                 *Check core array.
                 */
                if (ttDTC.sliceTotalNeedDownload != ttDTC.downloadSliceTaskConfigArray.count) {
                    continue;
                }
                TTDownloadSliceTaskConfig *sliceTaskConfig = [ttDTC.downloadSliceTaskConfigArray objectAtIndex:(subSlice.sliceNumber - 1)];
                [sliceTaskConfig.subSliceInfoArray addObject:subSlice];
                DLLOGD(@"dlLog:sliceTaskConfig.subSliceInfoArray.count=%lu, subSlice.subSliceNumber=%lu",
                       (unsigned long)sliceTaskConfig.subSliceInfoArray.count, (unsigned long)subSlice.subSliceNumber);
            }
            DOWNLOADER_AUTO_RELEASE_POOL_END
        }
        
        sqlite3_finalize(stmt);
        /**
         *Get task's parameters from DB.
         */
        result = sqlite3_prepare_v2(sqlite, queryParameters.UTF8String, -1, &stmt, nil);
        if (result != SQLITE_OK) {
            NSString *log = [NSString stringWithFormat:@"queryDownloadTaskConfigImpl:sqlite3_prepare_v2:4:result=%d,", result];
            *error1 = [self makeErrorInfo:log result:result];
            DLLOGD(@"parameters find failed sqlite3_prepare error sql:%@", queryParameters);
        } else {
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                DOWNLOADER_AUTO_RELEASE_POOL_BEGIN
                NSString *urlKeyMd5 = [self getStringColumn:stmt index:0];
                int8_t restoreTimesRemain = sqlite3_column_int(stmt, 1);
                int16_t versionType = sqlite3_column_int(stmt, 2);
                NSString *parametersJson = [self getStringColumn:stmt index:3];
                int isSupportRange = sqlite3_column_int(stmt, 4);
                DownloadGlobalParameters *param = [[DownloadGlobalParameters alloc] initWithString:parametersJson error:nil];
                
                NSString *config = [self getStringColumn:stmt index:10];
                TTDownloadTaskExtendConfig *extendConfig = [[TTDownloadTaskExtendConfig alloc] initWithString:config error:nil];
                
                TTDownloadTaskConfig *ttDTC = [ttDTCForKeyMd5 objectForKey:urlKeyMd5];
                if (ttDTC) {
                    DLLOGD(@"queryDownloadTaskConfigImpl:get patameter form db throttleNetSpeed=%lld restoreFirstValue=%d", param.throttleNetSpeed, param.restoreTimesAutomatic);
                    ttDTC.userParam = param;
                    ttDTC.extendConfig = extendConfig;
                    ttDTC.restoreTimesAuto = restoreTimesRemain;
                    ttDTC.versionType = versionType;
                    ttDTC.isSupportRange = isSupportRange > 0 ? YES : NO;
                }
                DOWNLOADER_AUTO_RELEASE_POOL_END
            }
        }
        sqlite3_finalize(stmt);
    } @finally {
        [sqliteLock unlock];
    }
    
    return ttDTCForKeyUrl;
}

- (BOOL)updateExtendConfigSync:(TTDownloadTaskConfig *)taskConfig
                         error:(NSError **)error {
    return [self updateParametersTableExtendColumnSync:taskConfig columnName:@"COLUMN7" error:error];
}

- (BOOL)updateParametersTableExtendColumnSync:(TTDownloadTaskConfig *)taskConfig
                                   columnName:(NSString *)column
                                        error:(NSError **)error {
    NSString *extendConfig = taskConfig.extendConfig ? [taskConfig.extendConfig toJSONString] : nil;
    NSString *sqlString = [NSString stringWithFormat:@"UPDATE DownloadTaskParameters set '%@' = '%@' where MAIN_URL_MD5='%@'", column, [TTNetworkUtil getNONEmptyString:extendConfig], taskConfig.fileStorageDir];

    if (![self executeSQL:sqlString error:error isDisableLock:NO]) {
        DLLOGD(@"error=%@", *error);
        return NO;
    }
    return YES;
}

- (NSString *)getStringColumn:(sqlite3_stmt *)stmt
                        index:(int)index {
    const char *cValue = (const char *)sqlite3_column_text(stmt, index);
    NSString *value = [NSString stringWithUTF8String:cValue];
    
    if (!value || value.length == 0) {
        return nil;
    }
    return value;
}

/**
 * Insert or update DownloadTaskConfig
 */
- (BOOL)insertDownloadTaskConfigSync:(TTDownloadTaskConfig *)ttDTC
                               error:(NSError **)error1 {
    return [self inTransaction:^(BOOL *rollback, NSError **error) {
        DLLOGD(@"insertDownloadTaskConfigSync taskConfig %d", ttDTC.sliceTotalNeedDownload);

        if (![[TTDownloadManager class] isTaskConfigValid:ttDTC]) {
            *rollback = YES;
            return;
        }
        
        if (![self updateDownloadTaskConfigSync:ttDTC error:error]) {
            *rollback = YES;
            return;
        }
        
        /**
         *Insert data.
         */
        if (![self updateParametersTable:ttDTC error:error]) {
            *rollback = YES;
            return;
        }
        
        if (ttDTC.sliceTotalNeedDownload != ttDTC.downloadSliceTaskConfigArray.count) {
            *rollback = YES;
            return;
        }
        for (TTDownloadSliceTaskConfig *ttDSTC in ttDTC.downloadSliceTaskConfigArray) {
            if (![self updateDownloadSliceTaskConfig:ttDSTC downloadTaskConfig:ttDTC error:error]) {
                *rollback = YES;
                return;
            }
            
            for (TTDownloadSubSliceInfo *subSlice in ttDSTC.subSliceInfoArray) {
                if (![self insertOrUpdateSubSliceInfo:subSlice error:error]) {
                    *rollback = YES;
                    return;
                }
            }
            
        }
    } error:error1 isDisableLock:NO];
}

- (BOOL)updateDownloadTaskConfigSync:(TTDownloadTaskConfig *)ttDTC
                               error:(NSError **)error {
    //only DOWNLOADED and FAILED status is allowed
    if (!(ttDTC.downloadStatus == DOWNLOADED || ttDTC.downloadStatus == FAILED)) {
        DLLOGD(@"updateDownloadTaskConfigSync: downloadStatus %d is NOT allowed", (int)ttDTC.downloadStatus);
        return NO;
    }
    
    NSString *insertOrUpdateDTCTable =
    [NSString stringWithFormat:@"INSERT OR REPLACE INTO DownloadTaskConfig(%@) "
                                             "VALUES ('%@','%@','%@','%@','%@',%d, %d)",
                                             DOWNLOAD_TASK_CONFIG_COLUMN,
                                             [TTNetworkUtil getNONEmptyString:ttDTC.fileStorageDir],
                                             [TTNetworkUtil getNONEmptyString:ttDTC.urlKey],
                                             [TTNetworkUtil getNONEmptyString:ttDTC.secondUrl],
                                             [TTNetworkUtil getNONEmptyString:ttDTC.fileStorageName],
                                             [TTNetworkUtil getNONEmptyString:ttDTC.md5Value],
                                             ttDTC.sliceTotalNeedDownload,
                                             (int)ttDTC.downloadStatus];
    
    return [self executeSQL:insertOrUpdateDTCTable error:error isDisableLock:NO];
}

- (BOOL)updateDownloadSliceTaskConfig:(TTDownloadSliceTaskConfig *)ttDSTC
                   downloadTaskConfig:(TTDownloadTaskConfig *)ttDTC
                                error:(NSError **)error {
    NSString *insertOrUpdateDSTCTable = [NSString stringWithFormat:@"INSERT OR REPLACE INTO DownloadSliceTaskConfig(%@) "
                                         "VALUES ('%@',%d,'%@',%lld)",
                                         DOWNLOAD_SLICE_TASK_CONFIG_COLUMN,
                                         [TTNetworkUtil getNONEmptyString:ttDTC.fileStorageDir],
                                         ttDSTC.sliceNumber,
                                         [TTNetworkUtil getNONEmptyString:ttDSTC.sliceTempStorageName],
                                         ttDSTC.sliceTotalLength];
    
    return [self executeSQL:insertOrUpdateDSTCTable error:error isDisableLock:NO];
}

- (BOOL)updateSliceConfig:(TTDownloadSliceTaskConfig *)sliceConfig
              sliceConfig:(TTDownloadTaskConfig *)taskConfig
                    error:(NSError **)error1 {
    return [self inTransaction:^(BOOL *rollback, NSError **error) {
        NSString *sqlString = [NSString stringWithFormat:@"UPDATE DownloadSliceTaskConfig set SLICE_NAME='%@', SLICE_SIZE=%lld WHERE MAIN_URL_MD5 = '%@' AND SLICE_NUMBER = %d", [TTNetworkUtil getNONEmptyString:sliceConfig.sliceTempStorageName], sliceConfig.sliceTotalLength, [TTNetworkUtil getNONEmptyString:taskConfig.fileStorageDir], sliceConfig.sliceNumber];
        if (![self executeSQL:sqlString error:error isDisableLock:NO]) {
            *rollback = YES;
            return;
        }
    } error:error1 isDisableLock:NO];
}

- (BOOL)insertOrUpdateSubSliceInfo:(TTDownloadSubSliceInfo *)subSlice
                             error:(NSError **)error {
    DLLOGD(@"insert fileStorageDir=%@,sliceNumber=%d,subSliceNumber=%lu,subSliceName=%@,startRange=%lld,endRange=%lld,sliceStatus=%ld", subSlice.fileStorageDir, subSlice.sliceNumber, (unsigned long)subSlice.subSliceNumber, subSlice.subSliceName, subSlice.rangeStart, subSlice.rangeEnd, (long)subSlice.sliceStatus);
        
    NSString *insertOrUpdateSubSliceInfo = [NSString stringWithFormat:@"INSERT OR REPLACE INTO SubSliceInfo(%@) "
                                            "VALUES ('%@',%d,%lu,%lld,%lld,'%@',%ld,%d,%d,%d,%d,'%@','%@')",
                                            SUB_SLICE_INFO_COLUMN,
                                            [TTNetworkUtil getNONEmptyString:subSlice.fileStorageDir],
                                            subSlice.sliceNumber,
                                            subSlice.subSliceNumber,
                                            subSlice.rangeStart,
                                            subSlice.rangeEnd,
                                            [TTNetworkUtil getNONEmptyString:subSlice.subSliceName],
                                            (long)subSlice.sliceStatus,
                                            0, 0, 0, 0, [TTNetworkUtil getNONEmptyString:nil],
                                            [TTNetworkUtil getNONEmptyString:nil]];
    
    return [self executeSQL:insertOrUpdateSubSliceInfo error:error isDisableLock:NO];
}

- (BOOL)deleteSubSliceInfo:(TTDownloadTaskConfig *)downloadTaskConfig
                     error:(NSError **)error1 {
    return [self inTransaction:^(BOOL *rollback, NSError **error) {
        DLLOGD(@"delete mainUrl=%@,secondUrl=%@,fileStorageDir=%@", downloadTaskConfig.urlKey, downloadTaskConfig.secondUrl, downloadTaskConfig.fileStorageDir);
        
        NSString *deleteSubSliceInfo = [NSString stringWithFormat:@"DELETE FROM SubSliceInfo WHERE MAIN_URL_MD5 = '%@'", downloadTaskConfig.fileStorageDir];
        
        if (![self executeSQL:deleteSubSliceInfo error:error isDisableLock:NO]) {
            *rollback = YES;
            return;
        }
    } error:error1 isDisableLock:NO];
}
/**
 *Delete DownloadTaskConfig
 */
- (BOOL)deleteDownloadTaskConfigSync:(TTDownloadTaskConfig *)ttDTC
                               error:(NSError **)error1 {
    return [self inTransaction:^(BOOL *rollback, NSError **error) {
        NSString *deleteDTCTable = [NSString stringWithFormat:@"DELETE FROM DownloadTaskConfig WHERE MAIN_URL_MD5 = '%@'", ttDTC.fileStorageDir];

        NSString *deleteDSTCTable = [NSString stringWithFormat:@"DELETE FROM DownloadSliceTaskConfig WHERE MAIN_URL_MD5 = '%@'", ttDTC.fileStorageDir];
        
        NSString *deleteParametersTable = [NSString stringWithFormat:@"DELETE FROM DownloadTaskParameters WHERE MAIN_URL_MD5 = '%@'", ttDTC.fileStorageDir];
        
        NSString *deleteSubSliceRule = [NSString stringWithFormat:@"DELETE FROM SubSliceInfo WHERE MAIN_URL_MD5 = '%@'", ttDTC.fileStorageDir];

        if (![self executeSQL:deleteDTCTable error:error isDisableLock:NO]) {
            *rollback = YES;
            return;
        }

        if (![self executeSQL:deleteParametersTable error:error isDisableLock:NO]) {
            *rollback = YES;
            return;
        }

        if (![self executeSQL:deleteDSTCTable error:error isDisableLock:NO]) {
            *rollback = YES;
            return;
        }
        
        if (![self executeSQL:deleteSubSliceRule error:error isDisableLock:NO]) {
            *rollback = YES;
            return;
        }
    } error:error1 isDisableLock:NO];
}

/**
 * Delete DownloadTaskConfig on single thread. We must set isDisableLock YES to avoid dead lock,
 * because deleteDownloadTaskConfigSyncOnSingleThread is called in critical section which is locked by same lock.
 */
- (BOOL)deleteDownloadTaskConfigSyncOnSingleThread:(TTDownloadTaskConfig *)ttDTC
                                             error:(NSError **)error1 {
    return [self inTransaction:^(BOOL *rollback, NSError **error) {
        NSString *deleteDTCTable = [NSString stringWithFormat:@"DELETE FROM DownloadTaskConfig WHERE MAIN_URL_MD5 = '%@'", ttDTC.fileStorageDir];

        NSString *deleteDSTCTable = [NSString stringWithFormat:@"DELETE FROM DownloadSliceTaskConfig WHERE MAIN_URL_MD5 = '%@'", ttDTC.fileStorageDir];
        
        NSString *deleteParametersTable = [NSString stringWithFormat:@"DELETE FROM DownloadTaskParameters WHERE MAIN_URL_MD5 = '%@'", ttDTC.fileStorageDir];
        
        NSString *deleteSubSliceRule = [NSString stringWithFormat:@"DELETE FROM SubSliceInfo WHERE MAIN_URL_MD5 = '%@'", ttDTC.fileStorageDir];
        
        NSString *deleteTrackModel = [NSString stringWithFormat:@"DELETE FROM DownloadTrackModel WHERE MAIN_URL_MD5 = '%@'", ttDTC.fileStorageDir];

        if (![self executeSQL:deleteDTCTable error:error isDisableLock:YES]) {
            *rollback = YES;
            return;
        }

        if (![self executeSQL:deleteParametersTable error:error isDisableLock:YES]) {
            *rollback = YES;
            return;
        }

        if (![self executeSQL:deleteDSTCTable error:error isDisableLock:YES]) {
            *rollback = YES;
            return;
        }
        
        if (![self executeSQL:deleteSubSliceRule error:error isDisableLock:YES]) {
            *rollback = YES;
            return;
        }
        
        if (![self executeSQL:deleteTrackModel error:error isDisableLock:YES]) {
            *rollback = YES;
        }
    } error:error1 isDisableLock:YES];
}


#pragma mark - DownloadTaskParameters
- (BOOL)updateParametersTable:(TTDownloadTaskConfig *)ttDTC
                        error:(NSError **)error1 {
    NSString *parametersJson = ttDTC.userParam ? [ttDTC.userParam toJSONString] : nil;
    
    NSString *extendConfig = ttDTC.extendConfig ? [ttDTC.extendConfig toJSONString] : nil;
    
    int isSupportRange = ttDTC.isSupportRange ? 1 : 0;
    NSString *insertOrUpdateParametersTable = [NSString stringWithFormat:@"INSERT OR REPLACE INTO DownloadTaskParameters(%@) "
                                               "VALUES ('%@',%d,%d,'%@',%d,%d,%d,%d,%d,%d,'%@','%@')",
                                               DOWNLOAD_TASK_PARAMETERS_COLUMN,
                                               [TTNetworkUtil getNONEmptyString:ttDTC.fileStorageDir],
                                               ttDTC.restoreTimesAuto,
                                               ttDTC.versionType,
                                               [TTNetworkUtil getNONEmptyString:parametersJson],
                                               isSupportRange,
                                               0, 0, 0, 0, 0, [TTNetworkUtil getNONEmptyString:extendConfig],
                                               [TTNetworkUtil getNONEmptyString:nil]];
    DLLOGD(@"insertDownloadTaskConfigSync:rule=%@", insertOrUpdateParametersTable);
    return [self executeSQL:insertOrUpdateParametersTable error:error1 isDisableLock:NO];
}

#pragma mark - TTDownloadTrackModel
/**
 *Query DownloadTrackModel by urlMd5
 */
- (BOOL)queryDownloadTrackModelWithUrlMd5Sync:(NSString *)urlMd5
                     downloadTrackResultBlock:(DownloadTrackResultBlock)downloadTrackResultBlk
                                        error:(NSError **)error1 {
    NSString *queryDTM = [NSString stringWithFormat:@"SELECT %@ from DownloadTrackModel where MAIN_URL_MD5 = '%@'", DOWNLOAD_TRACK_MODEL_COLUMN, urlMd5];

    NSMutableDictionary *models = [self queryDownloadTrackModelImpl:queryDTM error:error1];

    if (models && models.count > 0) {
        TTDownloadTrackModel *model = [models objectForKey:urlMd5];
        if (model) {
            downloadTrackResultBlk(model);
            return YES;
        }
        return NO;

    } else {
        downloadTrackResultBlk(nil);
        return NO;
    }
}

/**
 * Get all of DownloadTrackTrackModel
 */
- (BOOL)queryAllDownloadTrackModelSync:(AllDownloadTrackResultBlock)allDownloadTrackResultBlk
                                 error:(NSError **)error1 {
    NSString *queryDTM = [NSString stringWithFormat:@"SELECT %@ from DownloadTrackModel", DOWNLOAD_TRACK_MODEL_COLUMN];

    NSMutableDictionary *models = [self queryDownloadTrackModelImpl:queryDTM error:error1];

    if (models && models.count > 0) {
        allDownloadTrackResultBlk(models);
        return YES;
    } else {
        allDownloadTrackResultBlk(nil);
        return NO;
    }
}

- (NSMutableDictionary *)queryDownloadTrackModelImpl:(NSString *)queryDTM
                                               error:(NSError **)error1 {
    NSMutableDictionary *ttDTMForKeyMd5 = [[NSMutableDictionary alloc] init];

    @try {
        [sqliteLock lock];
        sqlite3_stmt *stmt = nil;

        int result = sqlite3_prepare_v2(sqlite, queryDTM.UTF8String, -1, &stmt, nil);
        if (result != SQLITE_OK) {
            DLLOGD(@"downloader downloadTrackModel sqlite3_prepare error sql:%@", queryDTM);
            NSString *log = [NSString stringWithFormat:@"queryDownloadTrackModelImpl:sqlite3_prepare_v2:result=%d,", result];
            *error1 = [self makeErrorInfo:log result:result];
            return nil;
        }

        while (sqlite3_step(stmt) == SQLITE_ROW) {
            DOWNLOADER_AUTO_RELEASE_POOL_BEGIN
            NSString *modelJsonStr = [self getStringColumn:stmt index:2];
            TTDownloadTrackModel *ttDTM = [[TTDownloadTrackModel alloc] initWithString:modelJsonStr error:nil];

            if (!ttDTM) {
                continue;
            }
            if (!ttDTM.downloadId) {
                ttDTM.downloadId = [self getStringColumn:stmt index:0];
            }
            if (!ttDTM.fileStorageDir) {
                ttDTM.fileStorageDir = [self getStringColumn:stmt index:1];
            }

            if (ttDTM.fileStorageDir) {
                [ttDTMForKeyMd5 setObject:ttDTM forKey:ttDTM.fileStorageDir];
            }
            DOWNLOADER_AUTO_RELEASE_POOL_END
        }

        sqlite3_finalize(stmt);

    } @finally {
        [sqliteLock unlock];
    }

    return ttDTMForKeyMd5;
}

/**
 *Insert DownloadTrackModel
 */
- (BOOL)insertDownloadTrackModelSync:(TTDownloadTrackModel *)ttDTM
                               error:(NSError **)error1 {

    NSString *modelJsonStr = [ttDTM toJSONString];
    if (!modelJsonStr) {
        DLLOGD(@"Wrong in get model json during insert");
        return NO;
    }

    return [self inTransaction:^(BOOL *rollback, NSError **error) {
        DLLOGD(@"insert trackModel");

        NSString *insertOrUpdateDTMTable =
        [NSString stringWithFormat:@"INSERT OR REPLACE INTO DownloadTrackModel(%@) VALUES ('%@','%@','%@')",
                                                DOWNLOAD_TRACK_MODEL_COLUMN,
                                                [TTNetworkUtil getNONEmptyString:ttDTM.downloadId],
                                                [TTNetworkUtil getNONEmptyString:ttDTM.fileStorageDir],
                                                [TTNetworkUtil getNONEmptyString:modelJsonStr]];
        if (![self executeSQL:insertOrUpdateDTMTable error:error isDisableLock:NO]) {
            *rollback = YES;
            return;
        }
    } error:error1 isDisableLock:NO];
}

/**
 *Update DownloadTrackModel
 */
- (BOOL)updateDownloadTrackModelSync:(TTDownloadTrackModel *)ttDTM
                               error:(NSError **)error1 {

    NSString *modelJsonStr = [ttDTM toJSONString];
    if (!modelJsonStr) {
        DLLOGD(@"Wrong in get model json during update");
        return NO;
    }

    NSString *updateDTMTable = [NSString stringWithFormat:@"UPDATE DownloadTrackModel set TRACK_PARAM = '%@' WHERE DOWNLOAD_ID='%@' AND MAIN_URL_MD5 = '%@'",
                                [TTNetworkUtil getNONEmptyString:modelJsonStr],
                                [TTNetworkUtil getNONEmptyString:ttDTM.downloadId],
                                [TTNetworkUtil getNONEmptyString:ttDTM.fileStorageDir]];

    return [self executeSQL:updateDTMTable error:error1 isDisableLock:NO];
}

/**
 *Delete DownloadTrackModel
 */
- (BOOL)deleteDownloadTrackModelSync:(TTDownloadTrackModel *)ttDTM
                               error:(NSError **)error1 {
    return [self inTransaction:^(BOOL *rollback, NSError **error) {
        NSString *deleteDTMTable = [NSString stringWithFormat:@"DELETE FROM DownloadTrackModel WHERE DOWNLOAD_ID = '%@' AND MAIN_URL_MD5 = '%@'", ttDTM.downloadId, ttDTM.fileStorageDir];

        if (![self executeSQL:deleteDTMTable error:error isDisableLock:NO]) {
            *rollback = YES;
        }
    } error:error1 isDisableLock:NO];
}

/**
 * Delete TTDownloadTrackModel by urlMd5.
 */
- (BOOL)deleteDownloadTrackModelWithUrlMd5Sync:(NSString *)urlMd5
                                         error:(NSError **)error1 {
    return [self inTransaction:^(BOOL *rollback, NSError **error) {
        NSString *deleteDTMTable = [NSString stringWithFormat:@"DELETE FROM DownloadTrackModel WHERE MAIN_URL_MD5 = '%@'", urlMd5];

        if (![self executeSQL:deleteDTMTable error:error isDisableLock:NO]) {
            *rollback = YES;
        }
    } error:error1 isDisableLock:NO];
}

#pragma mark - SQLImpl

- (BOOL)inTransaction:(void (^)(BOOL *rollback, NSError **error))block
                error:(NSError **)error
        isDisableLock:(BOOL)isDisableLock {
    BOOL shouldRollback = NO;
    @synchronized (self) {
        NSError *error2 = nil;
        shouldRollback = ![self executeSQL:@"BEGIN;" error:&error2 isDisableLock:isDisableLock];
        if (error) {
            DLLOGD(@"error=%@", error2);
        }

        if (!shouldRollback) {
            block(&shouldRollback, error);
        }
        
        NSError *error3 = nil;
        if (shouldRollback) {
            [self executeSQL:@"ROLLBACK;" error:&error3 isDisableLock:isDisableLock];
        } else {
            [self executeSQL:@"COMMIT;" error:&error3 isDisableLock:isDisableLock];
        }
        if (error3) {
            DLLOGD(@"error=%@", error3);
        }
    }

    return !shouldRollback;
}

- (NSError *)makeErrorInfo:(NSString *)log
                    result:(int)result {
    if (!log) {
        log = @"";
    }
    NSError *error = [NSError errorWithDomain:log code:result userInfo:nil];
    DLLOGD(@"error=%@", error);
    return error;
}

- (BOOL)executeSQL:(NSString *)sql
             error:(NSError **)error
     isDisableLock:(BOOL)isDisableLock {
    BOOL ret = NO;
    char *internalError = nil;
    int8_t retryTimes = 3;
    NSString *log = nil;
    int result = 0;

    if (!isDisableLock) {
        [sqliteLock lock];
    }
    
    while (retryTimes-- > 0) {
        result = sqlite3_exec(sqlite, sql.UTF8String, nil, nil, &internalError);
        if (SQLITE_OK == result) {
            ret = YES;
            break;
        } else if (internalError) {
            if (retryTimes == 0) {
                log = [NSString stringWithFormat:@"executeSQL:sql=%@,result=%d,sqliteErrorInfo=%s", sql, result, internalError];
            }
            sqlite3_free(internalError);
        }
    }
    
    if (SQLITE_OK != result) {
        *error = [self makeErrorInfo:log result:result];
        DLLOGD(@"TTDownloadStorageCentre execute sql error:%@", log);
    }

    if (!isDisableLock) {
        [sqliteLock unlock];
    }
    return ret;
}
@end

NS_ASSUME_NONNULL_END
