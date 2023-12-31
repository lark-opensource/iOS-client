//
//  HMDRecordStore.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/12.
//

#import "HMDRecordStore.h"
#import "HMDStoreFMDB.h"
#import "HeimdallrUtilities.h"
#import "HMDMacro.h"
#import "HMDDynamicCall.h"
#import "HeimdallrUtilities.h"
#import "HMDUserDefaults.h"
#import "HMDALogProtocol.h"
#import "HMDStoreMemoryDB.h"
#import "HMDFileTool.h"

static NSString *const kHMDOriginalDatabaseName = @"record.db";
static NSString *const kHMDMigratedDatabaseName = @"heimdallr.db";
static NSString *const kHMDStoreErrorCodeKey = @"HMDStoreErrorCodeKey";

@interface HMDRecordStore ()
@property (nonatomic, strong, readwrite) id<HMDStoreIMP> database;
@property (nonatomic, strong, readwrite) HMDStoreMemoryDB *memoryDB;

@end
static HMDRecordStore *singletonInstance = nil;
@implementation HMDRecordStore

+ (instancetype)shared {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        singletonInstance = [[self alloc] init];
    });
    return singletonInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        singletonInstance = [super allocWithZone:zone];
    });
    return singletonInstance;
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return singletonInstance;
}

- (instancetype)init {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singletonInstance = [super init];
        if (singletonInstance) {
            // Data cache based on memory
            self.memoryDB = [[HMDStoreMemoryDB alloc] init];
            
            // Database based on disk
            NSString *heimdallrPath  = [HeimdallrUtilities heimdallrRootPath];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if(![fileManager fileExistsAtPath:heimdallrPath]) {
                hmdCheckAndCreateDirectory(heimdallrPath);
            }
            NSString *databaseName = kHMDMigratedDatabaseName;

            if ([self needMigrateHistoryData]) {
                if ([self migrateHistoryDataSyncAtFolder:heimdallrPath]) {
                    [self removeDeprecatedDatabaseAsyncAtFolder:heimdallrPath];
                } else {
                    databaseName = kHMDOriginalDatabaseName;
                }
            } else {
                [self removeDeprecatedDatabaseAsyncAtFolder:heimdallrPath];
            }
            NSString *path = [heimdallrPath stringByAppendingPathComponent:databaseName];

            HMDLog(@"[I][Heimdallr] DB Path：%@", path);
            
            [self checkDatabaseCorruptionWithPath:heimdallrPath];
            
            self.database = [[HMDStoreFMDB alloc] initWithPath:path];
            DC_OB(DC_CL(HMDDiskSpaceDistribution, sharedInstance),registerModule:,self);
        }
    });
    return singletonInstance;
}

//数据库文件大小，单位byte
- (unsigned long long)dbFileSize {
    return [self.database dbFileSize];
}

- (BOOL)migrateHistoryDataSyncAtFolder:(NSString *)folerPath {
    
    __block BOOL success = YES;
    
    NSArray *originalNames = @[@"record.db",@"record.db-shm",@"record.db-wal"];
    NSArray *migratedNames = @[@"heimdallr.db",@"heimdallr.db-shm",@"heimdallr.db-wal"];
    
    [originalNames enumerateObjectsUsingBlock:^(NSString *_Nonnull originalName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *originalFullPath = [folerPath stringByAppendingPathComponent:originalName];
        NSString *migratedFullPath = [folerPath stringByAppendingPathComponent:[migratedNames objectAtIndex:idx]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:originalFullPath]) {
            BOOL result = [[NSFileManager defaultManager] copyItemAtPath:originalFullPath toPath:migratedFullPath error:NULL];
            if (!result) {
                success = result;
                *stop = YES;
            }
        }
    }];
    
    //make sure the three files migrate successfully at the same time
    if (!success) {
        for(NSString *fileName in migratedNames) {
            NSString *fullPath = [folerPath stringByAppendingPathComponent:fileName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:fullPath error:NULL];
            }
        }
    }
    
    return success;
}

- (void)removeDeprecatedDatabaseAsyncAtFolder:(NSString *)folerPath {
    NSArray *fileNames = @[@"record.db",@"record.db-shm",@"record.db-wal"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for(NSString *fileName in fileNames) {
            NSString *fullPath = [folerPath stringByAppendingPathComponent:fileName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:fullPath error:NULL];
            }
        }
    });
}

- (BOOL)devastateDatabase {
    NSString *folderPath = [self.database.rootPath stringByDeletingLastPathComponent];
    BOOL removeSuccessed = [self devastateDatabaseWithPath:folderPath];
    return removeSuccessed;
}

- (BOOL)devastateDatabaseWithPath:(NSString *)folderPath {
    NSArray *fileNames = @[@"heimdallr.db",@"heimdallr.db-shm",@"heimdallr.db-wal"];
    BOOL removeSuccessed = YES;
    for(NSString *fileName in fileNames) {
        NSString *fullPath = [folderPath stringByAppendingPathComponent:fileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
            removeSuccessed = removeSuccessed & [[NSFileManager defaultManager] removeItemAtPath:fullPath error:NULL];
        }
    }
    // 删除DB文件成功后重新初始化一个 BGDB
    if(removeSuccessed) {
        NSString *path = [folderPath stringByAppendingPathComponent:kHMDMigratedDatabaseName];
        self.database = [[HMDStoreFMDB alloc] initWithPath:path];
    }

    return removeSuccessed;
}
    
//头条和西瓜因为线上已经放量所以需要迁移历史数据
- (BOOL)needMigrateHistoryData {
    NSString *bundleID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    if([bundleID isEqualToString:@"com.ss.iphone.article.News"]
       || [bundleID isEqualToString:@"com.ss.iphone.article.Video"]) {
        return YES;
    }
    
    return NO;
}

- (void)saveStoreErrorCode:(NSInteger)errorCode {
    [[HMDUserDefaults standardUserDefaults] setInteger:errorCode forKey:kHMDStoreErrorCodeKey];
    HMDALOG_PROTOCOL_INFO_TAG(@"HMDStore", @"DB delete error : %ld", errorCode);
}

- (void)checkDatabaseCorruptionWithPath:(NSString *)folderPath {
    if([[HMDUserDefaults standardUserDefaults] integerForKey:kHMDStoreErrorCodeKey] != 11) {
        return;
    }
    
    BOOL success = [self devastateDatabaseWithPath:folderPath];
    if (success) {
        [self saveStoreErrorCode:0];
    }
    HMDALOG_PROTOCOL_FATAL_TAG(@"HMDStore", @"Heimdallr.db has removed successfully : %d because of corruption", success);
}

#pragma - mark HMDInspectorDiskSpaceDistribution

+ (NSArray *)removableFilePaths {
    NSMutableArray *paths = [NSMutableArray new];
    NSArray *fileNames = @[@"heimdallr.db",@"heimdallr.db-shm",@"heimdallr.db-wal"];
    NSString *rootDir = [HeimdallrUtilities heimdallrRootPath];
    for (NSString *name in fileNames) {
        [paths addObject:[rootDir stringByAppendingPathComponent:name]];
    }
    return paths;
}

- (BOOL)removeFileImmediately:(NSArray *)pathArr {
    return NO;
}

@end
