//
//  IESManifestManager.m
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/2/25.
//

#import "IESManifestManager.h"
#import "IESEffectRecord.h"
#import "IESAlgorithmRecord.h"
#import <EffectPlatformSDK/IESEffectModel.h>
#import <EffectPlatformSDK/IESEffectAlgorithmModel.h>
#import <EffectPlatformSDK/IESEffectUtil.h>
#import <EffectPlatformSDK/NSError+IESEffectManager.h>
#import <EffectPlatformSDK/NSFileManager+IESEffectManager.h>
#import <EffectPlatformSDK/IESEffectLogger.h>
#import <EffectPlatformSDK/IESEffectPlatformRequestManager.h>
#import <FMDB/FMDB.h>

static inline BOOL isExistsSizeTypeColumnInAlgorithmsTable(FMDatabase *db)
{
    return [db columnExists:@"size_type" inTableWithName:@"algorithms"];
}

@interface IESManifestManager ()

@property (nonatomic, strong, readwrite) IESEffectConfig *config;

// Effects records memory cache
@property (nonatomic, strong) NSMutableDictionary<NSString *, IESEffectRecord *> *effectRecords;
@property (nonatomic, strong) NSRecursiveLock *effectRecordsLock;

// Algorithms records memory cache
@property (nonatomic, strong) NSMutableDictionary<NSString *, IESAlgorithmRecord *> *algorithmRecords;
@property (nonatomic, strong) NSRecursiveLock *algorithmRecordsLock;

// builtin algorithm records
@property (nonatomic, copy) NSDictionary<NSString *, IESAlgorithmRecord *> *builtinAlgorithmRecords;

// online algorithm models.
@property (nonatomic, copy) NSDictionary<NSString *, IESEffectAlgorithmModel *> *onlineAlgorithmModels;
@property (nonatomic, strong) NSRecursiveLock *onlineAlgorithmModelsLock;
@property (nonatomic, assign, getter=isLoadingOnlineAlgorithmModels) BOOL loadingOnlineAlgorithmModels;
@property (nonatomic, strong) NSMutableArray *onlineAlgorithmModelsCallbacks;

@property (nonatomic, strong) NSCache<NSString *, NSNumber *> *checkRecordsCache;
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end

@implementation IESManifestManager

- (instancetype)initWithConfig:(IESEffectConfig *)config {
    if (self = [super init]) {
        _config = config;
        _dispatchQueue = dispatch_queue_create("com.bytedance.ies.effect-manifest-queue", DISPATCH_QUEUE_SERIAL);
        _effectRecords = [[NSMutableDictionary alloc] init];
        _effectRecordsLock = [[NSRecursiveLock alloc] init];
        _algorithmRecords = [[NSMutableDictionary alloc] init];
        _algorithmRecordsLock = [[NSRecursiveLock alloc] init];
        _onlineAlgorithmModelsLock = [[NSRecursiveLock alloc] init];
        _onlineAlgorithmModelsCallbacks = [[NSMutableArray alloc] init];
        _checkRecordsCache = [[NSCache alloc] init];
        _loadingOnlineAlgorithmModels = NO;
    }
    return self;
}

#pragma mark - Private

- (BOOL)p_createTable {
    __block BOOL result = NO;
    // Create tables
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *sql = @"CREATE TABLE IF NOT EXISTS effects (effect_md5 TEXT PRIMARY KEY, effect_id TEXT, size INTEGER, use_count INTEGER, ref_count INTEGER, last_use_time REAL, panel_name TEXT, effect_model BLOB, extra TEXT)";
        NSString *sql2 = @"CREATE TABLE IF NOT EXISTS algorithms (name TEXT PRIMARY KEY, version TEXT, md5 TEXT, size INTEGER, size_type INTEGER)";
        if ([db tableExists:@"algorithms"] && !isExistsSizeTypeColumnInAlgorithmsTable(db)) {
            sql2 = @"ALTER TABLE algorithms ADD size_type INTEGER";
        }
        BOOL success = [db executeUpdate:sql];
        BOOL success2 = [db executeUpdate:sql2];
        if (success && success2) {
            result = YES;
        } else {
            *rollback = YES;
        }
    }];
    return result;
}

- (void)p_preloadEffectList {
    @weakify(self);
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableDictionary *records = [[NSMutableDictionary alloc] init];
        NSString *sql = @"SELECT effect_md5, effect_id, panel_name, size FROM effects";
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            NSDictionary *result = [resultSet resultDictionary];
            NSString *effectMD5 = result[@"effect_md5"];
            NSString *effectIdentifier = result[@"effect_id"];
            unsigned long long size = [(NSNumber *)result[@"size"] unsignedLongLongValue];
            NSString *panelName = result[@"panel_name"];
            IESEffectRecord *effect = [[IESEffectRecord alloc] initWithEffectMD5:effectMD5
                                                                effectIdentifier:effectIdentifier
                                                                            size:size];
            if (panelName) {
                [effect updatePanelName:panelName];
            }
            if (effect.effectMD5) {
                records[effect.effectMD5] = effect;
            }
        }
        
        if (records.count > 0) {
            @strongify(self);
            [self.effectRecordsLock lock];
            [self.effectRecords addEntriesFromDictionary:records];
            [self.effectRecordsLock unlock];
        }
    }];
}

- (void)p_preloadAlgorithmsList {
    @weakify(self);
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableDictionary *records = [[NSMutableDictionary alloc] init];
        NSString *sql = @"SELECT name, version, md5, size FROM algorithms";
        if (isExistsSizeTypeColumnInAlgorithmsTable(db)) {
            sql = @"SELECT name, version, md5, size, size_type FROM algorithms";
        }
        FMResultSet *resultSet = [db executeQuery:sql];
        NSString *algorithmsDirectory = self.config.algorithmsDirectory;
        while ([resultSet next]) {
            NSDictionary *result = [resultSet resultDictionary];
            NSString *name = result[@"name"];
            NSString *version = result[@"version"];
            NSString *modelMD5 = result[@"md5"];
            NSString *filePath = [algorithmsDirectory stringByAppendingPathComponent:modelMD5];
            unsigned long long size = [(NSNumber *)result[@"size"] unsignedLongLongValue];
            id sizeTypeObj = result[@"size_type"];
            NSInteger sizeType = [sizeTypeObj isKindOfClass:[NSNull class]] ? 0 : [sizeTypeObj integerValue];
            IESAlgorithmRecord *record = [[IESAlgorithmRecord alloc] initWithName:name
                                                                          version:version
                                                                         modelMD5:modelMD5
                                                                         filePath:filePath
                                                                             size:size
                                                                         sizeType:sizeType];
            if (record.name) {
                records[record.name] = record;
            }
        }
        
        if (records.count > 0) {
            @strongify(self);
            [self.algorithmRecordsLock lock];
            [self.algorithmRecords addEntriesFromDictionary:records];
            [self.algorithmRecordsLock unlock];
        }
    }];
}

// handle response from ${domain}/model/api/arithmetics
- (void)p_handleAlgorithmListResponse:(id)dictionary error:(NSError *)error {
    // Handle server error.
    if (error || ![dictionary isKindOfClass:[NSDictionary class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loadingOnlineAlgorithmModels = NO;
            NSArray *callbacks = [self.onlineAlgorithmModelsCallbacks copy];
            [self.onlineAlgorithmModelsCallbacks removeAllObjects];
            for (ies_effect_result_block_t block in callbacks) {
                block(NO, error);
            }
        });
        return;
    }
    
    // Parse Result
    NSDictionary *parseResult = nil;
    NSMutableString *parseResultStr = [NSMutableString stringWithString:@""];
    NSDictionary *jsonObject = (NSDictionary *)dictionary;
    NSDictionary *data = jsonObject[@"data"];
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSDictionary *arithmetics = data[@"arithmetics"];
        if ([arithmetics isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *algorithmModelsDictionary = [[NSMutableDictionary alloc] init];
            [arithmetics enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[NSArray class]]) {
                    NSError *parseError = nil;
                    NSArray *algorithmsArray = [MTLJSONAdapter modelsOfClass:[IESEffectAlgorithmModel class]
                                                               fromJSONArray:(NSArray *)obj
                                                                       error:&parseError];
                    [algorithmsArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        IESEffectAlgorithmModel *algorithmModel = (IESEffectAlgorithmModel *)obj;
                        if (algorithmModel.name) {
                            algorithmModelsDictionary[algorithmModel.name] = algorithmModel;
                            [parseResultStr appendFormat:@"name:%@, version:%@, sizeType:%ld, modelMD5:%@. ", algorithmModel.name, algorithmModel.version, (long)algorithmModel.sizeType, algorithmModel.modelMD5];
                        }
                    }];
                }
            }];
            parseResult = [algorithmModelsDictionary copy];
        }
    }
    
    if (parseResult) {
        [self updateOnlineAlgorithmModels:[parseResult allValues]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loadingOnlineAlgorithmModels = NO;
            NSArray *callbacks = [self.onlineAlgorithmModelsCallbacks copy];
            [self.onlineAlgorithmModelsCallbacks removeAllObjects];
            for (ies_effect_result_block_t block in callbacks) {
                block(YES, nil);
            }
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loadingOnlineAlgorithmModels = NO;
            NSError *parseError = [NSError ieseffect_errorWithCode:40031 description:@"Parse /model/api/arithmetics response failed."];
            NSArray *callbacks = [self.onlineAlgorithmModelsCallbacks copy];
            [self.onlineAlgorithmModelsCallbacks removeAllObjects];
            for (ies_effect_result_block_t block in callbacks) {
                block(NO, parseError);
            }
        });
    }
    
    // Track load online algorithm model list event.
    BOOL success = (nil != parseResult && parseResult.count > 0);
    [[IESEffectLogger logger] logEvent:@"ep_load_online_algorithm_model" params:@{@"success": @(success), @"response": parseResultStr ?: @""}];
    [[IESEffectLogger logger] trackService:@"ep_load_online_algorithm_model_success_rate" status:success ? 1:0 extra:@{@"response": parseResultStr ?: @""}];
}

/**
 * Check exists
 */
- (BOOL)p_isEffectRecordValid:(IESEffectRecord *)effectRecord {
    if (effectRecord.effectMD5.length > 0) {
        NSString *filePath = [self.config.effectsDirectory stringByAppendingPathComponent:effectRecord.effectMD5];
        BOOL isDirectory = NO;
        BOOL isFileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        if (isFileExists && isDirectory) {
            return YES;
        }
    }
    
    return NO;
}

/**
 * Check exists and file size.
 */
- (BOOL)p_isAlgorithmRecordValid:(IESAlgorithmRecord *)algorithmRecord {
    if (algorithmRecord.filePath.length > 0) {
        BOOL isDirectory = NO;
        BOOL isFileExists = [[NSFileManager defaultManager] fileExistsAtPath:algorithmRecord.filePath isDirectory:&isDirectory];
        if (isFileExists && !isDirectory) {
            unsigned long long modelSize = 0;
            NSError *getFileSizeError = nil;
            if ([NSFileManager ieseffect_getFileSize:&modelSize filePath:algorithmRecord.filePath error:&getFileSizeError]) {
                if (algorithmRecord.size == modelSize) {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

#pragma mark - Public

- (void)setupDatabaseCompletion:(ies_effect_result_block_t)completion {
    NSString *dbPath = self.config.effectManifestPath;
    
    dispatch_async(self.dispatchQueue, ^{
        // Create database.
        FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        if (nil == dbQueue) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [NSError ieseffect_errorWithCode:40032 description:@"Open database failed."];
                    completion(NO, error);
                });
            }
            return;
        }
        self.dbQueue = dbQueue;
        
        // Create tables and preload data.
        if ([self p_createTable]) {
            [self p_preloadEffectList];
            [self p_preloadAlgorithmsList];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(YES, nil);
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(NO, nil);
                }
            });
        }
    });
}

- (void)insertEffectModel:(IESEffectModel *)effectModel
               effectSize:(unsigned long long)effectSize
                   NSData:(NSData *)effectModelData
               completion:(ies_effect_result_block_t)completion {
    if (!effectModel.md5) {
        if (completion) {
            completion(NO, nil);
        }
        return;
    }
    
    // Set memory cache.
    IESEffectRecord *record = [[IESEffectRecord alloc] initWithEffectMD5:effectModel.md5
                                                        effectIdentifier:effectModel.effectIdentifier
                                                                    size:effectSize];
    [self.effectRecordsLock lock];
    self.effectRecords[record.effectMD5] = record;
    [self.effectRecordsLock unlock];
    
    // Save to sqlite database.
    dispatch_async(self.dispatchQueue, ^{
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            BOOL result = [db executeUpdate:@"INSERT OR REPLACE INTO effects (effect_md5, effect_id, size, use_count, ref_count, last_use_time, panel_name, effect_model, extra) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                           effectModel.md5,
                           effectModel.effectIdentifier,
                           @(effectSize),
                           @0,
                           @0,
                           @0,
                           effectModel.panelName ?: @"",
                           effectModelData,
                           @""];
            NSError *error = nil;
            if (!result) {
                error = db.lastError;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(result, error);
                }
            });
        }];
    });
}

- (void)insertAlgorithmModel:(IESEffectAlgorithmModel *)model
                        size:(unsigned long long)size
                  completion:(ies_effect_result_block_t)completion {
    if (!model.name || !model.version || !model.modelMD5) {
        if (completion) {
            completion(NO, nil);
        }
        return;
    }
    
    // Set memory cache.
    NSString *filePath = [self.config.algorithmsDirectory stringByAppendingPathComponent:model.modelMD5];
    IESAlgorithmRecord *record = [[IESAlgorithmRecord alloc] initWithName:model.name
                                                                  version:model.version
                                                                 modelMD5:model.modelMD5
                                                                 filePath:filePath
                                                                     size:size
                                                                 sizeType:model.sizeType];
    [self.algorithmRecordsLock lock];
    self.algorithmRecords[record.name] = record;
    [self.algorithmRecordsLock unlock];
    
    // Save to sqlite database.
    dispatch_async(self.dispatchQueue, ^{
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            BOOL result = NO;
            if (isExistsSizeTypeColumnInAlgorithmsTable(db)) {
                result = [db executeUpdate:@"INSERT OR REPLACE INTO algorithms (name, version, md5, size, size_type) values(?, ?, ?, ?, ?)",
                          model.name, model.version, model.modelMD5, @(size), @(model.sizeType)];
            } else {
                result = [db executeUpdate:@"INSERT OR REPLACE INTO algorithms (name, version, md5, size) values(?, ?, ?, ?)",
                          model.name, model.version, model.modelMD5, @(size)];
            }
            NSError *error = nil;
            if (!result) {
                error = db.lastError;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(result, error);
                }
            });
        }];
    });
}

- (IESEffectRecord *)effectRecordForEffectMD5:(NSString *)effectMD5 {
    if (!effectMD5) {
        return nil;
    }
    
    [self.effectRecordsLock lock];
    IESEffectRecord *record = self.effectRecords[effectMD5];
    [self.effectRecordsLock unlock];
    
    if (record) {
        if ([self p_isEffectRecordValid:record]) {
            return record;
        } else {
            // ⚠️ Invalid effect record. The effect directory was deleted or broken by others. ⚠️
            [[IESEffectLogger logger] logEvent:@"effectplatform_invalid_effect_record" params:@{@"effectIdentifier": record.effectIdentifier ?: @"",
                                                                                                @"effectMD5": record.effectMD5 ?: @"",
            }];
            
            return nil;
        }
    }
    
    return record;
}

- (IESAlgorithmRecord *)downloadedAlgorithmRecordForName:(NSString *)name version:(NSString *)version traceLog:(NSMutableString * _Nullable)traceLog {
    if (!name || !version) {
        return nil;
    }
    
    [self.algorithmRecordsLock lock];
    IESAlgorithmRecord *record = self.algorithmRecords[name];
    [self.algorithmRecordsLock unlock];
    
    IESEffectLogInfo(@"obtain downloaded record(name:%@ version:%@)", name, version);
    
    if (record) {
        if ([IESEffectUtil isVersion:record.version higherOrEqualThan:version]) {
            // Check valid
            if ([self p_isAlgorithmRecordValid:record]) {
                return record;
            } else {
                // ⚠️ Invalid algorithm record. The model file was deleted or broken by others. ⚠️
                [[IESEffectLogger logger] logEvent:@"effectplatform_invalid_algorithm_record" params:@{@"name": record.name ?: @"",
                                                                                                       @"version": record.version ?: @"",
                                                                                                       @"modelMD5": record.modelMD5 ?: @"",
                                                                                                       @"sizeType": @(record.sizeType),
                }];
                IESEffectLogError(@"the size of algorithm model record is checked invalid.");
                [traceLog appendString:[NSString stringWithFormat:@"the model record is invalid with version:%@ modelMD5:%@ sizeType:%ld. ", record.version ?: @"", record.modelMD5 ?: @"", (long)record.sizeType]];
                return nil;
            }
        } else {
            [traceLog appendString:[NSString stringWithFormat:@"the version ofmodel record is lower than the user need with version:%@ modelMD5:%@ sizeType:%ld. ", record.version ?: @"", record.modelMD5 ?: @"", (long)record.sizeType]];
            IESEffectLogInfo(@"downloadedAlgorithmRecordForName with traceLog parsed modelName(name:%@ version:%@) downloaded record(name:%@ version:%@)", name, version, record.name, record.version);
            // If the downloaded model is not satifified the required version. Remove the outdated downloaded model.
            [self removeAlgorithmRecordsWithName:name completion:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    [[NSFileManager defaultManager] removeItemAtPath:record.filePath error:nil];
                    IESEffectLogInfo(@"Remove Outdated downloaded model(name: %@, version: %@) success.", record.name, record.version);
                } else {
                    IESEffectLogError(@"Remove Outdated downloaded model(name: %@, version: %@) failed with error: %@", record.name, record.version, error);
                }
            }];
            return nil;
        }
    }
    
    return record;
}

- (IESAlgorithmRecord *)downloadedAlgorithmRecrodForCheckUpdateWithName:(NSString *)name version:(NSString *)version {
    if (!name || !version) {
        return nil;
    }
    
    [self.algorithmRecordsLock lock];
    IESAlgorithmRecord *record = self.algorithmRecords[name];
    [self.algorithmRecordsLock unlock];
    
    if (!record) {
        return nil;
    }
    
    if ([IESEffectUtil isVersion:record.version higherOrEqualThan:version]) {
        //If this record model does not check valid
        NSNumber *checkRecord = [self.checkRecordsCache objectForKey:record.modelMD5];
        
        if (!checkRecord) {
            //check pass
            if ([self p_isAlgorithmRecordValid:record]) {
                //save this check record
                [self.checkRecordsCache setObject:@(record.size) forKey:record.modelMD5];
            } else {
                return nil;
            }
        }
        return record;
    } else {
        IESEffectLogInfo(@"checkUpdate parsed modelName(name:%@ version:%@) downloaded record(name:%@ version:%@)", name, version, record.name, record.version);
        // If the downloaded model is not satifified the required version. Remove the outdated downloaded model.
        [self removeAlgorithmRecordsWithName:name completion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [[NSFileManager defaultManager] removeItemAtPath:record.filePath error:nil];
                IESEffectLogInfo(@"Remove Outdated downloaded model(name: %@, version: %@) success.", record.name, record.version);
            } else {
                IESEffectLogError(@"Remove Outdated downloaded model(name: %@, version: %@) failed with error: %@", record.name, record.version, error);
            }
        }];
        return nil;
    }
    
    return record;
}

- (IESAlgorithmRecord *)builtinAlgorithmRecordForName:(NSString *)name {
    if (!name) {
        return nil;
    }
    
    return self.builtinAlgorithmRecords[name];
}

- (IESEffectAlgorithmModel *)onlineAlgorithmRecordForName:(NSString *)name {
    if (!name) {
        return nil;
    }
    
    [self.onlineAlgorithmModelsLock lock];
    IESEffectAlgorithmModel *algorithmModel = self.onlineAlgorithmModels[name];
    [self.onlineAlgorithmModelsLock unlock];
    return algorithmModel;
}

//
// Fetch builtin model list from builtin bundle ${EffectSDKResource.bundle}.
//
- (void)loadBuiltinAlgorithmRecordsWithCompletion:(ies_effect_result_block_t)completion {
    NSString *bundlePath = self.config.effectSDKResourceBundlePath;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL isDirectory = NO;
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        if ([fileManager fileExistsAtPath:bundlePath isDirectory:&isDirectory] && isDirectory) {
            NSDirectoryEnumerator *subpaths = [fileManager enumeratorAtPath:bundlePath];
            NSMutableDictionary<NSString *, IESAlgorithmRecord *> *records = [[NSMutableDictionary alloc] init];
            NSString *subpath = nil;
            while ((subpath = [subpaths nextObject])) {
                if ([subpath hasSuffix:@".model"] || [subpath hasSuffix:@".dat"]) {
                    NSString *lastPathComponent = [subpath lastPathComponent];
                    NSString *shortName = nil;
                    NSString *version = nil;
                    [IESEffectUtil parseModelFilePath:lastPathComponent completion:^(BOOL isSuccess, NSString * _Nullable shortName, NSString * _Nullable version, NSInteger sizeType) {
                        if (isSuccess && shortName.length > 0 && version.length > 0) {
                            NSString *filePath = [bundlePath stringByAppendingPathComponent:subpath];
                            IESAlgorithmRecord *record = [[IESAlgorithmRecord alloc] initWithName:shortName
                                                                                          version:version
                                                                                         modelMD5:nil
                                                                                         filePath:filePath
                                                                                             size:0
                                                                                         sizeType:sizeType];
                            records[record.name] = record;
                        }
                    }];
                }
            }
            self.builtinAlgorithmRecords = [records copy];
            
        }
        
        // Track load builtin algorithm model event.
        NSMutableString *builtinAlgorithmRecordsDesc = [[NSMutableString alloc] init];
        for (IESAlgorithmRecord *record in self.builtinAlgorithmRecords.allValues) {
            [builtinAlgorithmRecordsDesc appendFormat:@"name: %@, version: %@, sizeType: %@\n", record.name, record.version, @(record.sizeType)];
        }
        [[IESEffectLogger logger] logEvent:@"ep_load_builtin_algorithm_records" params:@{@"builtinAlgorithmRecords": builtinAlgorithmRecordsDesc ?: @""}];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    });
}

// Fetch online model list from ${domain}/model/api/arithmetics".
- (void)loadOnlineAlgorithmModelsWithCompletion:(ies_effect_result_block_t)completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) {
            [self.onlineAlgorithmModelsCallbacks addObject:completion];
        }
        
        if (self.isLoadingOnlineAlgorithmModels) {
            return;
        }
        self.loadingOnlineAlgorithmModels = YES;
        
        static NSString *path = @"/model/api/arithmetics";
        NSString *URLString = [self.config.domain stringByAppendingString:path];
        NSMutableDictionary *totalParameters = [@{} mutableCopy];
        [totalParameters addEntriesFromDictionary:[self.config commonParameters]];
        //去除如果存在的地理经纬度字段
        [totalParameters removeObjectsForKeys:@[@"longitude", @"latitude", @"city_code", @"longitude_last", @"latitude_last", @"city_code_last"]];
        NSString *tag = [self.config.effectSDKResourceBundleConfig objectForKey:@"tag"];
        if (tag.length > 0) {
            [totalParameters setObject:tag forKey:@"tag"];
        }
        totalParameters[@"status"] = self.config.downloadOnlineEnviromentModel ? @"1" : @"0";
        CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
        void (^requestCompletion) (NSError * _Nullable error, id  _Nullable result) = ^(NSError * _Nullable error, id  _Nullable result) {
            [self p_handleAlgorithmListResponse:result error:error];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self logForAlgorithmList:error startTime:startTime];
            });
        };
        IESEffectPreFetchProcessIfNeed(completion, requestCompletion)
        [[IESEffectPlatformRequestManager requestManager] requestWithURLString:URLString
                                                                    parameters:totalParameters
                                                                  headerFields:@{}
                                                                    httpMethod:@"GET"
                                                                    completion:requestCompletion];
    });
}

- (void)fetchOnlineAlgorithmModelWithModelInfos:(NSDictionary *)modelInfos
                                     completion:(nonnull void (^)(IESEffectAlgorithmModel * _Nullable, NSError * _Nullable))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static NSString *path = @"/model/api/model";
        NSString *URLString = [self.config.domain stringByAppendingString:path];
        NSMutableDictionary *totalParameters = [NSMutableDictionary dictionary];
        [totalParameters addEntriesFromDictionary:[self.config commonParameters]];
        [totalParameters addEntriesFromDictionary:modelInfos];
        totalParameters[@"status"] = self.config.downloadOnlineEnviromentModel ? @"1" : @"0";
        
        [[IESEffectPlatformRequestManager requestManager] requestWithURLString:URLString
                                                                    parameters:totalParameters
                                                                  headerFields:@{}
                                                                    httpMethod:@"GET"
                                                                    completion:^(NSError * _Nullable error, id  _Nullable result) {
            [self p_handleAlgorithmModelResponse:result error:error completion:completion];
        }];
    });
}

- (void)p_handleAlgorithmModelResponse:(id)dictionary
                                 error:(NSError *)error
                            completion:(void (^)(IESEffectAlgorithmModel * _Nullable, NSError * _Nullable))completion {
    if (error || ![dictionary isKindOfClass:[NSDictionary class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil, error);
            }
        });
        return;
    }
    
    IESEffectAlgorithmModel *onlineModel = nil;
    NSDictionary *jsonData = (NSDictionary *)dictionary;
    NSDictionary *algorithmModelData = jsonData[@"data"];
    NSError *parseError = nil;
    if ([algorithmModelData isKindOfClass:[NSDictionary class]]) {
        onlineModel = [MTLJSONAdapter modelOfClass:[IESEffectAlgorithmModel class]
                                fromJSONDictionary:algorithmModelData
                                             error:&parseError];
    }
    
    if (onlineModel && onlineModel.name.length > 0) {
        [self updateOnlineAlgorithmModels:@[onlineModel]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(onlineModel, nil);
            }
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil, parseError);
            }
        });
    }
}

- (void)updateOnlineAlgorithmModels:(NSArray<IESEffectAlgorithmModel *> *)onlineModels {
    [self.onlineAlgorithmModelsLock lock];
    NSMutableDictionary *updatedOnlineModels = [NSMutableDictionary dictionaryWithDictionary:self.onlineAlgorithmModels];
    for (IESEffectAlgorithmModel *onlineModel in onlineModels) {
        updatedOnlineModels[onlineModel.name] = onlineModel;
    }
    self.onlineAlgorithmModels = [updatedOnlineModels copy];
    [self.onlineAlgorithmModelsLock unlock];
}

- (BOOL)isOnlineAlgorithmModelsLoaded {
    [self.onlineAlgorithmModelsLock lock];
    BOOL result = self.onlineAlgorithmModels.count > 0;
    [self.onlineAlgorithmModelsLock unlock];
    return result;
}

#pragma mark - Clean

- (unsigned long long)totalSizeOfEffectsAllocated {
    __block unsigned long long totalSize = 0;
    [self.effectRecordsLock lock];
    [self.effectRecords enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESEffectRecord * _Nonnull obj, BOOL * _Nonnull stop) {
        totalSize += obj.size;
    }];
    [self.effectRecordsLock unlock];
    return totalSize;
}

- (unsigned long long)totalSizeOfEffectsAllocatedExceptWith:(NSArray<NSString *> *)panels {
    __block unsigned long long totalSize = 0;
    [self.effectRecordsLock lock];
    [self.effectRecords enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESEffectRecord * _Nonnull obj, BOOL * _Nonnull stop) {
        if (![panels containsObject:obj.panel]) {
            totalSize += obj.size;
        }
    }];
    [self.effectRecordsLock unlock];
    return totalSize;
}

- (unsigned long long)totalSizeOfAlgorithmAllocated {
    __block unsigned long long totalSize = 0;
    [self.algorithmRecordsLock lock];
    [self.algorithmRecords enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESAlgorithmRecord * _Nonnull obj, BOOL * _Nonnull stop) {
        totalSize += obj.size;
    }];
    [self.algorithmRecordsLock unlock];
    return totalSize;
}

- (void)removeAllEffectsWithCompletion:(ies_effect_result_block_t)completion {
    @weakify(self);
    dispatch_async(self.dispatchQueue, ^{
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL result = [db executeUpdate:@"DELETE FROM effects"];
            if (result) {
                @strongify(self);
                [self.effectRecordsLock lock];
                [self.effectRecords removeAllObjects];
                [self.effectRecordsLock unlock];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(YES, nil);
                    }
                });
            } else {
                *rollback = YES;
                NSError *error = db.lastError;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(NO, error);
                    }
                });
            }
        }];
    });
}

- (void)removeEffectsWithAllowUnCleanList:(NSArray<NSString *> *)uncleanList
                               completion:(void (^)(NSError * _Nullable, NSArray<NSString *> * _Nullable))completion {
    @weakify(self);
    dispatch_async(self.dispatchQueue, ^{
        [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            NSMutableArray *uncleanMD5s = [[NSMutableArray alloc] init];
            for (NSString *uncleanPanelName in uncleanList) {
                FMResultSet *resultSet = [db executeQuery:@"SELECT effect_md5 FROM effects WHERE panel_name == ?", uncleanPanelName];
                if (resultSet) {
                    while ([resultSet next]) {
                        NSDictionary *result = [resultSet resultDictionary];
                        NSString *effectMD5 = result[@"effect_md5"];
                        [uncleanMD5s addObject:effectMD5];
                    }
                }
            }
            @strongify(self);
            [self.effectRecordsLock lock];
            NSMutableArray<NSString *> *allMD5s = [NSMutableArray arrayWithArray:[self.effectRecords allKeys]];
            [self.effectRecordsLock unlock];
            
            [allMD5s removeObjectsInArray:uncleanMD5s];
            
            [self.effectRecordsLock lock];
            [self.effectRecords removeObjectsForKeys:allMD5s];
            [self.effectRecordsLock unlock];
            
            NSInteger deleteSuccessCount = 0;
            for (NSString *md5 in allMD5s) {
                BOOL result = [db executeUpdate:@"DELETE FROM effects WHERE effect_md5 == ?", md5];
                if (result) {
                    ++deleteSuccessCount;
                } else {
                    IESEffectLogError(@"delete record %@ from effects table failed with %@", md5, db.lastError);
                }
            }
            
            if (deleteSuccessCount < allMD5s.count) {
                NSError *error = [NSError ieseffect_errorWithCode:40034
                                                      description:@"delete effect records from database failed for having unclean list"];
                *rollback = YES;
                if (completion) {
                    completion(error, nil);
                }
            } else {
                if (completion) {
                    completion(nil, uncleanMD5s);
                }
            }
        }];
    });
}

- (void)removeAllEffectsNotLockedWithCompletion:(void (^)(BOOL, NSError * _Nullable, NSArray<NSString *> * _Nullable))completion {
    @weakify(self);
    dispatch_async(self.dispatchQueue, ^{
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *resultSet = [db executeQuery:@"SELECT effect_md5 FROM effects WHERE ref_count == 0"];
            if (resultSet) {
                NSMutableArray *md5s = [[NSMutableArray alloc] init];
                while ([resultSet next]) {
                    NSDictionary *result = [resultSet resultDictionary];
                    NSString *effectMD5 = result[@"effect_md5"];
                    [md5s addObject:effectMD5];
                }
                BOOL result = [db executeUpdate:@"DELETE FROM effects WHERE ref_count == 0"];
                if (result) {
                    @strongify(self);
                    [self.effectRecordsLock lock];
                    [self.effectRecords removeObjectsForKeys:md5s];
                    [self.effectRecordsLock unlock];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(YES, nil, [md5s copy]);
                        }
                    });
                } else {
                    *rollback = YES;
                    NSError *error = db.lastError;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(NO, error, nil);
                        }
                    });
                }
            } else {
                NSError *error = db.lastError;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(NO, error, nil);
                    }
                });
            }
        }];
    });
}

- (void)removeAllAlgorithmsWithCompletion:(void(^)(NSError * _Nullable error))completion {
    @weakify(self);
    dispatch_async(self.dispatchQueue, ^{
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL result = [db executeUpdate:@"DELETE FROM algorithms"];
            if (result) {
                @strongify(self);
                [self.algorithmRecordsLock lock];
                [self.algorithmRecords removeAllObjects];
                [self.algorithmRecordsLock unlock];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(nil);
                    }
                });
            } else {
                *rollback = YES;
                NSError *error = db.lastError;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(error);
                    }
                });
            }
        }];
    });
}

- (void)removeAlgorithmRecordsWithName:(NSString *)name completion:(ies_effect_result_block_t)completion {
    if (!name) {
        if (completion) {
            NSError *error = [NSError ieseffect_errorWithCode:40033 description:@"[IESManifestManager removeAlgorithmRecordsWithName:] Invalid Parameter: name"];
            completion(NO, error);
        }
        return;
    }
    
    @weakify(self);
    dispatch_async(self.dispatchQueue, ^{
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            BOOL result = [db executeUpdate:@"DELETE FROM algorithms WHERE name == ?", name];
            if (result) {
                // Remove the record from memory cache.
                @strongify(self);
                [self.algorithmRecordsLock lock];
                self.algorithmRecords[name] = nil;
                [self.algorithmRecordsLock unlock];
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(YES, nil);
                    });
                }
            } else {
                NSError *error = db.lastError;
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(NO, error);
                    });
                }
            }
        }];
    });
}

- (void)vacuumDatabaseFileWithCompletion:(ies_effect_result_block_t)completion {
    dispatch_async(self.dispatchQueue, ^{
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            BOOL result = [db executeUpdate:@"VACUUM"];
            NSError *error = nil;
            if (!result) {
                error = db.lastError;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(result, error);
                }
            });
        }];
    });
}

#pragma mark - log

// 下拉模型list打点
- (void)logForAlgorithmList:(NSError *)downloadError
                  startTime:(CFTimeInterval)startTime {
    CFAbsoluteTime duration = CFAbsoluteTimeGetCurrent() - startTime;
    NSString *errorDesc = @"";
    NSInteger isSuccess = 1;
    if (downloadError) {
        errorDesc = downloadError.description;
        isSuccess = 0;
    }
    NSDictionary *fetchParams = @{@"duration": @(duration * 1000),
                                  @"success": @(isSuccess),
                                  @"error_desc": errorDesc?:@""};
    [[IESEffectLogger logger] logEvent:@"fetch_algorithm_model_list" params:fetchParams];
}

@end

@implementation IESManifestManager (Statistic)

- (void)updateUseCountForEffect:(IESEffectModel *)effectModel byValue:(NSInteger)value {
    NSString *effectMD5 = effectModel.md5;
    if (!effectMD5) {
        return;
    }
    
    CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
    dispatch_async(self.dispatchQueue, ^{
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"UPDATE effects SET use_count = use_count + ?, last_use_time = ? WHERE effect_md5 == ?",  @(value), @(time), effectMD5];
        }];
    });
}

- (void)updateRefCountForEffect:(IESEffectModel *)effectModel byValue:(NSInteger)value {
    NSString *effectMD5 = effectModel.md5;
    if (!effectMD5) {
        return;
    }
    
    dispatch_async(self.dispatchQueue, ^{
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"UPDATE effects SET ref_count = ref_count + ? WHERE effect_md5 == ?",  @(value), effectMD5];
        }];
    });
}

@end
