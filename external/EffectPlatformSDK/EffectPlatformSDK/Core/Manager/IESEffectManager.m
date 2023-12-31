//
//  IESEffectManager.m
//  EffectPlatformSDK
//

#import <EffectPlatformSDK/IESEffectManager.h>
#import <EffectPlatformSDK/IESEffectDownloadQueue.h>
#import <EffectPlatformSDK/IESEffectCleaner.h>
#import <EffectPlatformSDK/IESManifestManager.h>
#import <EffectPlatformSDK/IESEffectUtil.h>
#import <EffectPlatformSDK/IESEffectLogger.h>
#import <EffectPlatformSDK/NSFileManager+IESEffectManager.h>
#import <EffectPlatformSDK/NSError+IESEffectManager.h>
#import <EffectPlatformSDK/IESEffectPlatformRequestManager.h>
#import "IESEffectRecord.h"
#import "IESAlgorithmRecord.h"
#import <EffectSDK_iOS/bef_effect_api.h>

static char *ieseffectmanager_resource_finder(__unused void * handle, __unused const char * dir, const char * name);

@interface IESEffectManager ()

// The shared config.
@property (nonatomic, strong, readwrite) IESEffectConfig *config;

// Manifest manager.
@property (nonatomic, strong) IESManifestManager *manifestManager;

// Effects and algorithms download(include unzip, compute size, completion check) queue.
@property (nonatomic, strong) IESEffectDownloadQueue *downloadQueue;

// Cleaner
@property (nonatomic, strong) IESEffectCleaner *cleaner;

@property (nonatomic) BOOL hasSetUp;

@end

@implementation IESEffectManager

- (instancetype)initWithConfig:(IESEffectConfig *)config {
    if (self = [super init]) {
        _config = config;
        _manifestManager = [[IESManifestManager alloc] initWithConfig:config];
        _downloadQueue = [[IESEffectDownloadQueue alloc] initWithConfig:config manifestManager:_manifestManager];
        _cleaner = [[IESEffectCleaner alloc] initWithConfig:config manifestManager:_manifestManager];
        [self registerNotifications];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)manager {
    static IESEffectManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Set the default root directory.
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *rootDirecotory = [documentsDirectory stringByAppendingPathComponent:@"com.bytedance.ies-effects"];
        
        // Get EffectSDKResource.bundle path.
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"EffectSDKResources" ofType:@"bundle"];
        
        // Get system infomation.
        NSString *systemVersion = [UIDevice currentDevice].systemVersion;
        
        // Get the application infomation.
        NSDictionary *infoDictionary = [NSBundle mainBundle].infoDictionary;
        NSString *appID = infoDictionary[@"CFBundleIdentifier"];
        NSString *appName = infoDictionary[@"CFBundleName"];
        NSString *appVersion = infoDictionary[@"CFBundleShortVersionString"];
        
        // Get the EffectSDK_iOS version.
#if !TARGET_IPHONE_SIMULATOR
        char version[10] = {0};
        bef_effect_get_sdk_version(version, sizeof(version));
        NSString *effectSDKVersion = [[NSString alloc] initWithUTF8String:version];
#else
        NSString *effectSDKVersion = nil;
#endif
        
        // Set the default domain to 'https://effect.snssdk.com'.
        // NSString *domain = @"https://effect.snssdk.com";
        
        // Create a configuration
        IESEffectConfig *config = [[IESEffectConfig alloc] init];
        config.deviceIdentifier = @"";
        config.osVersion = systemVersion;
        config.bundleIdentifier = appID;
        config.appName = appName;
        config.appVersion = appVersion;
        config.effectSDKVersion = effectSDKVersion;
        config.channel = @"App Store";
        // config.domain = domain;
        config.region = @"";
        config.rootDirectory = rootDirecotory;
        config.effectSDKResourceBundlePath = bundlePath;
        
        manager = [[IESEffectManager alloc] initWithConfig:config];
    });
    return manager;
}

#pragma mark - Setup

- (void)setUp {
    if (0 == self.config.domain.length) {
        NSAssert(NO, @"[IESEffectManager manager].config.domain is nil, that will be cause to download algorithm model failed!!");
        IESEffectLogError(@"[IESEffectManager manager].config.domain is nil!!!!");
        return;
    }
    
    if (!self.hasSetUp) {
        self.hasSetUp = YES;
        
        [[IESEffectLogger logger] logEvent:@"ep_begin_setup" params:@{@"appID": self.config.appID ?: @"",
                                                                      @"appVersion": self.config.appVersion ?: @"",
                                                                      @"effectSDKVersion": self.config.effectSDKVersion ?: @"",
                                                                      @"channel": self.config.channel ?: @"",
                                                                      @"domain": self.config.domain ?: @"",
                                                                      @"region": self.config.region ?: @"",
        }];
        
        // Initialize the directory structure.
        NSString *rootDirectory = self.config.rootDirectory;
        NSString *effectsDirectory = self.config.effectsDirectory;
        NSString *algorithmsDirectory = self.config.algorithmsDirectory;
        NSString *tmpDirectory = self.config.tmpDirectory;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirectory = NO;
        if (![fileManager fileExistsAtPath:rootDirectory isDirectory:&isDirectory]) {
            NSError *error = nil;
            if (![fileManager createDirectoryAtPath:rootDirectory
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:&error]) {
                NSString *errorDesc = [NSString stringWithFormat:@"Create rootDirectory failed. %@", error];
                [[IESEffectLogger logger] logEvent:@"ep_create_directory_structure" params:@{@"error": errorDesc ?: @""}];
            }
        }
        if (![fileManager fileExistsAtPath:effectsDirectory isDirectory:&isDirectory]) {
            NSError *error = nil;
            if (![fileManager createDirectoryAtPath:effectsDirectory
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:&error]) {
                NSString *errorDesc = [NSString stringWithFormat:@"Create effectsDirectory failed. %@", error];
                [[IESEffectLogger logger] logEvent:@"ep_create_directory_structure" params:@{@"error": errorDesc ?: @""}];
            }
        }
        if (![fileManager fileExistsAtPath:algorithmsDirectory isDirectory:&isDirectory]) {
            NSError *error = nil;
            if (![fileManager createDirectoryAtPath:algorithmsDirectory
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:&error]) {
                NSString *errorDesc = [NSString stringWithFormat:@"Create algorithmsDirectory failed. %@", error];
                [[IESEffectLogger logger] logEvent:@"ep_create_directory_structure" params:@{@"error": errorDesc ?: @""}];
            }
        }
        if (![fileManager fileExistsAtPath:tmpDirectory isDirectory:&isDirectory]) {
            NSError *error = nil;
            if (![fileManager createDirectoryAtPath:tmpDirectory
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:&error]) {
                NSString *errorDesc = [NSString stringWithFormat:@"Create tmpDirectory failed. %@", error];
                [[IESEffectLogger logger] logEvent:@"ep_create_directory_structure" params:@{@"error": errorDesc ?: @""}];
            }
        }
        
        // Set directory excluded from backup.
        // Directory with NSURLIsExcludedFromBackupKey set to YES will not backup to iCloud.
        if ([[NSFileManager defaultManager] fileExistsAtPath:rootDirectory]) {
            NSURL *rootURL = [NSURL fileURLWithPath:rootDirectory];
            NSError *error = nil;
            NSNumber *excludedFromBackupValue = nil;
            BOOL success = [rootURL getResourceValue:&excludedFromBackupValue forKey:NSURLIsExcludedFromBackupKey error:&error];
            if (success && ![excludedFromBackupValue boolValue]) {
                [rootURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
            }
        }
        
        // SetUp the manifest module.
        __weak typeof(self) weakSelf = self;
        [self.manifestManager setupDatabaseCompletion:^(BOOL success, NSError * _Nullable error) {
            __strong typeof(self) strongSelf = weakSelf;
            
            [[IESEffectLogger logger] logEvent:@"ep_setup_database_completion" params:@{@"success": @(success), @"error": error.description ?: @""}];
            [[IESEffectLogger logger] trackService:@"ep_setup_database_success_rate" status:success ? 1 : 0 extra:@{@"error": error.description ?: @""}];
            
            if (success) {
                if (strongSelf.config.enableAutoCleanCache) {
                    [strongSelf.cleaner cleanEffectsDirectoryWithPolicy:IESEffectCleanPolicyRemoveByQuota completion:nil];
                    //[strongSelf.cleaner cleanAlgorithmDirectory];
                }
            } else {
                IESEffectLogError(@"Setup manifest module failed with error: %@", error);
            }
        }];
        [self.manifestManager loadBuiltinAlgorithmRecordsWithCompletion:nil];
        
        // Clean tmp directory if autoCleanCache enabled.
        if (self.config.enableAutoCleanCache) {
            [self.cleaner cleanTmpDirectoryWithPolicy:IESEffectCleanPolicyRemoveByQuota completion:nil];
        }
    }
}

#pragma mark - Public

- (nullable NSString *)effectPathForEffectModel:(IESEffectModel *)effectModel {
    
    if (effectModel.algorithmRequirements.count > 0 || effectModel.modelNames.count > 0) {
        // 检查下载model_name模型
        NSSet<NSString *> *mergeResult = [IESEffectUtil mergeRequirements:effectModel.algorithmRequirements
                                                           withModelNames:effectModel.modelNames];
        if (![self isAlgorithmDownloaded:[mergeResult allObjects]]) {
            return nil;
        }
    }
    
    return [self effectPathForEffectMD5:effectModel.md5];
}

- (nullable NSString *)effectPathForEffectMD5:(NSString *)effectMD5 {
    if (effectMD5 && effectMD5.length > 0) {
        IESEffectRecord *record = [self.manifestManager effectRecordForEffectMD5:effectMD5];
        if (record) {
            return [self.config.effectsDirectory stringByAppendingPathComponent:record.effectMD5];
        }
    }
    
    return nil;
}

- (BOOL)isAlgorithmRequirementsDownloaded:(NSArray<NSString *> *)algorithmRequirements {
    NSSet<NSString *> *algorithmModelNames = [IESEffectUtil mergeRequirements:algorithmRequirements withModelNames:@{}];
    return [self isAlgorithmDownloaded:[algorithmModelNames allObjects]];
}

- (BOOL)isAlgorithmDownloaded:(NSArray<NSString *> *)algorithmNames {
    if (algorithmNames.count > 0) {
        __block NSInteger downloadedCount = 0;
        [algorithmNames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *name = nil;
            NSString *version = nil;
            
            BOOL haveAlgorithmRecord = [IESEffectUtil getShortNameAndVersionWithModelName:obj ?: @"" shortName:&name version:&version];
            if (haveAlgorithmRecord) {
                IESAlgorithmRecord *downloadedRecord = [self.manifestManager downloadedAlgorithmRecrodForCheckUpdateWithName:name
                                                                                                                     version:version];
                IESAlgorithmRecord *builtinRecord = [self.manifestManager builtinAlgorithmRecordForName:name];
                IESEffectAlgorithmModel *onlineModel = [self.manifestManager onlineAlgorithmRecordForName:name];
                if (downloadedRecord || builtinRecord) {
                    if (onlineModel) {
                        if (downloadedRecord) {
                            if ([IESEffectUtil compareOnlineModel:onlineModel withBaseRecord:downloadedRecord]) {
                                // If the online model is newer than the downloaded model.
                                // [[IESEffectLogger logger] logMessage:@"The online model is newer than the downloaded model."];
                            } else {
                                downloadedCount++;
                            }
                        } else {
                            if ([IESEffectUtil compareOnlineModel:onlineModel withBaseRecord:builtinRecord]) {
                                // If the online model is newer than the builtin model.
                                // [[IESEffectLogger logger] logMessage:@"The online model is newer than the builtin model."];
                            } else {
                                downloadedCount++;
                            }
                        }
                    } else {
                        downloadedCount++;
                    }
                }
            }
        }];
        return algorithmNames.count == downloadedCount;
    }
    
    return YES;
}

- (void)downloadEffect:(IESEffectModel *)effect
              progress:(void (^)(CGFloat))progress
            completion:(void (^)(NSString * _Nonnull, NSError * _Nonnull))completion {
    [self downloadEffect:effect
   downloadQueuePriority:NSOperationQueuePriorityNormal
downloadQualityOfService:NSQualityOfServiceDefault
                progress:progress
              completion:completion];
}

- (void)downloadEffect:(IESEffectModel *)effect
 downloadQueuePriority:(NSOperationQueuePriority)queuePriority
downloadQualityOfService:(NSQualityOfService)qualityOfService
              progress:(void (^ __nullable)(CGFloat progress))progress
            completion:(void (^ __nullable)(NSString *path, NSError *error))completion
{
    [self downloadEffect:effect downloadRequirements:YES downloadQueuePriority:queuePriority downloadQualityOfService:qualityOfService progress:progress completion:completion];
}

- (void)downloadEffect:(IESEffectModel *)effect
  downloadRequirements:(BOOL)downloadRequirements
 downloadQueuePriority:(NSOperationQueuePriority)queuePriority
downloadQualityOfService:(NSQualityOfService)qualityOfService
              progress:(void (^)(CGFloat))progress
            completion:(void (^)(NSString *, NSError *))completion {
    IESEffectLogDebug(@"download Effect:%@", effect.effectName ?:@"");
    if ([effect checkAlgorithmRelatedFieldsDecryptFailed]) {
        IESEffectLogError(@"download effect failed by decrypt failed with %@ %@.", effect.effectName, effect.effectIdentifier);
        if (completion) {
            NSError *error = [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain code:IESEffectErrorDecryptFailed userInfo:nil];
            completion(nil, error);
        }
        return;
    }
    
    if (downloadRequirements && (effect.algorithmRequirements.count > 0 || effect.modelNames.count > 0)) {
        @weakify(self);
        void (^fetchOnlineAlgorithmModelListCompletion)(BOOL success, NSError * _Nonnull error) = ^(BOOL success, NSError * _Nonnull error) {
            if (success) {
                @strongify(self);
                [self downloadEffect:effect
                downloadRequirements:NO
               downloadQueuePriority:queuePriority
            downloadQualityOfService:qualityOfService
                            progress:progress
                          completion:completion];
            } else {
                if (completion) {
                    completion(nil, error);
                }
            }
        };
        IESEffectPreFetchProcessIfNeed(completion, fetchOnlineAlgorithmModelListCompletion)
        [self fetchResourcesWithRequirements:effect.algorithmRequirements
                                  modelNames:effect.modelNames
                                  completion:fetchOnlineAlgorithmModelListCompletion];
    } else {
        NSString *destination = [self.config.effectsDirectory stringByAppendingPathComponent:effect.md5];
        IESEffectRecord *record = [self.manifestManager effectRecordForEffectMD5:effect.md5];
        if (record) {
            IESEffectLogDebug(@"download Effect: already have the effect");
            if (completion) {
                completion(destination, nil);
            }
            return;
        }
        
        CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
        
        // Write applog for begin download effect.
        [[IESEffectLogger logger] logEvent:@"ep_start_download_effect_model" params:@{@"effectName": effect.effectName ?: @"",
                                                                                      @"effectIdentifier": effect.effectIdentifier ?: @"",
                                                                                      @"effectMD5": effect.md5 ?: @"",
                                                                                      @"effectSDKVersion": self.config.effectSDKVersion?:@"",
        }];
        
        @weakify(self);
        void (^downloadCompletion)(BOOL success, NSError * _Nullable error, NSString * _Nonnull traceLog) = ^(BOOL success, NSError * _Nullable error, NSString * _Nonnull traceLog) {
            @strongify(self);
            CFAbsoluteTime duration = CFAbsoluteTimeGetCurrent() - begin;
            
            // Write applog for finish downloading effect.
            [[IESEffectLogger logger] logEvent:@"ep_end_download_effect_model" params:@{@"effectName": effect.effectName ?: @"",
                                                                                        @"effectIdentifier": effect.effectIdentifier ?: @"",
                                                                                        @"effectMD5": effect.md5 ?: @"",
                                                                                        @"effectSDKVersion": self.config.effectSDKVersion?:@"",
                                                                                        @"success": @(success),
                                                                                        @"duration": @(duration * 1000),
                                                                                        @"error_desc": error.description ?: @"",
            }];
            
            // Add monitor for downloading effect.
            NSString *name = [NSString stringWithFormat:@"effectName: %@, effectIdentifier: %@, md5: %@, fileDownloadURLs: %@", effect.effectName, effect.effectIdentifier, effect.md5, effect.fileDownloadURLs];
            NSMutableDictionary *extra = [[NSMutableDictionary alloc] init];
            extra[@"product_name"] = name ?: @"";
            extra[@"effect_download_time"] = @(duration * 1000);
            if (!success && error) {
                extra[@"monitor_trace"] = traceLog;
                extra[@"error_domain"] = error.domain ?: @"";
                extra[@"error_code"] = @(error.code);
                extra[@"error_desc"] = error.description ?: @"";
                IESEffectLogDebug(@"download Effect: failed, error = %@", error.description);
            }
            IESEffectLogInfo(@"%@ effect download result: %@ with error:%@", name, @(success ? 0 : 1), error.description ?: @"");
            [[IESEffectLogger logger] trackService:@"service_effect_download_error_rate" status:success ? 0 : 1 extra:extra.copy];
            extra[@"status"] = @(success ? 0 : 1);
            [[IESEffectLogger logger] logEvent:@"effect_model_download_success_rate" params:extra.copy];
            if (completion) {
                completion(success ? destination : nil, error);
            }
        };
        IESEffectPreFetchProcessIfNeed(completion, downloadCompletion)
        [self.downloadQueue downloadEffectModel:effect
                          downloadQueuePriority:queuePriority
                       downloadQualityOfService:qualityOfService
                                       progress:progress
                                     completion:downloadCompletion];
    }
}



- (void)downloadRequirements:(NSArray<NSString *> *)requirements completion:(void (^)(BOOL, NSError *))completion {
    [self fetchResourcesWithRequirements:requirements modelNames:@{} completion:completion];
}

- (void)fetchResourcesWithRequirements:(NSArray<NSString *> *)requirements
                            modelNames:(NSDictionary<NSString *, NSArray<NSString *> *> *)modelNames
                            completion:(void (^)(BOOL, NSError *))completion {
    NSParameterAssert(requirements.count > 0 || modelNames.count > 0);
    if (requirements.count == 0 && modelNames.count == 0) {
        IESEffectLogDebug(@"fetch: requirements and modelNames are both empty");
        if (completion) {
            completion(NO, nil);
        }
        return;
    }
    
    if (![self.manifestManager isOnlineAlgorithmModelsLoaded]) {
        @weakify(self);
        void(^loadOnlineAlgorithmModelsCompletion)(BOOL success, NSError * _Nullable error) = ^(BOOL success, NSError * _Nullable error) {
            if (success) {
                @strongify(self);
                [self fetchResourcesWithRequirements:requirements modelNames:modelNames completion:completion];
            } else {
                IESEffectLogError(@"load online algorithmModel List failed: %@ in fetchResource method", error.description ?: @"");
                if (completion) {
                    completion(NO, error);
                }
            }
        };
        IESEffectPreFetchProcessIfNeed(completion, loadOnlineAlgorithmModelsCompletion)
        [self.manifestManager loadOnlineAlgorithmModelsWithCompletion:loadOnlineAlgorithmModelsCompletion];
        return;
    }
    
    //the algorithmModelNames merged by requirements and modelNames
    NSSet<NSString *> *mergedModelNames = [IESEffectUtil mergeRequirements:requirements withModelNames:modelNames];
    
    [self fetchOnlineInfosAndResourcesWithModelNames:[mergedModelNames allObjects]
                                               extra:@{}
                                          completion:completion];
}

- (void)fetchOnlineInfosAndResourcesWithModelNames:(NSArray<NSString *> *)modelNames
                                             extra:(NSDictionary *)parameters
                                        completion:(void (^)(BOOL, NSError *))completion {
    if (modelNames.count == 0) {
        IESEffectLogInfo(@"the set of modelNames is empty");
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    IESEffectLogInfo(@"the parameters for fetching infos and resources are %@", parameters.description);
    NSMutableString *modelNamesNeedDownload = [[NSMutableString alloc] init];
    
    NSMutableArray<IESEffectAlgorithmModel *> *modelsNeedDownload = [[NSMutableArray alloc] init];
    NSMutableArray<NSDictionary *> *modelInfosNeedFetch = [[NSMutableArray alloc] init];

    //enumerate modelName
    [modelNames enumerateObjectsUsingBlock:^(NSString * _Nonnull modelName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *name = nil;
        NSString *version = nil;
        [IESEffectUtil getShortNameAndVersionWithModelName:modelName shortName:&name version:&version];
        NSString *bigVersion = [[version componentsSeparatedByString:@"."] firstObject];
        
        IESAlgorithmRecord *downloadedRecord = [self.manifestManager downloadedAlgorithmRecordForName:name
                                                                                              version:version traceLog:nil];
        IESAlgorithmRecord *builtinRecord    = [self.manifestManager builtinAlgorithmRecordForName:name];
        IESEffectAlgorithmModel *onlineModel = [self.manifestManager onlineAlgorithmRecordForName:name];//default online model list
        
        IESAlgorithmRecord *record = downloadedRecord;
        if (!downloadedRecord && builtinRecord) {
            record = builtinRecord;
        }
        IESEffectLogInfo(@"parsed name:%@ version:%@", name, version);
        IESEffectLogInfo(@"downloaded record version:%@ sizeType:%ld, builtin record version: %@", downloadedRecord.version, (long)downloadedRecord.sizeType, builtinRecord.version);
        IESEffectLogInfo(@"online model version:%@, sizeType:%ld", onlineModel.version, (long)onlineModel.sizeType);
        
        if (record) {
            //the assigned model is in the default online model list and it is changed
            if (onlineModel) {
                NSAssert(![IESEffectUtil isVersion:version higherThan:onlineModel.version], @"the version of online model is lower than the parsed version");
                if ([IESEffectUtil compareOnlineModel:onlineModel withBaseRecord:record]) {
                    [modelNamesNeedDownload appendFormat:@"%@, ", modelName];
                    [modelsNeedDownload addObject:onlineModel];
                }
            } else {
                IESEffectLogInfo(@"record is not empty but online model is empty");
                //the version of assigned model name is higher than the version of the local record
                if ([IESEffectUtil isVersion:version higherThan:record.version]) {
                    IESEffectLogInfo(@"the parsed version is higher than the version of record");
                    NSMutableDictionary *modelInfos = [NSMutableDictionary dictionaryWithDictionary:parameters];
                    modelInfos[@"name"] = name;
                    if (bigVersion.integerValue > 0) {
                        modelInfos[@"big_version"] = bigVersion;
                    }
                    [modelInfosNeedFetch addObject:modelInfos];
                }
            }
        } else {
            // If the version of online model in the default online model list is higher or equal than the parsed version
            if (onlineModel) {
                NSAssert(![IESEffectUtil isVersion:version higherThan:onlineModel.version], @"the version of online model is lower than the parsed version");
                [modelNamesNeedDownload appendFormat:@"%@, ", modelName];
                [modelsNeedDownload addObject:onlineModel];
            } else {
                IESEffectLogInfo(@"online model is empty, %@ needs fetch infos", modelName);
                NSMutableDictionary *modelInfos = [NSMutableDictionary dictionaryWithDictionary:parameters];
                modelInfos[@"name"] = name;
                if (bigVersion.integerValue > 0) {
                    modelInfos[@"big_version"] = bigVersion;
                }
                [modelInfosNeedFetch addObject:modelInfos];
            }
        }
    }];
    
    IESEffectLogInfo(@"modelNams need download:%@", modelNamesNeedDownload);
    
    __block NSInteger successFetchCount = 0;
    dispatch_group_t group = dispatch_group_create();
    
    for (NSDictionary *modelInfos in modelInfosNeedFetch) {
        dispatch_group_enter(group);
        [self.manifestManager fetchOnlineAlgorithmModelWithModelInfos:modelInfos
                                                           completion:^(IESEffectAlgorithmModel * _Nullable algorithmModel, NSError * _Nullable error) {
            if (algorithmModel) {
                IESEffectLogInfo(@"fetch assigned model %@ success", algorithmModel);
                @synchronized (modelsNeedDownload) {
                    [modelsNeedDownload addObject:algorithmModel];
                }
                ++successFetchCount;
            } else {
                IESEffectLogError(@"assigned model (name:%@) is not in the online model list and fetching its info with error: %@", modelInfos[@"name"], error);
            }
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (successFetchCount == modelInfosNeedFetch.count) {
            IESEffectLogInfo(@"fetch model infos success or no model needs to fetch infos");
            [self fetchResourcesWithAlgorithmModels:modelsNeedDownload completion:completion];
        } else {
            IESEffectLogError(@"some models fetch infos error");
            NSError *error = [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain code:IESEffectErrorModelInfosFetchFailed userInfo:nil];
            if (completion) {
                completion(NO, error);
            }
        }
    });
}

- (void)fetchResourcesWithAlgorithmModels:(NSArray<IESEffectAlgorithmModel *> *)modelsNeedDownload
                               completion:(void (^)(BOOL, NSError *))completion {
    if (modelsNeedDownload.count > 0) {
        __block NSInteger successCount = 0;
        dispatch_group_t group = dispatch_group_create();
        for (IESEffectAlgorithmModel *model in modelsNeedDownload) {
            dispatch_group_enter(group);
            CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
            
            NSDictionary *startDownloadParams = @{@"modelName":model.name ?: @"",
                                                  @"modelVersion":model.version ?: @"",
                                                  @"modelMD5":model.modelMD5 ?: @"",
                                                  @"sizeType": @(model.sizeType),
                                                  @"effectSDKVersion":self.config.effectSDKVersion ?: @""};
            [[IESEffectLogger logger] logEvent:@"ep_start_download_algorithm_model" params:startDownloadParams];
            @weakify(self);
            void (^downloadAlgorithmModelCompletion)(BOOL success, NSError * _Nullable error, NSString * _Nonnull traceLog) = ^(BOOL success, NSError * _Nullable error, NSString * _Nonnull traceLog) {
                @strongify(self);
                CFAbsoluteTime duration = CFAbsoluteTimeGetCurrent() - begin;
                
                // Write applog for end downloading algorithm model.
                [[IESEffectLogger logger] logEvent:@"ep_end_download_algorithm_model" params:@{@"modelName": model.name ?: @"",
                                                                                               @"modelVersion": model.version ?: @"",
                                                                                               @"modelMD5": model.modelMD5 ?: @"",
                                                                                               @"sizeType": @(model.sizeType),
                                                                                               @"effectSDKVersion": self.config.effectSDKVersion ?: @"",
                                                                                               @"success": @(success),
                                                                                               @"duration": @(duration * 1000),
                                                                                               @"error_desc": error.description ?: @"",
                }];
                
                // Monitor algorithm model download success rate and duration if success.
                NSString *name = [NSString stringWithFormat:@"name: %@, version: %@, md5: %@, fileDownloadURLs: %@", model.name, model.version, model.modelMD5, model.fileDownloadURLs];
                NSMutableDictionary *extra = [[NSMutableDictionary alloc] init];
                extra[@"product_name"] = name ?: @"";
                extra[@"model_download_time"] = @(duration * 1000);
                if (!success && error) {
                    extra[@"monitor_trace"] = traceLog;
                    extra[@"error_domain"] = error.domain ?: @"";
                    extra[@"error_code"] = @(error.code);
                    extra[@"error_desc"] = error.description ?: @"";
                    IESEffectLogDebug(@"fetch: (%@) model download failed, error = %@", name, error.description);
                }
                IESEffectLogInfo(@"%@ model download result: %d with error: %@", name, success ? 0 : 1, error.description ?: @"");
                [[IESEffectLogger logger] trackService:@"service_model_download_error_rate" status:success ? 0 : 1 extra:extra.copy];
                extra[@"status"] = @(success ? 0 : 1);
                [[IESEffectLogger logger] logEvent:@"algorithm_model_download_success_rate" params:extra.copy];
                if (success) {
                    IESEffectLogDebug(@"fetch: (%@) model download success", name);
                    successCount++;
                }
                dispatch_group_leave(group);
            };
            IESEffectPreFetchProcessIfNeed(completion, downloadAlgorithmModelCompletion)
            [self.downloadQueue downloadAlgorithmModel:model
                                              progress:nil
                                            completion:downloadAlgorithmModelCompletion];
        }
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (completion) {
                if (successCount == modelsNeedDownload.count) {
                    IESEffectLogDebug(@"fetch: all models download success");
                    completion(YES, nil);
                } else {
                    IESEffectLogDebug(@"fetch: some models download failed");
                    NSError *error = [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain code:IESEffectErrorModelsDownloadFailed userInfo:nil];
                    completion(NO, error);
                }
            }
        });
    } else {
        IESEffectLogDebug(@"fetch: no model need to download");
        if (completion) {
            completion(YES, nil);
        }
    }
}

- (NSDictionary<NSString *, IESAlgorithmRecord *> *)checkoutModelInfosWithRequirements:(NSArray<NSString *> *)requirements
                                                                            modelNames:(NSDictionary<NSString *, NSArray<NSString *> *> *)modelNames {
    NSMutableDictionary *modelInfos = [NSMutableDictionary dictionary];
    NSSet<NSString *> *mergedModelNames = [IESEffectUtil mergeRequirements:requirements withModelNames:modelNames];
    
    [mergedModelNames enumerateObjectsUsingBlock:^(NSString * _Nonnull modelName, BOOL * _Nonnull stop) {
        IESAlgorithmRecord *record = [self algorithmPathForAlgorithmName:modelName traceLog:nil];
        if (record != nil) {
            [modelInfos setValue:record forKey:modelName];
        }
    }];
    return [modelInfos copy];
}

- (ieseffectmanager_resource_finder_t)getResourceFinder {
    return ieseffectmanager_resource_finder;
}

#pragma mark - private
- (IESAlgorithmRecord *)algorithmPathForAlgorithmName:(NSString *)modelName traceLog:(NSMutableString *)traceLog {
    NSString *name = nil;
    NSString *version = nil;
    BOOL haveAlgorithmRecord = [IESEffectUtil getShortNameAndVersionWithModelName:modelName ?: @""
                                                                        shortName:&name
                                                                          version:&version];
    [traceLog appendString:[NSString stringWithFormat:@"parse name: %@ and version: %@. ", name, version]];
    if (haveAlgorithmRecord) {
        
        IESAlgorithmRecord *algorithmRecord = nil;
        
        // If there is a downloaded algorithm model which version is higher or equal than the demand.
        // Use the downloaded model.
        algorithmRecord = [self.manifestManager downloadedAlgorithmRecordForName:name version:version traceLog:traceLog];
        [traceLog appendString:[NSString stringWithFormat:@"record model filePath: %@. ", algorithmRecord.filePath ?: @""]];
        if (algorithmRecord) {
            // Model not found rate monitor
            return algorithmRecord;
        }
        
        // If there is no valid downloaded algorithm model and has a builtin model, use it.
        algorithmRecord = [self.manifestManager builtinAlgorithmRecordForName:name];
        [traceLog appendString:[NSString stringWithFormat:@"builtin model filePath: %@. ", algorithmRecord.filePath ?: @""]];
        if (algorithmRecord) {
            return algorithmRecord;
        }
    }
    
    return nil;
}

#pragma mark - Notifications

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
}

- (void)onAppWillTerminate:(NSNotification *)notification {
    IESEffectUtil.disablePeekResource = YES;
}

@end

@implementation IESEffectManager (Statistic)

- (void)updateUseCountForEffect:(IESEffectModel *)effectModel byValue:(NSInteger)value {
    [self.manifestManager updateUseCountForEffect:effectModel byValue:value];
}

- (void)updateRefCountForEffect:(IESEffectModel *)effectModel byValue:(NSInteger)value {
    [self.manifestManager updateRefCountForEffect:effectModel byValue:value];
}

@end

@implementation IESEffectManager (DiskClean)

- (void)addAllowPanelListForEffectUnClean:(NSArray<NSString *> *)allowPanelList {
    [self.cleaner addAllowListForEffectUnClean:allowPanelList];
}

- (unsigned long long)getTotalBytes {
    unsigned long long totalBytes = 0;
    totalBytes += [self.manifestManager totalSizeOfEffectsAllocated];
    totalBytes += [self.manifestManager totalSizeOfAlgorithmAllocated];
    unsigned long long tmpDirectorySize = 0;
    NSString *tmpDirectory = self.config.tmpDirectory;
    NSError *error = nil;
    if ([NSFileManager ieseffect_getAllocatedSize:&tmpDirectorySize
                                 ofDirectoryAtURL:[NSURL fileURLWithPath:tmpDirectory]
                                            error:&error]) {
        totalBytes += tmpDirectorySize;
    }
    
    return totalBytes;
}

- (void)removeAllCacheFiles {
    if (!self.hasSetUp) {
        return;
    }
    
    [self.cleaner cleanEffectsDirectoryWithPolicy:IESEffectCleanPolicyRemoveAll completion:^{
        [self.cleaner vacuumDatabaseFile];
        EPDebugLog(@"remove all cache file, cleanEffectsDirectoryWithPolicy");
    }];
    
    [self.cleaner cleanAlgorithmDirectory:^(NSError * _Nonnull error) {
        EPDebugLog(@"remove all cache file, cleanAlgorithmDirectory");
    }];
    
    [self.cleaner cleanTmpDirectoryWithPolicy:IESEffectCleanPolicyRemoveAll completion:^{
        EPDebugLog(@"remove all cache file, cleanTmpDirectoryWithPolicy");
    }];
}

@end

static char *ieseffectmanager_resource_finder(__unused void * handle, __unused const char * dir, const char * name) {
    NSString *modelName = [NSString stringWithUTF8String:name];
    NSMutableString *traceLog = [[NSMutableString alloc] init];
    IESAlgorithmRecord *algorithmRecord = [[IESEffectManager manager] algorithmPathForAlgorithmName:modelName traceLog:traceLog];
    NSString *modelPath = algorithmRecord.filePath;
    NSMutableDictionary *extra = [NSMutableDictionary dictionaryWithDictionary:@{@"product_name" : modelName ?: @""}];
    if (algorithmRecord.filePath.length <= 0) {
        extra[@"monitor_trace"] = traceLog;
    }
    [[IESEffectLogger logger] trackService:@"model_not_found_rate" status:algorithmRecord.filePath.length > 0 ? 0:1 extra:extra.copy];
    extra[@"status"] = @(algorithmRecord.filePath.length > 0 ? 0:1);
    [[IESEffectLogger logger] logEvent:@"find_algorithm_model_success_rate" params:extra.copy];
    if (modelPath.length > 0) {
        modelPath = [NSURL fileURLWithPath:modelPath].absoluteString; // Convert path to fileURL.
    } else {
        modelPath = @"file://not_exist";
    }
    EPDebugLog(@"resource finder modelName:%@ modelPath:%@", modelName,modelPath);
    char *result_path = malloc(strlen(modelPath.UTF8String) + 1);
    strcpy(result_path, modelPath.UTF8String) ;
    return result_path;
}
