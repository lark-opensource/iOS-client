//
//  ACCIntelligentMovieDataProvider.m
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/22.
//

#import "ACCIntelligentMovieDataProvider.h"

#import "ACCMomentMediaAsset+WCTTableCoding.h"
#import "ACCMomentBIMResult+WCTTableCoding.h"

#import <BDWCDB/WCDB/WCDB.h>

#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

static NSString *const ACCMovieMediaPrepareTable = @"prepare";
static NSString *const ACCMovieMediaProcessedTable = @"processed";

static NSString *const ACCMovieMediaDataProviderErrorDomain = @"com.acc.movie.database";
static NSInteger const ACCMovieMediaDataProviderErrorCodeDeletePrepareTable = -10;
static NSInteger const ACCMovieMediaDataProviderErrorCodeUpdateProcessedScanDate = -11;
static NSInteger const ACCMovieMediaDataProviderErrorCodeInsertNewPrepareObj = -12;
static NSInteger const ACCMovieMediaDataProviderErrorCodeCleanProcessedTable = -13;
static NSInteger const ACCMovieMediaDataProviderErrorCodeUpdateProcessedTable = -14;
static NSInteger const ACCMovieMediaDataProviderErrorCodeCleanDidProcessedPrepareTable = -15;

#define ACC_MOMENT_CHECK_ERROR \
if (errorCode != 0) { \
    if (completion) { \
        dispatch_async(dispatch_get_main_queue(), ^{ \
            completion([NSError errorWithDomain:ACCMovieMediaDataProviderErrorDomain code:errorCode userInfo:nil]); \
        }); \
    } \
    return ; \
}

static NSString* ACCMovieMediaLibraryDatabase(void)
{
    static dispatch_once_t onceToken;
    static NSString *databasePath;
    dispatch_once(&onceToken, ^{
        NSString *const curProviderVersion = @"1.0.0";
        NSString *dataDir = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"ACCMovieMedia"];
        databasePath = [dataDir stringByAppendingPathComponent:@"library.db"];
        
        NSString *prevProviderVersion = [[NSString alloc] initWithContentsOfFile:[dataDir stringByAppendingPathComponent:@"provider.ver"] encoding:NSUTF8StringEncoding error:nil];
        
        if (![prevProviderVersion isEqualToString:curProviderVersion]) {
            [[NSFileManager defaultManager] removeItemAtPath:dataDir error:nil];
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:dataDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSString *providerVersion = [dataDir stringByAppendingPathComponent:@"provider.ver"];
        [curProviderVersion writeToFile:providerVersion atomically:YES encoding:NSUTF8StringEncoding error:nil];
    });
    
    return databasePath;
}

@interface ACCIntelligentMovieDataProvider ()

@property (nonatomic, strong) WCTDatabase *libraryDatabase;
@property (nonatomic, strong, readwrite) dispatch_queue_t databaseQueue;

@end

@implementation ACCIntelligentMovieDataProvider

+ (dispatch_queue_t)createTableQueue
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t createTableQueue;
    dispatch_once(&onceToken, ^{
        createTableQueue = dispatch_queue_create("com.acc.movie.database.create.table", DISPATCH_QUEUE_SERIAL);
    });
    
    return createTableQueue;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _databaseQueue = dispatch_queue_create("com.acc.movie.database", DISPATCH_QUEUE_SERIAL);
        [self prepareDatabase];
    }
    
    return self;
}

#pragma mark - Public API

- (void)cleanAllTable
{
    dispatch_async(self.databaseQueue, ^{
        [self.libraryDatabase deleteAllObjectsFromTable:ACCMovieMediaPrepareTable];
        [self.libraryDatabase deleteAllObjectsFromTable:ACCMovieMediaProcessedTable];
    });
}

- (void)updateAssetResult:(NSArray<PHAsset *> *)result
                 scanDate:(NSUInteger)scanDate
               completion:(nonnull ACCMovieMediaDataProviderCompletion)completion
{
    dispatch_async(self.databaseQueue, ^{
        NSInteger __block errorCode = 0;
        if (![self.libraryDatabase deleteAllObjectsFromTable:ACCMovieMediaPrepareTable]) {
            errorCode = ACCMovieMediaDataProviderErrorCodeDeletePrepareTable;
        }
        ACC_MOMENT_CHECK_ERROR;
        
        [self.libraryDatabase runTransaction:^BOOL{
            NSArray *dateObj = @[@(scanDate)];
            [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                @autoreleasepool {
                    WCTRowSelect *select = [self.libraryDatabase
                                            prepareSelectRowsOnResults:{ACCMomentBIMResult.localIdentifier, ACCMomentBIMResult.checkModDate}
                                            fromTable:ACCMovieMediaProcessedTable];
                    [select where:ACCMomentMediaAsset.localIdentifier == obj.localIdentifier];
                    
                    BOOL newFlag = NO;
                    NSArray *values = select.nextRow;
                    NSNumber *modDate = nil;
                    if (values.count == 2) {
                        if ([values[1] isKindOfClass:NSNumber.class]) {
                            modDate = values[1];
                            NSUInteger curModDate = obj.modificationDate.timeIntervalSince1970 * 1000;
                            if (modDate.unsignedIntegerValue != curModDate) {
                                newFlag = YES;
                            }
                        }
                    } else {
                        newFlag = YES;
                    }
                    
                    if (newFlag) {
                        ACCMomentMediaAsset *asset = [[ACCMomentMediaAsset alloc] initWithPHAsset:obj];
                        asset.scanDate = scanDate;
                        if (![self.libraryDatabase insertOrReplaceObject:asset into:ACCMovieMediaPrepareTable]) {
                            errorCode = ACCMovieMediaDataProviderErrorCodeInsertNewPrepareObj;
                        }
                    } else {
                        if (![self.libraryDatabase updateRowsInTable:ACCMovieMediaProcessedTable
                                                        onProperties:ACCMomentMediaAsset.scanDate
                                                             withRow:dateObj
                                                               where:ACCMomentMediaAsset.localIdentifier == obj.localIdentifier]) {
                            errorCode = ACCMovieMediaDataProviderErrorCodeUpdateProcessedScanDate;
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
        
        if (![self.libraryDatabase deleteObjectsFromTable:ACCMovieMediaProcessedTable where:ACCMomentMediaAsset.scanDate != scanDate]) {
            errorCode = ACCMovieMediaDataProviderErrorCodeCleanProcessedTable;
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
                       resultBlock:(void(^)(NSArray<ACCMomentMediaAsset *> * _Nullable result,
                                            NSUInteger allTotalCount,
                                            BOOL endFlag))resultBlock
{
    dispatch_async(self.databaseQueue, ^{
        BOOL endFlag = NO;
        auto select = [self.libraryDatabase prepareSelectRowsOnResults:ACCMomentMediaAsset.localIdentifier.count() fromTable:ACCMovieMediaPrepareTable];
        NSNumber *count = (id)select.nextValue;
        if ([count isKindOfClass:NSNumber.class]) {
            if ((pageIndex + 1) * limit >= count.unsignedIntegerValue) {
                endFlag = YES;
            }
        }
        
        NSArray *result = [self.libraryDatabase getObjectsOfClass:ACCMomentMediaAsset.class
                                                        fromTable:ACCMovieMediaPrepareTable
                                                          orderBy:ACCMomentMediaAsset.creationDate.order(WCTOrderedDescending)
                                                            limit:limit
                                                           offset:(pageIndex * limit)];
        
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(result, count.unsignedIntegerValue, endFlag);
            });
        }
    });
}

- (void)cleanPrepareAssetsWithCompletion:(ACCMovieMediaDataProviderCompletion)completion
{
    dispatch_async(self.databaseQueue, ^{
        NSError *error = nil;
        if (![self.libraryDatabase deleteObjectsFromTable:ACCMovieMediaPrepareTable where:ACCMomentMediaAsset.didProcessed == YES]) {
            error = [NSError errorWithDomain:ACCMovieMediaDataProviderErrorDomain code:ACCMovieMediaDataProviderErrorCodeCleanDidProcessedPrepareTable userInfo:nil];
        }
        
        if (completion) {
            completion(error);
        }
    });
}

- (void)updateBIMResult:(NSArray<ACCMomentBIMResult *> *)result
             completion:(ACCMovieMediaDataProviderCompletion)completion
{
    dispatch_async(self.databaseQueue, ^{
        NSError __block *error = nil;
        
        @weakify(self);
        [self.libraryDatabase runTransaction:^BOOL{
            @strongify(self);
            auto select = [self.libraryDatabase prepareSelectRowsOnResults:ACCMomentBIMResult.uid.max() fromTable:ACCMovieMediaProcessedTable];
            NSNumber *maxUid = (id)select.nextValue;
            NSUInteger __block curUid = 0;
            if (maxUid) {
                curUid = maxUid.unsignedIntegerValue + 1;
            }
            
            [result enumerateObjectsUsingBlock:^(ACCMomentBIMResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.uid = curUid;
                @strongify(self);
                [self.libraryDatabase updateRowsInTable:ACCMovieMediaPrepareTable
                                             onProperty:ACCMomentMediaAsset.didProcessed
                                              withValue:@YES
                                                  where:ACCMomentMediaAsset.localIdentifier == obj.localIdentifier];
                curUid += 1;
            }];
            
            AWELogToolInfo(AWELogToolTagMoment, @"bim result to insert into DB: %@", result);
            if (result.count) {
                BOOL flag = [self.libraryDatabase insertObjects:result into:ACCMovieMediaProcessedTable];
                if (!flag) {
                    NSAssert(NO, @"BIM结果插入数据库失败，请确认原因");
                    error = [NSError errorWithDomain:ACCMovieMediaDataProviderErrorDomain code:ACCMovieMediaDataProviderErrorCodeUpdateProcessedTable userInfo:nil];
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
        WCTSelect *select = [self.libraryDatabase prepareSelectObjectsOfClass:ACCMomentBIMResult.class fromTable:ACCMovieMediaProcessedTable];
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
        auto select = [self.libraryDatabase prepareSelectRowsOnResults:ACCMomentBIMResult.localIdentifier.count() fromTable:ACCMovieMediaProcessedTable];
        NSNumber *count = (id)select.nextValue;
        if ([count isKindOfClass:NSNumber.class]) {
            if ((pageIndex+1)*limit >= count.unsignedIntegerValue) {
                endFlag = YES;
            }
        }
        
        NSArray *result =
        [self.libraryDatabase getObjectsOfClass:ACCMomentBIMResult.class
                                      fromTable:ACCMovieMediaProcessedTable
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

- (void)loadBIMWithLocalIdentifiers:(NSArray<NSString *> *)localIdentifiers
            resultBlock:(void(^)(NSArray<ACCMomentBIMResult *> * _Nullable results, NSError * _Nullable error))resultBlock
{
    dispatch_async(self.databaseQueue, ^{
        AWELogToolInfo(AWELogToolTagMoment, @"load bim with localIDs: %@", localIdentifiers);
        NSMutableArray *result = [[NSMutableArray alloc] init];
        [localIdentifiers enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ACCMomentBIMResult *r =
            [self.libraryDatabase getObjectsOfClass:ACCMomentBIMResult.class
                                          fromTable:ACCMovieMediaProcessedTable
                                              where:ACCMomentBIMResult.localIdentifier == obj].firstObject;
            AWELogToolInfo(AWELogToolTagMoment, @"bim result %@ with localID: %@", r, obj);
            if (r) {
                [result acc_addObject:r];
            }
        }];
        
        if (resultBlock) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resultBlock(result, nil);
            });
        }
    });
}

- (void)cleanBIMWhichNotExistInAssetResult:(NSArray<PHAsset *> *)result
                                  scanDate:(NSUInteger)scanDate
                                completion:(ACCMovieMediaDataProviderCompletion)completion
{
    dispatch_async(self.databaseQueue, ^{
        NSInteger __block errorCode = 0;
        [self.libraryDatabase runTransaction:^BOOL{
            NSArray *dateObj = @[@(scanDate)];
            [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                @autoreleasepool {
                    WCTRowSelect *select = [self.libraryDatabase
                                            prepareSelectRowsOnResults:ACCMomentMediaAsset.localIdentifier
                                            fromTable:ACCMovieMediaProcessedTable];
                    [select where:ACCMomentMediaAsset.localIdentifier == obj.localIdentifier];
                    
                    NSArray *values = select.nextRow;
                    if (values.count > 0) {
                        if (![self.libraryDatabase updateRowsInTable:ACCMovieMediaProcessedTable
                                                        onProperties:ACCMomentMediaAsset.scanDate
                                                             withRow:dateObj
                                                               where:ACCMomentMediaAsset.localIdentifier == obj.localIdentifier]) {
                            errorCode = ACCMovieMediaDataProviderErrorCodeUpdateProcessedScanDate;
                        }
                    }
                }
            }];
            
            return (errorCode == 0);
        }];
        ACC_MOMENT_CHECK_ERROR;
        
        if (![self.libraryDatabase deleteObjectsFromTable:ACCMovieMediaProcessedTable where:ACCMomentMediaAsset.scanDate != scanDate]) {
            errorCode = ACCMovieMediaDataProviderErrorCodeCleanProcessedTable;
        }
        ACC_MOMENT_CHECK_ERROR;
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
        }
    });
}

#pragma mark - Private Methods

- (void)prepareDatabase
{
    dispatch_async(self.databaseQueue, ^{
        dispatch_sync([ACCIntelligentMovieDataProvider createTableQueue], ^{
            self.libraryDatabase = [[WCTDatabase alloc] initWithPath:ACCMovieMediaLibraryDatabase()];
            [self.libraryDatabase createTableAndIndexesOfName:ACCMovieMediaPrepareTable withClass:ACCMomentMediaAsset.class];
            [self.libraryDatabase createTableAndIndexesOfName:ACCMovieMediaProcessedTable withClass:ACCMomentBIMResult.class];
        });
    });
}

@end
