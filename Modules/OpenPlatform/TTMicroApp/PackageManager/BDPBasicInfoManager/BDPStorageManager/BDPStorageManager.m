//
//  BDPStorageManager.m
//  Timor
//
//  Created by liubo on 2019/1/17.
//

#import <ECOInfra/BDPLog.h>
#import "BDPMetaInfoAccessor.h"
#import <OPFoundation/BDPModuleManager.h>
#import "BDPPackageModuleProtocol.h"
#import "BDPStorageManager.h"
#import "BDPStorageManagerSQLDefine.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/TMAKVDatabase.h>
#import <FMDB/FMDB.h>
#import <TTMicroApp/TTMicroApp-Swift.h>

// 老版本
#define DB_OLD_VERSION_FILENAME @"BDPStorageV01.db"
// 当前版本
#define DB_CUR_VERSION_FILENAME @"BDPStorageV02.db"

@interface BDPStorageManager ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, strong) FMDatabaseQueue *oldDBQueue;

@property (nonatomic, assign) BOOL usageTableExist;
@property (nonatomic, assign) BOOL usageRecordTableExist;

@end

@implementation BDPStorageManager

#pragma mark - Init

static id kSingletonInstance = nil;
+ (instancetype)sharedManager {
    @synchronized (self) {
        if (!kSingletonInstance) {
            kSingletonInstance = [[BDPStorageManager alloc] init];
        }
    }
    return kSingletonInstance;
}

+ (void)clearSharedManager {
    BDPStorageManager *manager = nil;
    @synchronized (self) {
        manager = kSingletonInstance;
        kSingletonInstance = nil;
    }
}

- (instancetype)init {
    if (self = [super init]) {
        [self buildStorageManager];
    }
    return self;
}

- (void)buildStorageManager {
    self.dbQueue = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].dbQueue;
}

#pragma mark -
- (void)clearAllTable {
    __block NSArray *bTableNames = nil;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableArray *mNames = nil;
        FMResultSet *set = [db executeQuery:@"SELECT name FROM sqlite_master WHERE type='table'"];
        while ([set next]) {
            if (!mNames) {
                mNames = [NSMutableArray array];
            }
            [mNames addObject:[set stringForColumnIndex:0]];
        }
        bTableNames = [mNames copy];
        [set close];
    }];
    if (bTableNames.count) {
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for (NSString *name in bTableNames) {
                [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@", name]];
            }
        }];
    }
}

@end


#pragma mark - 老版本数据库替换相关接口
@implementation BDPStorageManager (OldVersion)

- (void)createOldDBQueueIfNeeded {
    if (!self.oldDBQueue && [self isExistedOldVersionDB]) {
        self.oldDBQueue = [FMDatabaseQueue databaseQueueWithPath:[[[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeBase] stringByAppendingPathComponent:DB_OLD_VERSION_FILENAME]];
    }
}

- (BOOL)isExistedOldVersionDB {
    NSString *oldBDPath = [[[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeBase] stringByAppendingPathComponent:DB_OLD_VERSION_FILENAME];
    return [[NSFileManager defaultManager] fileExistsAtPath:oldBDPath];
}

- (void)removeOldVersionDB {
    if (self.oldDBQueue) {
        [self.oldDBQueue close];
        self.oldDBQueue = nil;
    }
    NSString *oldBDPath = [[[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeBase] stringByAppendingPathComponent:DB_OLD_VERSION_FILENAME];
    [[NSFileManager defaultManager] removeItemAtPath:oldBDPath error:nil];
}

- (NSArray<BDPModel *> *)queryOldInUsedModels {
    [self createOldDBQueueIfNeeded];
    __block NSArray *bModels = nil;
    [self.oldDBQueue inDatabase:^(FMDatabase *db) {
        NSMutableArray *mModels = nil;
        FMResultSet *set = [db executeQuery:OLD_SELECT_ALL_INUSED_MODEL_STATEMENT];
        while ([set next]) {
            if (!mModels) {
                mModels = [NSMutableArray array];
            }
            NSData *modelData = [set dataForColumnIndex:0];
            BDPModel *model = [BDPStorageManager appModelFromData:modelData];
            if (model) {
                [mModels addObject:model];
            }
        }
        [set close];
        bModels = [mModels copy];
    }];
    return bModels;
}

- (void)deleteOldInUsedModelWithUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return;
    }
    [self createOldDBQueueIfNeeded];
    [self.oldDBQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:OLD_DELETE_INUSED_MODEL_STATEMENT, uniqueID.identifier];
    }];
}

- (NSArray<BDPModel *> *)queryOldUpdatedModels {
    [self createOldDBQueueIfNeeded];
    __block NSArray *bModels = nil;
    [self.oldDBQueue inDatabase:^(FMDatabase *db) {
        NSMutableArray *mModels = nil;
        FMResultSet *set = [db executeQuery:OLD_SELECT_ALL_UPDATED_MODEL_STATEMENT];
        while ([set next]) {
            if (!mModels) {
                mModels = [NSMutableArray array];
            }
            NSData *modelData = [set dataForColumnIndex:0];
            BDPModel *model = [BDPStorageManager appModelFromData:modelData];
            if (model) {
                [mModels addObject:model];
            }
        }
        [set close];
        bModels = [mModels copy];
    }];
    return bModels;
}

- (void)deleteOldUpdatedModelWithUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return;
    }
    [self createOldDBQueueIfNeeded];
    [self.oldDBQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:OLD_DELETE_UPDATED_MODEL_STATEMENT, uniqueID.identifier];
    }];
}

@end


@implementation BDPStorageManager (Helper)

#pragma mark - App Model Helper
+ (BDPModel *)appModelFromData:(NSData *)modelData {
    if ([modelData length] <= 0) return nil;
    
    BDPModel *appModel = nil;
    @try {
        appModel = [NSKeyedUnarchiver unarchiveObjectWithData:modelData];
    } @catch (NSException *exception) {
        appModel = nil;
        BDPLogTagError(@"Load", @"Unarchive BDPModel Error: %@", exception);
    }
    return appModel;
}

@end
