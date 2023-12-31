//
//  ACCMomentMediaDataProvider.m
//  Pods
//
//  Created by Pinka on 2020/5/18.
//

#import "ACCMomentMediaDataProvider.h"

#import "ACCMomentMediaAsset+WCTTableCoding.h"
#import "ACCMomentBIMResult+WCTTableCoding.h"
#import <CreationKitInfra/NSString+ACCAdditions.h>

#import <BDWCDB/WCDB/WCDB.h>

static NSString *const ACCMomentMediaPrepareTable = @"prepare";
static NSString *const ACCMomentMediaProcessedTable = @"processed";

static NSString *const ACCMomentMediaDatabasePath = @"library.db";
static NSString *const ACCMomentMediaDatabaseNormalRecord = @"normal.log";
static NSString *const ACCMomentMediaDatabaseUpgradeRecord = @"upgrade.log";

static NSString *const ACCMomentMediaDataProviderErrorDomain = @"com.acc.moment.database";
static NSInteger const ACCMomentMediaDataProviderErrorCodeDeletePrepareTable = -10;
static NSInteger const ACCMomentMediaDataProviderErrorCodeUpdateProcessedScanDate = -11;
static NSInteger const ACCMomentMediaDataProviderErrorCodeInsertNewPrepareObj = -12;
static NSInteger const ACCMomentMediaDataProviderErrorCodeCleanProcessedTable = -13;
static NSInteger const ACCMomentMediaDataProviderErrorCodeUpdateProcessedTable = -14;
static NSInteger const ACCMomentMediaDataProviderErrorCodeCleanDidProcessedPrepareTable = -15;
static NSInteger const ACCMomentMediaDataProviderErrorCodePeopleIdsProcessedTable = -17;
static NSInteger const ACCMomentMediaDataProviderErrorCodeSimIdProcessedTable = -18;


#define ACC_MOMENT_CHECK_ERROR \
if (errorCode != 0) { \
    if (completion) { \
        dispatch_async(dispatch_get_main_queue(), ^{ \
            completion([NSError errorWithDomain:ACCMomentMediaDataProviderErrorDomain code:errorCode userInfo:nil]); \
        }); \
    } \
    return ; \
}

NSString* ACCMomentMediaRootPath(void)
{
    static dispatch_once_t onceToken;
    static NSString *dir = nil;
    dispatch_once(&onceToken, ^{
        dir = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"ACCMomentMedia"];
    });
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

static NSString* ACCMomentMediaUpgradeDatabaseLogNamePath(void)
{
    NSString *path = [ACCMomentMediaRootPath() stringByAppendingPathComponent:ACCMomentMediaDatabaseUpgradeRecord];
    return path;
}

static NSString* ACCMomentMediaUpgradeDatabaseLogName(void)
{
    NSString *name = [[NSString alloc] initWithContentsOfFile:ACCMomentMediaUpgradeDatabaseLogNamePath()
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    return name;
}

static NSString* ACCMomentMediaUpgradeDatabase(void)
{
    return [ACCMomentMediaRootPath() stringByAppendingPathComponent:ACCMomentMediaUpgradeDatabaseLogName()];
}

static NSString* ACCMomentMediaNormalDatabaseLogNamePath(void)
{
    NSString *path = [ACCMomentMediaRootPath() stringByAppendingPathComponent:ACCMomentMediaDatabaseNormalRecord];
    return path;
}

static NSString* ACCMomentMediaNormalDatabaseLogName(void)
{
    NSString *name = [[NSString alloc] initWithContentsOfFile:ACCMomentMediaNormalDatabaseLogNamePath()
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    return name;
}

static NSString* ACCMomentMediaNormalDatabase(void)
{
    return [ACCMomentMediaRootPath() stringByAppendingPathComponent:ACCMomentMediaNormalDatabaseLogName()];
}

@interface ACCMomentMediaDataProvider ()

@property (nonatomic, strong) WCTDatabase *libraryDatabase;

@property (nonatomic, strong, readwrite) dispatch_queue_t databaseQueue;

@end

@implementation ACCMomentMediaDataProvider

+ (void)initialize
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:ACCMomentMediaNormalDatabaseLogNamePath()]) {
        [ACCMomentMediaDatabasePath acc_writeToFile:ACCMomentMediaNormalDatabaseLogNamePath()
                                         atomically:YES
                                           encoding:NSUTF8StringEncoding
                                              error:nil];
    }
    
    NSString *normalName = [ACCMomentMediaNormalDatabaseLogName() stringByDeletingPathExtension];
    NSString *upgradeName = [ACCMomentMediaUpgradeDatabaseLogName() stringByDeletingPathExtension];
    for (NSString *file in [[NSFileManager defaultManager] enumeratorAtPath:ACCMomentMediaRootPath()]) {
        if ([file.pathExtension isEqualToString:@"db"] ||
            [file.pathExtension isEqualToString:@"db-shm"] ||
            [file.pathExtension isEqualToString:@"db-wal"]) {
            NSString *tmpName = [file stringByDeletingPathExtension];
            if (![tmpName isEqualToString:normalName] &&
                ![tmpName isEqualToString:upgradeName]) {
                [[NSFileManager defaultManager] removeItemAtPath:[ACCMomentMediaRootPath() stringByAppendingPathComponent:file] error:nil];
            }
        }
    }
}

- (instancetype)init
{
    NSAssert(NO, @"Can't use 'init' method!");
    return self;
}

+ (dispatch_queue_t)createTableQueue
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t createTableQueue;
    dispatch_once(&onceToken, ^{
        createTableQueue = dispatch_queue_create("com.acc.moment.database.create.table", DISPATCH_QUEUE_SERIAL);
    });
    
    return createTableQueue;
}

- (instancetype)initForNormalDatabase
{
    self = [super init];
    
    if (self) {
        _databaseQueue = dispatch_queue_create("com.acc.moment.database", DISPATCH_QUEUE_SERIAL);
        [self prepareDatabaseWithPath:ACCMomentMediaNormalDatabase()];
    }
    
    return self;
}

#pragma mark - Public API
+ (instancetype)defaultProvider
{
    static dispatch_once_t onceToken;
    static ACCMomentMediaDataProvider *instance;
    dispatch_once(&onceToken, ^{
        instance = [[ACCMomentMediaDataProvider alloc] initForNormalDatabase];
    });
    
    return instance;
}

+ (instancetype)normalProvider
{
    return [[ACCMomentMediaDataProvider alloc] initForNormalDatabase];
}

- (void)cleanAllTable
{
    dispatch_async(self.databaseQueue, ^{
        [self.libraryDatabase deleteAllObjectsFromTable:ACCMomentMediaPrepareTable];
        [self.libraryDatabase deleteAllObjectsFromTable:ACCMomentMediaProcessedTable];
    });
}

- (void)updateAsset:(ACCMomentMediaAsset *)asset
{
    dispatch_async(self.databaseQueue, ^{
        [self.libraryDatabase insertOrReplaceObject:asset into:ACCMomentMediaPrepareTable];
    });
}

- (void)updateAssetResult:(PHFetchResult<PHAsset *> *)result
                   filter:(nonnull ACCMomentMediaDataProviderUpdateAssetFilter)filter
                 scanDate:(NSUInteger)scanDate
               limitCount:(NSUInteger)limitCount
               completion:(nonnull ACCMomentMediaDataProviderCompletion)completion
{
    dispatch_async(self.databaseQueue, ^{
        NSInteger __block errorCode = 0;
        if (![self.libraryDatabase deleteAllObjectsFromTable:ACCMomentMediaPrepareTable]) {
            errorCode = ACCMomentMediaDataProviderErrorCodeDeletePrepareTable;
        }
        ACC_MOMENT_CHECK_ERROR;
        
        NSUInteger __block totalCount = 0;
        [self.libraryDatabase runTransaction:^BOOL{
            NSArray *dateObj = @[@(scanDate)];
            BOOL __block notAddNewFlag = NO;
            
            [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (filter && filter(obj) == NO) {
                    return;
                }
                
                totalCount += 1;
                if (!notAddNewFlag &&
                    limitCount > 0 &&
                    totalCount > limitCount) {
                    notAddNewFlag = YES;
                }
                
                @autoreleasepool {
                    WCTRowSelect *select = [self.libraryDatabase
                                            prepareSelectRowsOnResults:{ACCMomentBIMResult.localIdentifier, ACCMomentBIMResult.checkModDate}
                                            fromTable:ACCMomentMediaProcessedTable];
                    [select where:ACCMomentMediaAsset.localIdentifier == obj.localIdentifier];
                    
                    BOOL newFlag = NO;
                    NSArray *values = select.nextRow;
                    NSNumber *modDate = nil;
                    if (values.count == 2) {
                        if ([values[1] isKindOfClass:NSNumber.class]) {
                            modDate = values[1];
                            NSUInteger curModDate = obj.modificationDate.timeIntervalSince1970*1000;
                            if (modDate.unsignedIntegerValue != curModDate) {
                                newFlag = YES;
                            }
                        }
                    } else {
                        newFlag = YES;
                    }
                    
                    if (!newFlag) {
                        if (![self.libraryDatabase updateRowsInTable:ACCMomentMediaProcessedTable
                                                        onProperties:ACCMomentMediaAsset.scanDate
                                                             withRow:dateObj
                                                               where:ACCMomentMediaAsset.localIdentifier == obj.localIdentifier]) {
                            errorCode = ACCMomentMediaDataProviderErrorCodeUpdateProcessedScanDate;
                        }
                    } else if (newFlag && !notAddNewFlag) {
                        ACCMomentMediaAsset *asset = [[ACCMomentMediaAsset alloc] initWithPHAsset:obj];
                        asset.scanDate = scanDate;
                        if (![self.libraryDatabase insertOrReplaceObject:asset into:ACCMomentMediaPrepareTable]) {
                            errorCode = ACCMomentMediaDataProviderErrorCodeInsertNewPrepareObj;
                        }
                    }
                    
                    if (errorCode != 0) {
                        *stop = YES;
                    }
                }
            }];
            
            return (errorCode == 0);
        }];
        ACC_MOMENT_CHECK_ERROR;
        
        if (![self.libraryDatabase deleteObjectsFromTable:ACCMomentMediaProcessedTable where:ACCMomentMediaAsset.scanDate != scanDate]) {
            errorCode = ACCMomentMediaDataProviderErrorCodeCleanProcessedTable;
        }
        ACC_MOMENT_CHECK_ERROR;
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
        }
    });
}

- (void)loadPrepareAssetsWithLimit:(NSInteger)limit
                         pageIndex:(NSInteger)pageIndex
                   videoLoadConfig:(ACCMomentMediaDataProviderVideoConfig)videoLoadConfig
                       resultBlock:(nonnull void (^)(NSArray<ACCMomentMediaAsset *> * _Nullable, NSUInteger allTotalCount, BOOL, NSError * _Nullable))resultBlock
{
    dispatch_async(self.databaseQueue, ^{
        BOOL endFlag = NO;
        auto select = [self.libraryDatabase prepareSelectRowsOnResults:ACCMomentMediaAsset.localIdentifier.count() fromTable:ACCMomentMediaPrepareTable];
        NSNumber *count = (id)select.nextValue;
        if ([count isKindOfClass:NSNumber.class]) {
            if ((pageIndex+1)*limit >= count.unsignedIntegerValue) {
                endFlag = YES;
            }
        }
        
        NSArray *result = nil;
        switch (videoLoadConfig) {
            case ACCMomentMediaDataProviderVideoCofig_Default:
            {
                result =
                [self.libraryDatabase getObjectsOfClass:ACCMomentMediaAsset.class
                                              fromTable:ACCMomentMediaPrepareTable
                                                orderBy:ACCMomentMediaAsset.creationDate.order(WCTOrderedDescending)
                                                  limit:limit
                                                 offset:pageIndex*limit];
            }
                break;
                
            case ACCMomentMediaDataProviderVideoCofig_Ignore:
            {
                result =
                [self.libraryDatabase getObjectsOfClass:ACCMomentMediaAsset.class
                                              fromTable:ACCMomentMediaPrepareTable
                                                  where:ACCMomentMediaAsset.mediaType == PHAssetMediaTypeImage
                                                orderBy:ACCMomentMediaAsset.creationDate.order(WCTOrderedDescending)
                                                  limit:limit
                                                 offset:pageIndex*limit];
            }
                break;

            case ACCMomentMediaDataProviderVideoCofig_Descending:
            {
                result =
                [self.libraryDatabase getObjectsOfClass:ACCMomentMediaAsset.class
                                              fromTable:ACCMomentMediaPrepareTable
                                                orderBy:{ACCMomentBIMResult.mediaType.order(WCTOrderedAscending), ACCMomentBIMResult.creationDate.order(WCTOrderedDescending)}
                                                  limit:limit
                                                 offset:pageIndex*limit];
            }
                break;
    }
        
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(result, count.unsignedIntegerValue, endFlag, nil);
            });
        }
    });
}

- (void)cleanPrepareAssetsWithCompletion:(ACCMomentMediaDataProviderCompletion)completion
{
    dispatch_async(self.databaseQueue, ^{
        NSError *error = nil;
        if (![self.libraryDatabase deleteObjectsFromTable:ACCMomentMediaPrepareTable where:ACCMomentMediaAsset.didProcessed == YES]) {
            error = [NSError errorWithDomain:ACCMomentMediaDataProviderErrorDomain code:ACCMomentMediaDataProviderErrorCodeCleanDidProcessedPrepareTable userInfo:nil];
        }
        
        if (completion) {
            completion(error);
        }
    });
}

- (void)updateBIMResult:(NSArray<ACCMomentBIMResult *> *)result
             completion:(ACCMomentMediaDataProviderCompletion)completion
{
    dispatch_async(self.databaseQueue, ^{
        NSError __block *error = nil;
        
        [self.libraryDatabase runTransaction:^BOOL{
            auto select = [self.libraryDatabase prepareSelectRowsOnResults:ACCMomentBIMResult.uid.max() fromTable:ACCMomentMediaProcessedTable];
            NSNumber *maxUid = (id)select.nextValue;
            NSUInteger __block curUid = 0;
            if (maxUid) {
                curUid = maxUid.unsignedIntegerValue + 1;
            }
            
            [result enumerateObjectsUsingBlock:^(ACCMomentBIMResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.uid = curUid;
                [self.libraryDatabase updateRowsInTable:ACCMomentMediaPrepareTable
                                             onProperty:ACCMomentMediaAsset.didProcessed
                                              withValue:@YES
                                                  where:ACCMomentMediaAsset.localIdentifier == obj.localIdentifier];
                curUid += 1;
            }];
            
            if (result.count) {
                BOOL flag = [self.libraryDatabase insertObjects:result into:ACCMomentMediaProcessedTable];
                if (!flag) {
                    error = [NSError errorWithDomain:ACCMomentMediaDataProviderErrorDomain code:ACCMomentMediaDataProviderErrorCodeUpdateProcessedTable userInfo:nil];
                }
            }

            return YES;
        }];
        
        if (completion) {
            completion(error);
        }
    });
}

- (void)loadBIMResultToSelectObj:(void(^)(WCTSelect *select, NSError * _Nullable error))completion
{
    dispatch_async(self.databaseQueue, ^{
        WCTSelect *select = [self.libraryDatabase prepareSelectObjectsOfClass:ACCMomentBIMResult.class fromTable:ACCMomentMediaProcessedTable];
        [select orderBy:ACCMomentBIMResult.creationDate.order(WCTOrderedDescending)];
        
        if (completion) {
            completion(select, nil);
        }
    });
}

- (void)loadBIMResultWithLimit:(NSInteger)limit
                     pageIndex:(NSInteger)pageIndex
                   resultBlock:(void(^)(NSArray<ACCMomentBIMResult *> * _Nullable result, BOOL endFlag, NSError * _Nullable error))resultBlock
{
    dispatch_async(self.databaseQueue, ^{
        BOOL endFlag = NO;
        auto select = [self.libraryDatabase prepareSelectRowsOnResults:ACCMomentBIMResult.localIdentifier.count() fromTable:ACCMomentMediaProcessedTable];
        NSNumber *count = (id)select.nextValue;
        if ([count isKindOfClass:NSNumber.class]) {
            if ((pageIndex+1)*limit >= count.unsignedIntegerValue) {
                endFlag = YES;
            }
        }
        
        NSArray *result =
        [self.libraryDatabase getObjectsOfClass:ACCMomentBIMResult.class
                                      fromTable:ACCMomentMediaProcessedTable
                                        orderBy:ACCMomentBIMResult.creationDate.order(WCTOrderedDescending)
                                          limit:limit
                                         offset:pageIndex*limit];
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(result, endFlag, nil);
            });
        }
    });
}

- (void)updateCIMSimIds:(NSArray<NSNumber *> *)simIds
                bimUids:(NSArray<NSNumber *> *)bimUids
             completion:(ACCMomentMediaDataProviderCompletion)completion
{
    dispatch_async(self.databaseQueue, ^{
        NSError __block *error = nil;
        
        [self.libraryDatabase runTransaction:^BOOL{
            [self.libraryDatabase updateAllRowsInTable:ACCMomentMediaProcessedTable
                                            onProperty:ACCMomentBIMResult.simId
                                             withValue:@(-1)];
            
            long long __block maxSimId = -1;
            [bimUids enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (idx >= simIds.count) {
                    *stop = YES;
                    return;
                }
                
                if (simIds[idx].longLongValue > maxSimId) {
                    maxSimId = simIds[idx].longLongValue;
                }
                
                BOOL flag =
                [self.libraryDatabase updateRowsInTable:ACCMomentMediaProcessedTable
                                             onProperty:ACCMomentBIMResult.simId
                                              withValue:simIds[idx]
                                                  where:ACCMomentBIMResult.uid == obj.unsignedIntegerValue];
                if (!flag) {
                    error = [NSError errorWithDomain:ACCMomentMediaDataProviderErrorDomain code:ACCMomentMediaDataProviderErrorCodeSimIdProcessedTable userInfo:nil];
                }
            }];
            
            auto select = [[self.libraryDatabase prepareSelectRowsOnResults:ACCMomentBIMResult.localIdentifier
                                                                  fromTable:ACCMomentMediaProcessedTable] where:ACCMomentBIMResult.simId == -1];
            NSString *localId = nil;
            while ((localId = (id)select.nextValue)) {
                maxSimId += 1;
                [self.libraryDatabase updateRowsInTable:ACCMomentMediaProcessedTable
                                             onProperty:ACCMomentBIMResult.simId
                                              withValue:@(maxSimId)
                                                  where:ACCMomentBIMResult.localIdentifier == localId];
            }
            
            return YES;
        }];
        
        if (completion) {
            completion(error);
        }
    });
}

- (void)updateCIMPeopleIds:(NSArray<NSArray<NSNumber *> *> *)peopleIds
                   bimUids:(NSArray<NSNumber *> *)bimUids
                completion:(ACCMomentMediaDataProviderCompletion)completion
{
    dispatch_async(self.databaseQueue, ^{
        NSError __block *error = nil;
        
        [self.libraryDatabase runTransaction:^BOOL{
            [bimUids enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (idx >= peopleIds.count) {
                    *stop = YES;
                    return;
                }
                
                BOOL flag =
                [self.libraryDatabase updateRowsInTable:ACCMomentMediaProcessedTable
                                             onProperty:ACCMomentBIMResult.peopleIds
                                              withValue:peopleIds[idx]
                                                  where:ACCMomentBIMResult.uid == obj.unsignedIntegerValue];
                if (!flag) {
                    error = [NSError errorWithDomain:ACCMomentMediaDataProviderErrorDomain code:ACCMomentMediaDataProviderErrorCodePeopleIdsProcessedTable userInfo:nil];
                }
            }];
            
            return YES;
        }];
        
        if (completion) {
            completion(error);
        }
    });
}

- (void)loadLocalIdentifiersWithUids:(NSArray<NSNumber *> *)uids
                         resultBlock:(void(^)(NSDictionary<NSNumber *, NSString *> * _Nullable result, NSError * _Nullable error))resultBlock;
{
    dispatch_async(self.databaseQueue, ^{
        NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
        [uids enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *oneId = (id)[[self.libraryDatabase
                                prepareSelectRowsOnResults:ACCMomentBIMResult.localIdentifier fromTable:ACCMomentMediaProcessedTable]
                                where:ACCMomentBIMResult.uid == obj.unsignedIntValue].nextValue;
            
            if ([oneId isKindOfClass:NSString.class] && oneId.length) {
                result[obj] = oneId;
            }
        }];
        
        if (resultBlock) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resultBlock(result, nil);
            });
        }
    });
}

- (void)loadBIMWithUids:(NSArray<NSNumber *> *)uids
            resultBlock:(void(^)(NSArray<ACCMomentBIMResult *> * _Nullable results, NSError * _Nullable error))resultBlock
{
    dispatch_async(self.databaseQueue, ^{
        NSMutableArray *result = [[NSMutableArray alloc] init];
        [uids enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ACCMomentBIMResult *r =
            [self.libraryDatabase getObjectsOfClass:ACCMomentBIMResult.class
                                          fromTable:ACCMomentMediaProcessedTable
                                              where:ACCMomentBIMResult.uid == obj.unsignedIntegerValue].firstObject;
            if (r) {
                [result addObject:r];
            }
        }];
        
        if (resultBlock) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resultBlock(result, nil);
            });
        }
    });
}

- (void)loadBIMWithLocalIdentifiers:(NSArray<NSString *> *)localIdentifiers
            resultBlock:(void(^)(NSArray<ACCMomentBIMResult *> * _Nullable results, NSError * _Nullable error))resultBlock
{
    dispatch_async(self.databaseQueue, ^{
        NSMutableArray *result = [[NSMutableArray alloc] init];
        [localIdentifiers enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ACCMomentBIMResult *r =
            [self.libraryDatabase getObjectsOfClass:ACCMomentBIMResult.class
                                          fromTable:ACCMomentMediaProcessedTable
                                              where:ACCMomentBIMResult.localIdentifier == obj].firstObject;
            if (r) {
                [result addObject:r];
            }
        }];
        
        if (resultBlock) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resultBlock(result, nil);
            });
        }
    });
}

- (void)cleanBIMWhichNotExistInAssetResult:(PHFetchResult<PHAsset *> *)result
                                  scanDate:(NSUInteger)scanDate
                                completion:(ACCMomentMediaDataProviderCompletion)completion
{
    dispatch_async(self.databaseQueue, ^{
        NSInteger __block errorCode = 0;
        [self.libraryDatabase runTransaction:^BOOL{
            NSArray *dateObj = @[@(scanDate)];
            [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                @autoreleasepool {
                    WCTRowSelect *select = [self.libraryDatabase
                                            prepareSelectRowsOnResults:ACCMomentMediaAsset.localIdentifier
                                            fromTable:ACCMomentMediaProcessedTable];
                    [select where:ACCMomentMediaAsset.localIdentifier == obj.localIdentifier];
                    
                    NSArray *values = select.nextRow;
                    if (values.count > 0) {
                        if (![self.libraryDatabase updateRowsInTable:ACCMomentMediaProcessedTable
                                                        onProperties:ACCMomentMediaAsset.scanDate
                                                             withRow:dateObj
                                                               where:ACCMomentMediaAsset.localIdentifier == obj.localIdentifier]) {
                            errorCode = ACCMomentMediaDataProviderErrorCodeUpdateProcessedScanDate;
                        }
                    }
                }
            }];
            
            return (errorCode == 0);
        }];
        ACC_MOMENT_CHECK_ERROR;
        
        if (![self.libraryDatabase deleteObjectsFromTable:ACCMomentMediaProcessedTable where:ACCMomentMediaAsset.scanDate != scanDate]) {
            errorCode = ACCMomentMediaDataProviderErrorCodeCleanProcessedTable;
        }
        ACC_MOMENT_CHECK_ERROR;
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
        }
    });
}

- (void)allBIMCount:(void (^)(NSUInteger))resultBlock
{
    dispatch_async(self.databaseQueue, ^{
        auto select = [self.libraryDatabase prepareSelectRowsOnResults:ACCMomentBIMResult.localIdentifier.count() fromTable:ACCMomentMediaProcessedTable];
        NSNumber *count = (id)select.nextValue;
        NSUInteger result = 0;
        if ([count isKindOfClass:NSNumber.class]) {
            result = count.unsignedIntegerValue;
        }
        
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(result);
            });
        }
    });
}

- (void)cleanRedundancyBIMCount:(NSUInteger)count
                     completion:(ACCMomentMediaDataProviderCompletion)completion
{
    dispatch_async(self.databaseQueue, ^{
        [self.libraryDatabase runTransaction:^BOOL{
            auto select = [self.libraryDatabase prepareSelectRowsOnResults:{ACCMomentMediaAsset.localIdentifier, ACCMomentMediaAsset.creationDate}
                                                                 fromTable:ACCMomentMediaProcessedTable];
            [select orderBy:ACCMomentMediaAsset.creationDate.order(WCTOrderedDescending)];
            
            NSArray *values = nil;
            NSUInteger index = 0;
            while ((values = select.nextRow) != nil) {
                if (index < count) {
                    index += 1;
                    continue;
                }
                
                NSString *localIdentifier = values.firstObject;
                if ([localIdentifier isKindOfClass:NSString.class]) {
                    [self.libraryDatabase deleteObjectsFromTable:ACCMomentMediaProcessedTable
                                                           where:ACCMomentMediaAsset.localIdentifier == localIdentifier];
                }
            }
            
            return YES;
        }];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
        }
    });
}

+ (void)setNeedUpgradeDatabase
{
    NSString *name = [[NSUUID UUID].UUIDString stringByAppendingString:@".db"];
    [name acc_writeToFile:ACCMomentMediaUpgradeDatabaseLogNamePath()
               atomically:YES
                 encoding:NSUTF8StringEncoding
                    error:nil];
}

+ (void)completeUpgradeDatabase
{
    [[NSFileManager defaultManager] removeItemAtPath:ACCMomentMediaNormalDatabaseLogNamePath()
                                               error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:ACCMomentMediaUpgradeDatabaseLogNamePath()
                                            toPath:ACCMomentMediaNormalDatabaseLogNamePath()
                                             error:nil];
}

+ (instancetype)upgradeProvider
{
    return [[ACCMomentMediaDataProvider alloc] initForUpgradeDatabase];
}

#pragma mark - Private Methods
- (instancetype)initForUpgradeDatabase
{
    self = [super init];
    
    if (self) {
        if (ACCMomentMediaUpgradeDatabaseLogName().length) {
            _databaseQueue = dispatch_queue_create("com.acc.moment.database", DISPATCH_QUEUE_SERIAL);
            [self prepareDatabaseWithPath:ACCMomentMediaUpgradeDatabase()];
        } else {
            return nil;
        }
    }
    
    return self;
}

- (void)prepareDatabaseWithPath:(NSString *)path
{
    if (path.length) {
        dispatch_async(self.databaseQueue, ^{
            dispatch_sync([ACCMomentMediaDataProvider createTableQueue], ^{
                self.libraryDatabase = [[WCTDatabase alloc] initWithPath:path];
                [self.libraryDatabase createTableAndIndexesOfName:ACCMomentMediaPrepareTable withClass:ACCMomentMediaAsset.class];
                [self.libraryDatabase createTableAndIndexesOfName:ACCMomentMediaProcessedTable withClass:ACCMomentBIMResult.class];
            });
        });
    }
}

@end
