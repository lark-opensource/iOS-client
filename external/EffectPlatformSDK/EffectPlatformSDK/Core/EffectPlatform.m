//
//  EffectPlatform.m
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/29.
//
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/stat.h>

#import <CoreGraphics/CoreGraphics.h>
#import <FMDB/FMDB.h>
#import <OpenGLES/ES2/gl.h>
#import <FileMD5Hash/FileHash.h>
#import <SSZipArchive/SSZipArchive.h>

#import "EffectPlatform.h"
#import "EffectPlatform+Additions.h"
#import "IESFileDownloader.h"
#import "IESEffectPlatformRequestManager.h"
#import "NSString+EffectPlatformUtils.h"
#import "IESAlgorithmRecord.h"
#import "IESUserUsedStickerResponseModel.h"
#import "IESThirdPartyStickerModel.h"
#import "IESThirdPartyResponseModel.h"

#import <EffectPlatformSDK/IESEffectManager.h>
#import <EffectPlatformSDK/IESEffectLogger.h>

#define DEFAULT_SDK_VERSION @"2.0.0"

#define ResponseCacheKeyWithPanel(panel) [NSString stringWithFormat:@"%@%@",[[EffectPlatform sharedInstance] _cacheKeyPrefixFromCommonParameters], panel]

#define ResponseCacheKeyWithPanelForNew(panel) [NSString stringWithFormat:@"%@%@_new",[[EffectPlatform sharedInstance] _cacheKeyPrefixFromCommonParameters], panel]

#define ResponseCacheKeyWithPanelAndCategoryAndCursor(panel, category, cursor, sortingPosition) [NSString stringWithFormat:@"%@%@%@%@%@",[[EffectPlatform sharedInstance] _cacheKeyPrefixFromCommonParameters], panel, category, @(cursor), @(sortingPosition)]

#define ResponseCacheKeyWithPanelAndCursorForHot(panel, cursor, sortingPosition) [NSString stringWithFormat:@"%@%@%@%@_hot",[[EffectPlatform sharedInstance] _cacheKeyPrefixFromCommonParameters], panel, @(cursor), @(sortingPosition)]

#define FullPathOfSubPath(dir) [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:dir]

NSNotificationName const EffectPlatformFinishCleanCacheNotification = @"EffectPlatformFinishCleanCacheNotification";


@interface EffectCacheInfo : NSObject
@property (nonatomic, copy) NSString *resourceName;
@property (nonatomic, strong) NSDate *lastAccessDate;
@property (nonatomic, assign) NSUInteger cacheSize;
@property (nonatomic, copy) NSString *effectName;

@end

@implementation EffectCacheInfo

@end

@interface EffectPlatform ()
@property (nonatomic, copy) dispatch_block_t autoCacheCleanBlock;
@property (nonatomic, assign) IESCacheCleanStatus cacheCleanStatus;

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, strong) dispatch_queue_t ioQueue;
@property (nonatomic, strong) dispatch_queue_t dbDispatchQueue;

@property (nonatomic, copy) NSArray<NSString *> *allowPanelList;
@property (nonatomic, strong) NSRecursiveLock *lock;
@end


@implementation EffectPlatform

- (instancetype)init {
    if (self = [super init]) {
        _networkCallBackQueue = dispatch_queue_create("com.bytedance.ies.effect-platform-networkCallBack", DISPATCH_QUEUE_SERIAL);
        _infoDictLock = [[NSRecursiveLock alloc] init];
        _infoDictLock.name = @"com.bytedance.ies.infoDictLock";
        _ioQueue = dispatch_queue_create("com.bytedance.ies.resourceIoQueue", DISPATCH_QUEUE_SERIAL);
        _dbDispatchQueue = dispatch_queue_create("com.bytedance.ies.effectplatform.dbQueue", DISPATCH_QUEUE_SERIAL);
        _lock = [[NSRecursiveLock alloc] init];
        _requestDelegate = [IESEffectPlatformRequestManager requestManager];
        [self initDB];
    }
    return self;
}

#pragma mark - Public Functions
+ (void)setEnableMemoryCache:(BOOL)enable
{
    [[EffectPlatform sharedInstance].cache setEnableMemoryCache:enable];
}
+ (EffectPlatform *)startWithAccessKey:(NSString *)accessKey;
{
    if ([[EffectPlatform sharedInstance].accessKey isEqual:accessKey]) {
        return [EffectPlatform sharedInstance];
    }
    
    [EffectPlatform sharedInstance].accessKey = accessKey;
    [EffectPlatform sharedInstance].cache = [[EffectPlatformCache alloc] initWithAccessKey:accessKey];
    return [EffectPlatform sharedInstance];
}

+ (EffectPlatform *)sharedInstance;
{
    static EffectPlatform *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [EffectPlatform new];
    });
    return sharedInstance;
}

+ (void)clearMemoryCache
{
    [[EffectPlatform sharedInstance].cache clearMemory];
}

+ (NSUInteger)cacheSizeOfEffectPlatform
{
    NSUInteger size = 0;
    NSArray<NSString *> *cachePaths = @[
                                        IES_EFFECT_FOLDER_PATH,
                                        IES_THIRDPARTY_FOLDER_PATH,
                                        IES_EFFECT_UNCOMPRESS_FOLDER_PATH
                                        ];
    NSString *fullPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    for (NSString *cachePath in cachePaths) {
        size += [self folderSizeAtPath:[fullPath stringByAppendingPathComponent:cachePath]];
    }
    size += [[IESEffectManager manager] getTotalBytes];
    return size;
}

+ (void)clearCache
{
    NSArray<NSString *> *cachePaths = @[
                                        IES_EFFECT_FOLDER_PATH,
                                        IES_THIRDPARTY_FOLDER_PATH,
                                        IES_EFFECT_UNCOMPRESS_FOLDER_PATH
                                        ];
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    for (NSString *cachePath in cachePaths) {
        NSString * fullPath= [rootPath stringByAppendingPathComponent:cachePath];
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath
                                                                                error:nil];
        for (NSString *content in contents) {
            NSString *path = [NSString stringWithFormat:@"%@/%@",fullPath,content];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            }
        }
    }
    [[EffectPlatform sharedInstance].cache clear];
    [[EffectPlatform sharedInstance] clearAllCacheItemsInDB];
    [[IESEffectManager manager] removeAllCacheFiles];
    [[NSNotificationCenter defaultCenter] postNotificationName:EffectPlatformFinishCleanCacheNotification object:nil];
}

+ (void)clearEffectsAndAlgorithms {
    NSArray<NSString *> *cachePaths = @[IES_EFFECT_ALGORITHM_FOLDER_PATH,
                                        IES_EFFECT_UNCOMPRESS_FOLDER_PATH
    ];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    for (NSString *cachePath in cachePaths) {
        NSString *fullPath= [documentsDirectory stringByAppendingPathComponent:cachePath];
        BOOL isDirectory = NO;
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
        if (fileExists && isDirectory) {
            NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:nil];
            if (contents.count > 0) {
                for (NSString *content in contents) {
                    NSString *path = [fullPath stringByAppendingPathComponent:content];
                    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                }
            }
        }
    }
    
    [[EffectPlatform sharedInstance] clearAllCacheItemsInDB];
}

#pragma mark - Database For Cached Effect

- (NSString *)dbPath {
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    filePath = [filePath stringByAppendingPathComponent:IES_FOLDER_PATH];
    return [filePath stringByAppendingPathComponent:@"EffectCache.db"];
}

- (BOOL)initDB {
    self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:[self dbPath]];
    __block BOOL success = NO;
    if (self.dbQueue.openFlags) {
        NSString *sql = @"CREATE TABLE IF NOT EXISTS EffectCacheModel (resourceName TEXT PRIMARY KEY, effectName TEXT, cacheSize INTEGER, lastAccessDate REAL)";
        __weak typeof(self) weakSelf = self;
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            __strong typeof(self) strongSelf = weakSelf;
            success = [db executeUpdate:sql];
            if (!success) {
                if (strongSelf.dbErrorBlock) {
                    strongSelf.dbErrorBlock(db.lastError);
                }
            }
        }];
    }
    return success;
}

- (void)clearAllCacheItemsInDB
{
    __weak typeof(self) weakSelf = self;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        __strong typeof(self) strongSelf = weakSelf;
        BOOL success = [db executeUpdate:@"DELETE FROM EffectCacheModel"];
        if (!success) {
            NSError *error = [NSError errorWithDomain:db.lastError.domain code:db.lastErrorCode userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"[-clearAllCacheItemsInDB] effect clear DB failed, errorMsg: %@", db.lastErrorMessage]}];
            if (strongSelf.dbErrorBlock) {
                strongSelf.dbErrorBlock(error);
            }
        }
    }];
}

#pragma mark -

+ (void)clearCacheForEffectFolderPath
{
    NSArray<NSString *> *cachePaths = @[
                                        IES_EFFECT_FOLDER_PATH,
                                        ];
    for (NSString *cachePath in cachePaths) {
        NSString *fullPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        fullPath = [fullPath stringByAppendingPathComponent:cachePath];
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath
                                                                                error:nil];
        for (NSString *content in contents) {
            NSString *path = [NSString stringWithFormat:@"%@/%@",fullPath,content];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            }
        }
    }
    [[EffectPlatform sharedInstance].cache clear];
}

+ (IESEffectPlatformResponseModel *)cachedEffectsOfPanel:(NSString *)panel
{
    NSString *key = ResponseCacheKeyWithPanel(panel);
    IESEffectPlatformResponseModel *model = [[EffectPlatform sharedInstance].cache objectWithKey:key];
    if ([EffectPlatform sharedInstance].platformURLPrefix.count == 0 && model.urlPrefix.count > 0) {
        [EffectPlatform sharedInstance].platformURLPrefix = [model.urlPrefix copy];
    }
    return model;
}

+ (IESEffectPlatformNewResponseModel *)cachedEffectsOfPanel:(NSString *)panel category:(NSString *)category
{
    NSString *key = ResponseCacheKeyWithPanelAndCategoryAndCursor(panel, category, 0, 0);
    return [[EffectPlatform sharedInstance].cache newResponseWithKey:key];
}

+ (IESEffectPlatformNewResponseModel *)cachedEffectsOfPanel:(NSString *)panel category:(NSString *)category cursor:(NSInteger)cursor sortingPosition:(NSInteger)position
{
    NSString *key = ResponseCacheKeyWithPanelAndCategoryAndCursor(panel, category, cursor, position);
    return [[EffectPlatform sharedInstance].cache newResponseWithKey:key];
}

+ (IESEffectPlatformNewResponseModel *)cachedCategoriesOfPanel:(NSString *)panel
{
    NSString *key = ResponseCacheKeyWithPanelForNew(panel);
    return [[EffectPlatform sharedInstance].cache newResponseWithKey:key];
}

+ (IESEffectPlatformNewResponseModel *)cachedHotEffectsOfPanel:(NSString *)panel cursor:(NSInteger)cursor sortingPosition:(NSInteger)position
{
    NSString *key = ResponseCacheKeyWithPanelAndCursorForHot(panel, cursor, position);
    return [[EffectPlatform sharedInstance].cache newResponseWithKey:key];
}

- (NSMutableDictionary *)downloadingProgressDic
{
    if (!_downloadingProgressDic) {
        _downloadingProgressDic = [NSMutableDictionary dictionary];
    }
    return _downloadingProgressDic;
}

- (NSMutableDictionary *)downloadingCompletionDic
{
    if (!_downloadingCompletionDic) {
        _downloadingCompletionDic = [NSMutableDictionary dictionary];
    }
    return _downloadingCompletionDic;
}

- (void)saveNewResponseModelData:(IESEffectPlatformNewResponseModel *)responseModel withKey:(NSString *)key {
    NSError *transformError = nil;
    NSDictionary *responseModelData = [MTLJSONAdapter JSONDictionaryFromModel:responseModel error:&transformError];
    if (responseModelData && !transformError) {
        [self.cache setJson:responseModelData newResponse:responseModel forKey:key];
    } else {
        IESEffectLogError(@"the decrypted response model data saves failed with error: %@", transformError.description);
    }
}

+ (void)setNetworkParametersBlock:(EffectPlatformNetworkParametersBlock)networkParametersBlock
{
    [[EffectPlatform sharedInstance] setNetworkParametersBlock:networkParametersBlock];
}

- (void)setNetworkParametersBlock:(EffectPlatformNetworkParametersBlock)networkParametersBlock {
    _networkParametersBlock = networkParametersBlock;
    [IESEffectManager manager].config.networkParametersBlock = networkParametersBlock;
}

+ (void)setExtraPerRequestNetworkParametersBlock:(EffectPlatformNetworkParametersBlock _Nullable)networkParametersBlock
{
    [EffectPlatform sharedInstance].extraPerRequestNetworkParametersBlock = networkParametersBlock;
}

+ (void)setEffectSDKVersion:(NSString *)sdkVersion
{
    [EffectPlatform sharedInstance].effectVersion = sdkVersion;
}

+ (void)setDeviceIdentifier:(NSString *)deviceIdentifier
{
    [EffectPlatform sharedInstance].deviceIdentifier = deviceIdentifier;
    [IESEffectManager manager].config.deviceIdentifier = deviceIdentifier;
}

+ (void)setChannel:(NSString *)channel
{
    [EffectPlatform sharedInstance].channel = channel;
}

+ (void)setRegion:(NSString *)region
{
    [EffectPlatform sharedInstance].region = region;
    [IESEffectManager manager].config.region = region;
}

+ (void)setAppId:(NSString *)appId
{
    [EffectPlatform sharedInstance].appId = appId;
    [IESEffectManager manager].config.appID = appId;
}

+ (void)setOsVersion:(NSString *)osVersion
{
    [EffectPlatform sharedInstance].osVersion = osVersion;
}

+ (void)setDomain:(NSString *)domain
{
    [EffectPlatform sharedInstance].domain = domain;
    [IESEffectManager manager].config.domain = domain;
}

+ (void)setRequestDelegate:(id<EffectPlatformRequestDelegate>)requestDelegate
{
    [EffectPlatform sharedInstance].requestDelegate = requestDelegate;
    [IESFileDownloader sharedInstance].requestDelegate = requestDelegate;
}

+ (void)setTrackingDelegate:(id<EffectPlatformTrackingDelegate>)trackingDelegate
{
    if ([trackingDelegate respondsToSelector:@selector(postTracker:value:status:)]) {
        [EffectPlatform sharedInstance].trackingDelegate = trackingDelegate;
    }
}

+ (void)setAutoDownloadEffects:(BOOL)autoDownloadEffects
{
    [EffectPlatform sharedInstance].autoDownloadEffects = autoDownloadEffects;
}

+ (void)setDidAppUpdated:(BOOL)didAppUpdated
{
    [EffectPlatform sharedInstance].didAppUpdated = didAppUpdated;
    if (didAppUpdated) {
        [EffectPlatform clearCache];
    }
}

+ (void)setAppVersion:(NSString *)appVersion
{
    [EffectPlatform sharedInstance].appVersion = appVersion;
}

+ (void)setPlatformOptimizeStrategy:(NSNumber *)platformOptimizeStrategy
{
    [EffectPlatform sharedInstance].platformOptimizeStrategy = platformOptimizeStrategy;
}

+ (void)setEnableReducedEffectList:(BOOL)enableReducedEffectList
{
    [EffectPlatform sharedInstance].enableReducedEffectList = enableReducedEffectList;
}

+ (BOOL)createEffectDownloadFolderIfNeeded
{
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    filePath = [filePath stringByAppendingPathComponent:IES_EFFECT_FOLDER_PATH];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return NO;
}

#pragma mark - Public Functions

- (NSString *)cacheKeyPrefixFromCommonParameters
{
    return [self _cacheKeyPrefixFromCommonParameters];
}

- (NSDictionary *)commonParameters
{
    return [self _commonParameters];
}

- (void)autoDownloadIfNeededWithNewModel:(IESEffectPlatformNewResponseModel *)model
{
    return [self _autoDownloadIfNeededWithNewModel:model];
}

#pragma mark - Private Functions

- (NSString *)_cacheKeyPrefixFromCommonParameters
{
    NSMutableString *keyPrefix = @"".mutableCopy;
    NSString *region = self.region ?: @"";
    NSString *sdk_version = self.effectVersion ?: DEFAULT_SDK_VERSION;
    NSString *channel = self.channel ?: @"test";
    NSString *reduced = self.enableReducedEffectList ? @"1" : @"0";
    [keyPrefix appendFormat:@"%@-%@,", @"region", region];
    [keyPrefix appendFormat:@"%@-%@,", @"sdk_version", sdk_version];
    [keyPrefix appendFormat:@"%@-%@,", @"channel", channel];
    [keyPrefix appendFormat:@"%@-%@,", @"reduced", reduced];
    return keyPrefix;
}


- (NSDictionary *)_commonParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"access_key"] = self.accessKey ?: @"";
    parameters[@"region"] = self.region ?: @"";
    parameters[@"sdk_version"] = self.effectVersion ?: DEFAULT_SDK_VERSION;
    parameters[@"device_id"] = (self.deviceIdentifier ?: [UIDevice currentDevice].identifierForVendor.UUIDString) ?: @"";
    parameters[@"device_platform"] = @"iphone";
    parameters[@"device_type"] = [EffectPlatform _deviceType] ?: @"";
    parameters[@"package_name"] = [[NSBundle mainBundle] infoDictionary][@"CFBundleIdentifier"] ?: @"";
    parameters[@"app_name"] = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"] ?: @"";
    parameters[@"app_version"] = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: @"";
    parameters[@"channel"] = self.channel ?: @"test";
    parameters[@"platformSDKVersion"] = IESEffectPlatformSDKVersion ?: @"";
    parameters[@"platform_sdk_version"] = IESEffectPlatformSDKVersion ?: @"";
    if (self.appVersion && self.appVersion.length > 0) {
        parameters[@"app_version"] = self.appVersion;
    }
    parameters[@"aid"] = self.appId;
    parameters[@"os_version"] = self.osVersion;
    parameters[@"platform_ab_params"] = self.platformOptimizeStrategy ?: @(0);
    if (self.networkParametersBlock) {
        [parameters addEntriesFromDictionary:self.networkParametersBlock() ?: @{}];
    }
    return parameters.copy;
}

+ (NSString *)_getSysInfoByName:(char *)typeSpecifier
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    return results;
}

+ (NSString *)_deviceType
{
    return [EffectPlatform _getSysInfoByName:"hw.machine"];
}

- (void)_autoDownloadIfNeededWithModel:(IESEffectPlatformResponseModel *)model
{
    if (!self.autoDownloadEffects) {
        return;
    }
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        [model.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.downloaded) {
                [EffectPlatform downloadEffect:obj progress:nil completion:nil];
            }
        }];
    });
}

- (void)_autoDownloadIfNeededWithNewModel:(IESEffectPlatformNewResponseModel *)model
{
    if (!self.autoDownloadEffects) {
        return;
    }
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        [model.categoryEffects.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.downloaded) {
                [EffectPlatform downloadEffect:obj progress:nil completion:nil];
            }
        }];
        
        [model.categorySampleEffects enumerateObjectsUsingBlock:^(IESCategorySampleEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.effect && !obj.effect.downloaded) {
                [EffectPlatform downloadEffect:obj.effect progress:nil completion:nil];
            }
        }];
    });
}

@end

@implementation EffectPlatform(EffectDownloader)

#pragma mark - Get Effect List

+ (void)downloadEffectListWithPanel:(NSString *)panel
                         completion:(EffectPlatformFetchListCompletionBlock)completion
{
    [self downloadEffectListWithPanel:panel saveCache:YES completion:completion];
}

+ (void)downloadEffectListWithPanel:(NSString *)panel
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                         completion:(EffectPlatformFetchListCompletionBlock _Nullable)completion
{
    [self downloadEffectListWithPanel:panel
                            saveCache:YES
                 effectTestStatusType:statusType
                           completion:completion];
}

+ (void)downloadEffectListWithPanel:(NSString *)panel
                          saveCache:(BOOL)saveCache
                         completion:(EffectPlatformFetchListCompletionBlock)completion
{
    [self downloadEffectListWithPanel:panel
                            saveCache:saveCache
                 effectTestStatusType:IESEffectModelTestStatusTypeDefault
                           completion:completion];
}

+ (void)downloadEffectListWithPanel:(NSString *)panel
                          saveCache:(BOOL)saveCache
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                         completion:(EffectPlatformFetchListCompletionBlock _Nullable)completion
{
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    totalParameters[@"panel"] = panel;
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    if (statusType != IESEffectModelTestStatusTypeDefault) {
        totalParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusType];
    }
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSString *urlString = [platform _urlWithPath:@"/effect/api/v3/effects"];
    if (platform.enableReducedEffectList) {
        urlString = [platform _urlWithPath:@"/effect/api/effects/v4"];
    }
    
    NSMutableDictionary *trackInfo = @{
        @"app_id" : platform.appId ?: @"",
        @"access_key" : platform.accessKey ?: @"",
        @"panel" : panel ?: @"",
        @"status":@(0)
    }.mutableCopy;
    NSString *serviceName = @"effect_list_success_rate";
    
    [EffectPlatform _requestWithURLString:urlString parameters:totalParameters completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch all effect|panel=%@|saveCache=%d|statusType=%@|error=%@", panel, saveCache, @(statusType), error);
        
        if (error) {
           NSDictionary *extra = _addErrorInfoToTrackInfo(trackInfo, error);
           dispatch_async(dispatch_get_main_queue(), ^{
               if (platform.trackingDelegate) {
                   [platform.trackingDelegate postTracker:serviceName
                                                    value:extra
                                                   status:1];
               }
               [[IESEffectLogger logger] logEvent:serviceName params:extra];
               !completion ?: completion(error, nil);
           });
           return;
        }

        NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
        if (serverError) {
           NSDictionary *extra = _addErrorInfoToTrackInfo(trackInfo, serverError);
           dispatch_async(dispatch_get_main_queue(), ^{
               if (platform.trackingDelegate) {
                   [platform.trackingDelegate postTracker:serviceName
                                                    value:extra
                                                   status:1];
               }
               [[IESEffectLogger logger] logEvent:serviceName params:extra];
               !completion ?: completion(serverError, nil);
           });
           return;
        }
        CFTimeInterval parseJSONStartTime = CFAbsoluteTimeGetCurrent();
        NSError *mappingError;
        IESEffectPlatformResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESEffectPlatformResponseModel class]
                                                                 fromJSONDictionary:jsonDic[@"data"]
                                                                              error:&mappingError];
        if ([jsonDic[@"_AME_Header_RequestID"] isKindOfClass:[NSString class]]) {
            responseModel.requestID = jsonDic[@"_AME_Header_RequestID"];
        }
        if (mappingError || !responseModel) {
           NSDictionary *extra = _addErrorInfoToTrackInfo(trackInfo, mappingError);
           dispatch_async(dispatch_get_main_queue(), ^{
               if (platform.trackingDelegate) {
                   [platform.trackingDelegate postTracker:serviceName
                                                    value:extra
                                                   status:1];
               }
               [[IESEffectLogger logger] logEvent:serviceName params:extra];
               !completion ?: completion(mappingError, nil);
           });
           return;
        }

        [responseModel setPanelName:panel];
        [responseModel preProcessEffects];
        
        NSMutableDictionary *extra = trackInfo.mutableCopy;
        extra[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
        extra[@"json_time"] = @((CFAbsoluteTimeGetCurrent() - parseJSONStartTime) * 1000);
        
        if (saveCache) {
            NSString *key = ResponseCacheKeyWithPanel(panel);
            NSError *transformError = nil;
            NSDictionary *responseModelData = [MTLJSONAdapter JSONDictionaryFromModel:responseModel error:&transformError];
            if (responseModelData && !transformError) {
                [[EffectPlatform sharedInstance].cache setJson:responseModelData object:responseModel forKey:key];
            } else {
                IESEffectLogError(@"the decrypted effect list data saves failed with error:%@", transformError.description);
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
           if (platform.trackingDelegate) {
               [platform.trackingDelegate postTracker:serviceName
                                                value:extra
                                               status:0];
           }
           [[IESEffectLogger logger] logEvent:serviceName params:extra];
           !completion ?: completion(nil, responseModel);
        });
        [[EffectPlatform sharedInstance] _autoDownloadIfNeededWithModel:responseModel];
    }];
}

+ (void)fetchEffectListStateWithPanel:(NSString *)panel completion:(EffectPlatformFetchListCompletionBlock)completion
{
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    totalParameters[@"panel"] = panel;
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    
    NSString *urlString = [platform _urlWithPath:@"/effect/api/filterbox/list"];
    [EffectPlatform _requestWithURLString:urlString
                               parameters:totalParameters
                               completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch effect list state|panel=%@|error=%@", panel, error);
        
        if (error) {
           dispatch_async(dispatch_get_main_queue(), ^{
               !completion ?: completion(error, nil);
           });
           return;
        }
        NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
        if (serverError) {
           dispatch_async(dispatch_get_main_queue(), ^{
               !completion ?: completion(serverError, nil);
           });
           return;
        }

        NSError *mappingError;
        IESEffectPlatformResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESEffectPlatformResponseModel class]
                                                                 fromJSONDictionary:jsonDic[@"data"]
                                                                              error:&mappingError];
        if (mappingError || !responseModel) {
           dispatch_async(dispatch_get_main_queue(), ^{
               !completion ?: completion(mappingError, nil);
           });
           return;
        }
        [responseModel setPanelName:panel];
        [responseModel preProcessEffects];
        dispatch_async(dispatch_get_main_queue(), ^{
           !completion ?: completion(nil, responseModel);
        });
    }];
}

+ (void)updateEffectListStateWithPanel:(NSString *)panel
                            checkArray:(NSArray *)checkArray
                          uncheckArray:(NSArray *)uncheckArray
                            completion:(nonnull EffectPlatformFilterBoxUpdateCompletion)completion
{
    // -1 未同步
    // 0 同步成功
    // 1 同步失败
    __block NSInteger syncCheckState = -1;
    __block NSInteger syncUncheckState = -1;
    
    // 1. 将check或uncheck状态同步到服务端
    NSString *const filterBoxUpdatePath = @"/effect/api/filterbox/update";
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    
    if (checkArray.count > 0) {
        NSString *checkIds = [checkArray componentsJoinedByString:@","];
        NSMutableDictionary *totalParameters = [@{} mutableCopy];
        totalParameters[@"panel"] = panel;
        totalParameters[@"effect_ids"] = checkIds ?: @"";
        totalParameters[@"type"] = @(1);
        [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
        if (platform.extraPerRequestNetworkParametersBlock) {
            [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
            [self setExtraPerRequestNetworkParametersBlock:nil];
        }
        
        // WARNING:
        // aid 这个参数服务端要求传整数，只此接口需要改，所以此处覆盖公共参数中的整数类型
        totalParameters[@"aid"] = @([[[EffectPlatform sharedInstance] appId] integerValue]);
        
        NSString *urlString = [platform _urlWithPath:filterBoxUpdatePath];
        [EffectPlatform _requestWithURLString:urlString
                                   parameters:totalParameters
                                       cookie:nil
                                   httpMethod:@"POST"
                                   completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
            IESEffectLogInfo(@"update checkArray effect list state|panel=%@|error=%@", panel, error);
                                       if (jsonDic) {
                                           NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
                                           if (nil == serverError) {
                                               syncCheckState = 0;
                                           } else {
                                               syncCheckState = 1;
                                           }
                                       } else {
                                           syncCheckState = 1;
                                       }
                                       
                                       // 两个同步都结束
                                       if (-1 != syncCheckState && -1 != syncUncheckState) {
                                           if (completion) {
                                               if (0 == syncCheckState && 0 == syncUncheckState) {
                                                   // 同步成功后，缓存（内存和磁盘）已dirty，需要清除
                                                   NSString *key = ResponseCacheKeyWithPanel(panel);
                                                   [[EffectPlatform sharedInstance].cache clearJsonAndObjectForKey:key];
                                                   
                                                   completion(nil, YES);
                                               } else {
                                                   completion(error, NO);
                                               }
                                           }
                                       }
                                   }];
    } else {
        syncCheckState = 0; // 不需要同步直接标记为成功
    }
    
    if (uncheckArray.count > 0) {
        NSString *uncheckIds = [uncheckArray componentsJoinedByString:@","];
        NSMutableDictionary *totalParameters = [@{} mutableCopy];
        totalParameters[@"panel"] = panel;
        totalParameters[@"effect_ids"] = uncheckIds ?: @"";
        totalParameters[@"type"] = @(0);
        [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
        if (platform.extraPerRequestNetworkParametersBlock) {
            [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
            [self setExtraPerRequestNetworkParametersBlock:nil];
        }
        
        // WARNING:
        // aid 这个参数服务端要求传整数，只此接口需要改，所以此处覆盖公共参数中的整数类型
        totalParameters[@"aid"] = @([[[EffectPlatform sharedInstance] appId] integerValue]);
        
        NSString *urlString = [platform _urlWithPath:filterBoxUpdatePath];
        [EffectPlatform _requestWithURLString:urlString
                                   parameters:totalParameters
                                       cookie:nil
                                   httpMethod:@"POST"
                                   completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
            IESEffectLogInfo(@"update uncheckArray effect list state|panel=%@|error=%@", panel, error);
                                       if (jsonDic) {
                                           NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
                                           if (nil == serverError) {
                                               syncUncheckState = 0;
                                           } else {
                                               syncUncheckState = 1;
                                           }
                                       } else {
                                           syncUncheckState = 1;
                                       }
                                       
                                       // 两个同步都结束
                                       if (-1 != syncCheckState && -1 != syncUncheckState) {
                                           if (completion) {
                                               if (0 == syncCheckState && 0 == syncUncheckState) {
                                                   // 同步成功后，缓存（内存和磁盘）已dirty，需要清除
                                                   NSString *key = ResponseCacheKeyWithPanel(panel);
                                                   [[EffectPlatform sharedInstance].cache clearJsonAndObjectForKey:key];
                                                   completion(nil, YES);
                                               } else {
                                                   completion(error, NO);
                                               }
                                           }
                                       }
                                   }];
    } else {
        syncUncheckState = 0; // 不需要同步直接标记为成功
    }
}

+ (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    [self downloadEffectListWithPanel:panel
                             category:category
                            pageCount:pageCount
                               cursor:cursor
                      sortingPosition:position
                            saveCache:YES
                           completion:completion];
}

+ (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    [self downloadEffectListWithPanel:panel
                             category:category
                            pageCount:pageCount
                               cursor:cursor
                      sortingPosition:position
                            saveCache:YES
                 effectTestStatusType:statusType
                           completion:completion];
}

+ (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
                          saveCache:(BOOL)saveCache
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    [self downloadEffectListWithPanel:panel
                             category:category
                            pageCount:pageCount
                               cursor:cursor
                      sortingPosition:position
                            saveCache:saveCache
                 effectTestStatusType:IESEffectModelTestStatusTypeDefault
                           completion:completion];
}

+ (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
                          saveCache:(BOOL)saveCache
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    [self downloadEffectListWithPanel:panel
                             category:category
                            pageCount:pageCount
                               cursor:cursor
                      sortingPosition:position
                              version:nil
                            saveCache:saveCache
                 effectTestStatusType:statusType
                           completion:completion];
}

+ (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
                            version:(NSString * _Nullable)version
                          saveCache:(BOOL)saveCache
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    [self downloadEffectListWithPanel:panel
                             category:category
                            pageCount:pageCount
                               cursor:cursor
                      sortingPosition:position
                              version:nil
                            saveCache:saveCache
                 effectTestStatusType:statusType
                      extraParameters:nil
                           completion:completion];
}

+ (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
                            version:(NSString * _Nullable)version
                          saveCache:(BOOL)saveCache
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                    extraParameters:(NSDictionary * _Nullable)extra
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSMutableDictionary *totalParameters = extra ? [extra mutableCopy] : [NSMutableDictionary dictionary];
    totalParameters[@"panel"] = panel ?: @"";
    totalParameters[@"category"] = category ?: @"";
    totalParameters[@"gpu"] = platform.gpu ?: @"";
    if (pageCount != NSNotFound) {
        totalParameters[@"count"] = [NSString stringWithFormat:@"%ld", (long)pageCount];
    }
    if (cursor != NSNotFound) {
        totalParameters[@"cursor"] = [NSString stringWithFormat:@"%ld", (long)cursor];
    }
    if (position != NSNotFound) {
        totalParameters[@"sorting_position"] = [NSString stringWithFormat:@"%ld", (long)position];
    }
    if (nil != version) {
        totalParameters[@"version"] = version;
    }
    if (statusType != IESEffectModelTestStatusTypeDefault) {
        totalParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusType];
    }
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSString *urlString = [platform _urlWithPath:@"/effect/api/category/effects"];
    if (platform.enableReducedEffectList) {
        urlString = [platform _urlWithPath:@"/effect/api/category/effects/v2"];
    }
    
    NSString *serviceName = @"category_list_success_rate";
    NSDictionary *trackInfo = @{
        @"app_id" : platform.appId ?: @"",
        @"access_key" : platform.accessKey ?: @"",
        @"panel" : panel ?: @"",
        @"category" : category ?: @"",
        @"status":@(0)
    };
    
    [EffectPlatform _requestWithURLString:urlString parameters:totalParameters completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch effect list|panel=%@|category=%@|pageCount=%@|cursor=%@|sortingPosition=%@|version=%@|error=%@",
                         panel, category, @(pageCount), @(cursor), @(position), version, error);
        if (error) {
           NSInteger status = 1;
           NSDictionary *extra = _addErrorInfoToTrackInfo(trackInfo, error);
           
           dispatch_async(dispatch_get_main_queue(), ^{
               if (platform.trackingDelegate) {
                   [platform.trackingDelegate postTracker:serviceName
                                                    value:extra
                                                   status:status];
               }
               [[IESEffectLogger logger] logEvent:serviceName params:extra];
               !completion ?: completion(error, nil);
           });
           return;
        }

        NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
        if (serverError) {
           NSInteger status = 1;
           NSDictionary *extra = _addErrorInfoToTrackInfo(trackInfo, serverError);
            
           dispatch_async(dispatch_get_main_queue(), ^{
               if (platform.trackingDelegate) {
                   [platform.trackingDelegate postTracker:serviceName
                                                    value:extra
                                                   status:status];
               }
               [[IESEffectLogger logger] logEvent:serviceName params:extra];
               !completion ?: completion(serverError, nil);
           });
           return;
        }
        
        CFTimeInterval parseJSONStartTime = CFAbsoluteTimeGetCurrent();
        NSError *mappingError = nil;
        IESEffectPlatformNewResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESEffectPlatformNewResponseModel class]
                                                                    fromJSONDictionary:jsonDic[@"data"]
                                                                                 error:&mappingError];
        if (mappingError || !responseModel) {
           NSInteger status = 1;
           NSDictionary *extra = _addErrorInfoToTrackInfo(trackInfo, mappingError);
           
           dispatch_async(dispatch_get_main_queue(), ^{
               if (platform.trackingDelegate) {
                   [platform.trackingDelegate postTracker:serviceName
                                                    value:extra
                                                   status:status];
               }
               [[IESEffectLogger logger] logEvent:serviceName params:extra];
               !completion ?: completion(mappingError, nil);
           });
           return;
        }
        
        [responseModel setPanelName:panel];
        [responseModel preProcessEffects];
        
        // track success
        NSMutableDictionary *extra = trackInfo.mutableCopy;
        extra[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
        extra[@"json_time"] = @((CFAbsoluteTimeGetCurrent() - parseJSONStartTime) * 1000);
        NSInteger status = 0;
        
        dispatch_async(dispatch_get_main_queue(), ^{
           if (platform.trackingDelegate) {
               [platform.trackingDelegate postTracker:serviceName
                                                value:extra
                                                status:status];
           }
           [[IESEffectLogger logger] logEvent:serviceName params:extra];
           !completion ?: completion(nil, responseModel);
        });
        NSString *key = ResponseCacheKeyWithPanelAndCategoryAndCursor(panel, category, cursor, position);
        if (saveCache) {
            [[EffectPlatform sharedInstance] saveNewResponseModelData:responseModel withKey:key];
        }
        [[EffectPlatform sharedInstance] _autoDownloadIfNeededWithNewModel:responseModel];
    }];
}

+ (void)downloadHotEffectListWithPanel:(NSString *)panel
                             pageCount:(NSInteger)pageCount
                                cursor:(NSInteger)cursor
                       sortingPosition:(NSInteger)position
                             saveCache:(BOOL)saveCache
                  effectTestStatusType:(IESEffectModelTestStatusType)statusType
                            completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    [self downloadHotEffectListWithPanel:panel
                               pageCount:pageCount
                                  cursor:cursor
                         sortingPosition:position
                               saveCache:saveCache
                    effectTestStatusType:statusType
                         extraParameters:nil
                              completion:completion];
}

+ (void)downloadHotEffectListWithPanel:(NSString *)panel
                             pageCount:(NSInteger)pageCount
                                cursor:(NSInteger)cursor
                       sortingPosition:(NSInteger)position
                             saveCache:(BOOL)saveCache
                  effectTestStatusType:(IESEffectModelTestStatusType)statusType
                       extraParameters:(NSDictionary *)extra
                            completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSMutableDictionary *totalParameters = extra ? [extra mutableCopy] : [@{} mutableCopy];
    totalParameters[@"panel"] = panel ?: @"";
    totalParameters[@"gpu"] = platform.gpu ?: @"";
    if (pageCount != NSNotFound) {
        totalParameters[@"count"] = [NSString stringWithFormat:@"%ld", (long)pageCount];
    }
    if (cursor != NSNotFound) {
        totalParameters[@"cursor"] = [NSString stringWithFormat:@"%ld", (long)cursor];
    }
    if (position != NSNotFound) {
        totalParameters[@"sorting_position"] = [NSString stringWithFormat:@"%ld", (long)position];
    }
    if (statusType != IESEffectModelTestStatusTypeDefault) {
        totalParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusType];
    }
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSString *urlString = [platform _urlWithPath:@"/effect/api/hoteffects"];
    
    NSDictionary *monitorTrackInfo = @{
        @"app_id" : platform.appId ?: @"",
        @"access_key" : platform.accessKey ?: @"",
        @"panel" : panel ?: @"",
        @"status":@(0)
    };
    NSString *serviceName = @"hot_list_success_rate";
    
    [EffectPlatform _requestWithURLString:urlString
                               parameters:totalParameters
                               completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch hot effect list|panel=%@|pageCount=%@|cursor=%@|position=%@|saveCache=%d|statusType=%@|error=%@",
                         panel, @(pageCount), @(cursor), position, saveCache, @(statusType), error);
        NSError *anyError = error ?: [EffectPlatform _serverErrorFromJSON:jsonDic];
        CFTimeInterval parseJSONStartTime = CFAbsoluteTimeGetCurrent();
        IESEffectPlatformNewResponseModel *responseModel = nil;
        if (!anyError) {
            responseModel = [MTLJSONAdapter modelOfClass:[IESEffectPlatformNewResponseModel class]
                                                                         fromJSONDictionary:jsonDic[@"data"]
                                                                                      error:&anyError];
        }
        if (anyError || !responseModel) {
            NSDictionary *extra = _addErrorInfoToTrackInfo(monitorTrackInfo, anyError);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (platform.trackingDelegate) {
                    [platform.trackingDelegate postTracker:serviceName
                                                     value:extra
                                                    status:1];
                }
                [[IESEffectLogger logger] logEvent:serviceName params:extra];
                !completion ?: completion(anyError, nil);
            });
            return;
        }
        [responseModel setPanelName:panel];
        [responseModel preProcessEffects];
        
        // track success
        NSMutableDictionary *extra = monitorTrackInfo.mutableCopy;
        extra[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
        extra[@"json_time"] = @((CFAbsoluteTimeGetCurrent() - parseJSONStartTime) * 1000);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (platform.trackingDelegate) {
               [platform.trackingDelegate postTracker:serviceName
                                                value:extra
                                                status:0];
            }
            [[IESEffectLogger logger] logEvent:serviceName params:extra];
            !completion ?: completion(nil, responseModel);
        });
        if (saveCache) {
            NSString *key = ResponseCacheKeyWithPanelAndCursorForHot(panel, cursor, position);
            [[EffectPlatform sharedInstance] saveNewResponseModelData:responseModel withKey:key];
        }
        [[EffectPlatform sharedInstance] _autoDownloadIfNeededWithNewModel:responseModel];
    }];
}

+ (void)downloadThemeEffectListWithPannel:(NSString *)panel
                             specCategory:(NSString *)specCategory
                                 category:(NSString *)category
                     effectTestStatusType:(IESEffectModelTestStatusType)statusType
                          extraParameters:(NSDictionary *)extra
                               completion:(EffectPlatformFetchCategoryListCompletionBlock)completion
{
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSMutableDictionary *totalParameters = extra ? [extra mutableCopy] : [@{} mutableCopy];
    totalParameters[@"panel"] = panel ?: @"";
    totalParameters[@"gpu"] = platform.gpu ?: @"";
    if (specCategory.length > 0) {
        totalParameters[@"spec_category"] = specCategory;
    }
    totalParameters[@"category"] = category ?: @"";
    
    if (statusType != IESEffectModelTestStatusTypeDefault) {
        totalParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusType];
    }
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    
    NSString *urlString = [platform _urlWithPath:@"/effect/api/category/effects/theme"];
    
    [EffectPlatform _requestWithURLString:urlString
                               parameters:totalParameters
                               completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch hot effect list|panel=%@|statusType=%@|error=%@",
                         panel, @(statusType), error);
        NSError *anyError = error ?: [EffectPlatform _serverErrorFromJSON:jsonDic];
        CFTimeInterval parseJSONStartTime = CFAbsoluteTimeGetCurrent();
        IESEffectPlatformNewResponseModel *responseModel = nil;
        if (!anyError) {
            responseModel = [MTLJSONAdapter modelOfClass:[IESEffectPlatformNewResponseModel class]
                                                                         fromJSONDictionary:jsonDic[@"data"]
                                                                                      error:&anyError];
        }
        if (anyError || !responseModel) {

            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(anyError, nil);
            });
            return;
        }
        [responseModel setPanelName:panel];
        [responseModel preProcessEffects];
        

        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, responseModel);
        });
        [[EffectPlatform sharedInstance] _autoDownloadIfNeededWithNewModel:responseModel];
    }];
}

#pragma mark - Get Category List

+ (void)fetchCategoriesListWithPanel:(NSString *)panel
        isLoadDefaultCategoryEffects:(BOOL)isLoad
                     defaultCategory:(NSString *)category
                           pageCount:(NSInteger)pageCount
                              cursor:(NSInteger)cursor
                          completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    [self fetchCategoriesListWithPanel:panel
          isLoadDefaultCategoryEffects:isLoad
                       defaultCategory:category
                             pageCount:pageCount
                                cursor:cursor
                             saveCache:YES
                            completion:completion];
}

+ (void)fetchCategoriesListWithPanel:(NSString *)panel
        isLoadDefaultCategoryEffects:(BOOL)isLoad
                     defaultCategory:(NSString *)category
                           pageCount:(NSInteger)pageCount
                              cursor:(NSInteger)cursor
                effectTestStatusType:(IESEffectModelTestStatusType)statusType
                          completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    [self fetchCategoriesListWithPanel:panel
          isLoadDefaultCategoryEffects:isLoad
                       defaultCategory:category
                             pageCount:pageCount
                                cursor:cursor
                             saveCache:YES
                  effectTestStatusType:statusType
                            completion:completion];
}

+ (void)fetchCategoriesListWithPanel:(NSString *)panel
        isLoadDefaultCategoryEffects:(BOOL)isLoad
                     defaultCategory:(NSString *)category
                           pageCount:(NSInteger)pageCount
                              cursor:(NSInteger)cursor
                           saveCache:(BOOL)saveCache
                          completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    [self fetchCategoriesListWithPanel:panel
          isLoadDefaultCategoryEffects:isLoad
                       defaultCategory:category
                             pageCount:pageCount
                                cursor:cursor
                             saveCache:saveCache
                  effectTestStatusType:IESEffectModelTestStatusTypeDefault
                            completion:completion];
}

+ (void)fetchCategoriesListWithPanel:(NSString *)panel
        isLoadDefaultCategoryEffects:(BOOL)isLoad
                     defaultCategory:(NSString *)category
                           pageCount:(NSInteger)pageCount
                              cursor:(NSInteger)cursor
                           saveCache:(BOOL)saveCache
                effectTestStatusType:(IESEffectModelTestStatusType)statusType
                          completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    [self fetchCategoriesListWithPanel:panel
          isLoadDefaultCategoryEffects:isLoad
                       defaultCategory:category
                             pageCount:pageCount
                                cursor:cursor
                             saveCache:saveCache
                  effectTestStatusType:statusType
                       extraParameters:nil
                            completion:completion];
}

+ (void)fetchCategoriesListWithPanel:(NSString *)panel
        isLoadDefaultCategoryEffects:(BOOL)isLoad
                     defaultCategory:(NSString *)category
                           pageCount:(NSInteger)pageCount
                              cursor:(NSInteger)cursor
                           saveCache:(BOOL)saveCache
                effectTestStatusType:(IESEffectModelTestStatusType)statusType
                     extraParameters:(NSDictionary * _Nullable)extra
                          completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSMutableDictionary *totalParameters = extra ? [extra mutableCopy] : [NSMutableDictionary dictionary];
    totalParameters[@"panel"] = panel ?: @"";
    totalParameters[@"gpu"] = platform.gpu ?: @"";
    if (isLoad) {
        totalParameters[@"has_category_effects"] = @(isLoad);
        totalParameters[@"category"] = category ?: @"";
        if (pageCount != NSNotFound) {
            totalParameters[@"count"] = [NSString stringWithFormat:@"%ld", (long)pageCount];
        }
        if (cursor != NSNotFound) {
            totalParameters[@"cursor"] = [NSString stringWithFormat:@"%ld", (long)cursor];
        }
    }
    if (statusType != IESEffectModelTestStatusTypeDefault) {
        totalParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusType];
    }
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    NSString *urlString = [platform _urlWithPath:@"/effect/api/panel/info"];
    if (platform.enableReducedEffectList) {
        urlString = [platform _urlWithPath:@"/effect/api/panel/info/v2"];
    }
    
    NSDictionary *monitorTrackInfo = @{
        @"app_id" : platform.appId ?: @"",
        @"access_key" : platform.accessKey ?: @"",
        @"panel" : panel ?: @"",
        @"status":@(0)
    };
    NSString *serviceName = @"panel_info_success_rate";
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    
    [EffectPlatform _requestWithURLString:urlString
                               parameters:totalParameters
                               completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch categories list|panel=%@|pageCount=%@|cursor=%@|saveCache=%d|statusType=%@|error=%@",
                         panel, @(pageCount), @(cursor), saveCache, @(statusType), error);
                                   if (error) {
                                       NSDictionary *extra = _addErrorInfoToTrackInfo(monitorTrackInfo, error);
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           if (platform.trackingDelegate) {
                                               [platform.trackingDelegate postTracker:serviceName
                                                                                value:extra
                                                                               status:1];
                                           }
                                           [[IESEffectLogger logger] logEvent:serviceName params:extra];
                                           !completion ?: completion(error, nil);
                                       });
                                       return;
                                   }
                                   NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
                                   if (serverError) {
                                       NSDictionary *extra = _addErrorInfoToTrackInfo(monitorTrackInfo, serverError);
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           if (platform.trackingDelegate) {
                                               [platform.trackingDelegate postTracker:serviceName
                                                                                value:extra
                                                                               status:1];
                                           }
                                           [[IESEffectLogger logger] logEvent:serviceName params:extra];
                                           !completion ?: completion(serverError, nil);
                                       });
                                       return;
                                   }
                                   CFTimeInterval parseJsonStartTime = CFAbsoluteTimeGetCurrent();
                                   NSError *mappingError = nil;
                                   IESEffectPlatformNewResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESEffectPlatformNewResponseModel class]
                                                                                             fromJSONDictionary:jsonDic[@"data"]
                                                                                                          error:&mappingError];
                                    if (responseModel.urlPrefix.count > 0) {
                                        platform.platformURLPrefix = [responseModel.urlPrefix copy];
                                    }
                                   if (mappingError || !responseModel) {
                                       NSDictionary *extra = _addErrorInfoToTrackInfo(monitorTrackInfo, mappingError);
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           if (platform.trackingDelegate) {
                                               [platform.trackingDelegate postTracker:serviceName
                                                                                value:extra
                                                                               status:1];
                                           }
                                           [[IESEffectLogger logger] logEvent:serviceName params:extra];
                                           !completion ?: completion(mappingError, nil);
                                       });
                                       return;
                                   }
                                   
                                   [responseModel setPanelName:panel];
                                   [responseModel preProcessEffects];
        
                                   NSMutableDictionary *extra = [monitorTrackInfo mutableCopy];
                                   extra[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
                                   extra[@"json_time"] = @((CFAbsoluteTimeGetCurrent() - parseJsonStartTime) * 1000);
        
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       if (platform.trackingDelegate) {
                                           [platform.trackingDelegate postTracker:serviceName
                                                                            value:extra
                                                                           status:0];
                                       }
                                       [[IESEffectLogger logger] logEvent:serviceName params:extra];
                                       !completion ?: completion(nil, responseModel);
                                   });
                                   if (saveCache) {
                                       NSString *key = ResponseCacheKeyWithPanelForNew(panel);
                                       [[EffectPlatform sharedInstance] saveNewResponseModelData:responseModel withKey:key];
                                       
                                       NSString *effectKey = ResponseCacheKeyWithPanelAndCategoryAndCursor(panel, category, cursor, 0);
                                       [[EffectPlatform sharedInstance] saveNewResponseModelData:responseModel withKey:effectKey];
                                   }
                                   [[EffectPlatform sharedInstance] _autoDownloadIfNeededWithNewModel:responseModel];
                               }];
}

+ (void)fetchOneCategoryListWithPanel:(NSString *)panel
                         specCategory:(NSString *)specCategory
                 effectTestStatusType:(IESEffectModelTestStatusType)statusType
                      extraParameters:(NSDictionary *)extra
                           completion:(EffectPlatformFetchCategoryListCompletionBlock)completion
{
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSMutableDictionary *totalParameters = extra ? [extra mutableCopy] : [NSMutableDictionary dictionary];
    totalParameters[@"panel"] = panel ?: @"";
    totalParameters[@"spec_category"] = specCategory ?: @"";
    totalParameters[@"gpu"] = platform.gpu ?: @"";
    if (statusType != IESEffectModelTestStatusTypeDefault) {
        totalParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusType];
    }
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    NSString *urlString = [platform _urlWithPath:@"/effect/api/panel/info/one"];
    
    [EffectPlatform _requestWithURLString:urlString
                               parameters:totalParameters
                               completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch one categories list|panel=%@|statusType=%@|error=%@",
                         panel, @(statusType), error);
                                   if (error) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           !completion ?: completion(error, nil);
                                       });
                                       return;
                                   }
                                   NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
                                   if (serverError) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           !completion ?: completion(serverError, nil);
                                       });
                                       return;
                                   }
                                   CFTimeInterval parseJsonStartTime = CFAbsoluteTimeGetCurrent();
                                   NSError *mappingError = nil;
                                   IESEffectPlatformNewResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESEffectPlatformNewResponseModel class]
                                                                                             fromJSONDictionary:jsonDic[@"data"]
                                                                                                          error:&mappingError];
                                    if (responseModel.urlPrefix.count > 0) {
                                        platform.platformURLPrefix = [responseModel.urlPrefix copy];
                                    }
                                   if (mappingError || !responseModel) {
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           !completion ?: completion(mappingError, nil);
                                       });
                                       return;
                                   }
                                   
                                   [responseModel setPanelName:panel];
                                   [responseModel preProcessEffects];
        
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       !completion ?: completion(nil, responseModel);
                                   });
                                   [[EffectPlatform sharedInstance] _autoDownloadIfNeededWithNewModel:responseModel];
                               }];
}

+ (void)fetchThemeCategoryListWithPanel:(NSString *)panel
                           specCategory:(NSString *)specCategory
                   effectTestStatusType:(IESEffectModelTestStatusType)statusType
                        extraParameters:(NSDictionary * _Nullable)extra
                             completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSMutableDictionary *totalParameters = extra ? [extra mutableCopy] : [NSMutableDictionary dictionary];
    totalParameters[@"panel"] = panel ?: @"";
    totalParameters[@"spec_category"] = specCategory ?: @"";
    totalParameters[@"gpu"] = platform.gpu ?: @"";
    if (statusType != IESEffectModelTestStatusTypeDefault) {
        totalParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusType];
    }
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    
    NSString *urlString = [platform _urlWithPath:@"/effect/api/panel/info/theme"];
    
    [EffectPlatform _requestWithURLString:urlString
                               parameters:totalParameters
                               completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch one categories list|panel=%@|statusType=%@|error=%@",
                         panel, @(statusType), error);
                                   if (error) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           !completion ?: completion(error, nil);
                                       });
                                       return;
                                   }
                                   NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
                                   if (serverError) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           !completion ?: completion(serverError, nil);
                                       });
                                       return;
                                   }
                                   CFTimeInterval parseJsonStartTime = CFAbsoluteTimeGetCurrent();
                                   NSError *mappingError = nil;
                                   IESEffectPlatformNewResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESEffectPlatformNewResponseModel class]
                                                                                             fromJSONDictionary:jsonDic[@"data"]
                                                                                                          error:&mappingError];
                                    if (responseModel.urlPrefix.count > 0) {
                                        platform.platformURLPrefix = [responseModel.urlPrefix copy];
                                    }
                                   if (mappingError || !responseModel) {
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           !completion ?: completion(mappingError, nil);
                                       });
                                       return;
                                   }
                                   
                                   [responseModel setPanelName:panel];
                                   [responseModel preProcessEffects];
        
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       !completion ?: completion(nil, responseModel);
                                   });
                                   [[EffectPlatform sharedInstance] _autoDownloadIfNeededWithNewModel:responseModel];
                               }];
    
}

#pragma mark - fetch Effect List
+ (void)fetchEffectListWithEffectIDS:(NSArray<NSString *> *)effectIDs
                          completion:(EffectPlatformFetchEffectListCompletion _Nullable)completion {
    [self fetchEffectListWithEffectIDS:effectIDs
                              gradeKey:nil
                            completion:completion];
}

+ (void)fetchEffectListWithEffectIDS:(NSArray<NSString *> *)effectIDs
                            gradeKey:(NSString *)gradeKey
                          completion:(EffectPlatformFetchEffectListCompletion _Nullable)completion {
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSString *urlString = [platform _urlWithPath:@"/effect/api/v3/effect/list"];
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    NSData *data = [NSJSONSerialization dataWithJSONObject:effectIDs
                                                   options:kNilOptions error:nil];
    if (data) {
        totalParameters[@"effect_ids"] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    if ([gradeKey isKindOfClass:[NSString class]]) {
        totalParameters[@"grade_key"] = gradeKey;
    }
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    [EffectPlatform _requestWithURLString:urlString
                               parameters:totalParameters
                               completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch effect list for effectIDs=%@|gradeKey=%@|error=%@", effectIDs, gradeKey, error);
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
               !completion ?: completion(error, nil, nil);
            });
            return;
        }
        NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
        if (serverError) {
            dispatch_async(dispatch_get_main_queue(), ^{
               !completion ?: completion(serverError, nil, nil);
            });
            return;
        }
        
        NSError *mappingError = nil;
        
        NSArray<IESEffectModel *> *effects = [MTLJSONAdapter modelsOfClass:[IESEffectModel class]
                                                            fromJSONArray:jsonDic[@"data"]
                                                                    error:&mappingError];
        if (mappingError) {
            dispatch_async(dispatch_get_main_queue(), ^{
               !completion ?: completion(mappingError, nil, nil);
            });
            return;
        }
        
        NSArray *collection = jsonDic[@"collection"];
        if (collection && [collection isKindOfClass:[NSArray class]] && collection.count > 0) {
            NSArray<IESEffectModel *> *collectionEffects = [MTLJSONAdapter modelsOfClass:[IESEffectModel class]
                                                                           fromJSONArray:collection
                                                                                   error:&mappingError];
            if (mappingError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                   !completion ?: completion(mappingError, nil, nil);
                });
                return;
            }
            for (IESEffectModel *effect in effects) {
                [effect updateChildrenEffectsWithCollection:collectionEffects];
            }
        }
        
        NSArray *binds = jsonDic[@"bind_effects"];
        NSArray<IESEffectModel *> *bindEffects = [[NSArray alloc] init];
        if (binds && [binds isKindOfClass:[NSArray class]] && binds.count > 0) {
            bindEffects = [MTLJSONAdapter modelsOfClass:[IESEffectModel class]
                                          fromJSONArray:binds
                                                  error:&mappingError];
            if (mappingError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    !completion ?: completion(mappingError, nil, nil);
                });
                return;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, effects, bindEffects);
        });
    }];
}

#pragma mark - Get Resourceids

+ (void)downloadEffectListWithResourceIds:(NSArray<NSString *> *)resourceIds
                                    panel:(NSString *)panel
                               completion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects))completion
{
    [EffectPlatform fetchEffectListWithResourceIds:resourceIds
                                             panel:panel
                                        completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects, NSArray<NSString *> * _Nullable urlPrefixs) {
        if (completion) {
            completion(error, effects);
        }
    }];
}

+ (void)fetchEffectListWithResourceIds:(NSArray<NSString *> *)resourceIds
                                 panel:(NSString *)panel
                            completion:(void (^)(NSError * _Nullable, NSArray<IESEffectModel *> * _Nullable, NSArray<NSString *> * _Nullable))completion {
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSString *urlString = [platform _urlWithPath:@"/effect/api/v3/effect/listByResourceId"];
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    NSData *data = nil;
    if ([NSJSONSerialization isValidJSONObject:resourceIds]) {
        data = [NSJSONSerialization dataWithJSONObject:resourceIds
                                                       options:kNilOptions error:nil];
    }
    
    if (data) {
        totalParameters[@"resource_ids"] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    totalParameters[@"panel"] = panel ?: @"";
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    [EffectPlatform _requestWithURLString:urlString
                               parameters:totalParameters
                               completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch effect list for resourceIds=%@|parameters=%@|error=%@", resourceIds, totalParameters, error);
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(error, nil, nil);
            });
            return;
        }
        NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
        if (serverError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(serverError, nil, nil);
            });
            return;
        }
        NSError *mappingError = nil;
        NSArray<IESEffectModel *> *effects = [MTLJSONAdapter modelsOfClass:[IESEffectModel class]
                                                             fromJSONArray:jsonDic[@"data"]
                                                                     error:&mappingError];
        if (mappingError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(mappingError, nil, nil);
            });
            return;
        }
        
        NSArray *collection = jsonDic[@"collection"];
        if (collection && [collection isKindOfClass:[NSArray class]] && collection.count > 0) {
            NSArray<IESEffectModel *> *collectionEffects = [MTLJSONAdapter modelsOfClass:[IESEffectModel class] fromJSONArray:collection error:&mappingError];
            if (mappingError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    !completion ?: completion(mappingError, nil, nil);
                });
                return;
            }
            for (IESEffectModel *effect in effects) {
                [effect updateChildrenEffectsWithCollection:collectionEffects];
            }
        }
        
        NSArray<NSString *> *urlPrefixs = jsonDic[@"url_prefix"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, effects, urlPrefixs);
        });
    }];
}

#pragma mark - UsedStickers

+ (void)fetchUserUsedStickersWithCompletion:(void (^)(NSError * _Nullable, NSArray<IESEffectModel *> * _Nullable))completion {
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    NSString *urlString = [platform _urlWithPath:@"/effect/api/user/usedSticker"];
    [EffectPlatform _requestWithURLString:urlString
                               parameters:totalParameters
                               completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch used sticker|error=%@", error);
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(error, nil);
            });
            return;
        }
        
        NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
        if (serverError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(serverError, nil);
            });
            return;
        }
        
        NSError *mappingError = nil;
        IESUserUsedStickerResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESUserUsedStickerResponseModel class]
                                                                   fromJSONDictionary:jsonDic error:&mappingError];
        if (mappingError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(mappingError, nil);
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, responseModel.effects);
        });
    }];
}

#pragma mark - Check Update

+ (void)checkEffectUpdateWithPanel:(NSString *)panel
                        completion:(void (^)(BOOL))completion
{
    [self checkEffectUpdateWithPanel:panel effectTestStatusType:IESEffectModelTestStatusTypeDefault completion:completion];
}

+ (void)checkEffectUpdateWithPanel:(NSString *)panel
              effectTestStatusType:(IESEffectModelTestStatusType)statusType
                        completion:(void (^)(BOOL))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *version = [[EffectPlatform sharedInstance] _effectCloudLibVersionWithPanel:panel];
        NSMutableDictionary *totalParameters = [[NSMutableDictionary alloc] init];
        totalParameters[@"panel"] = panel;
        totalParameters[@"version"] = version;
        if (statusType != IESEffectModelTestStatusTypeDefault) {
            totalParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusType];
        }
        [totalParameters addEntriesFromDictionary:[[EffectPlatform sharedInstance] _commonParameters]];
        if ([EffectPlatform sharedInstance].iopParametersBlock) {
            [totalParameters addEntriesFromDictionary:[EffectPlatform sharedInstance].iopParametersBlock() ?: @{}];
        }
        NSString *urlString = [[EffectPlatform sharedInstance] _urlWithPath:@"/effect/api/checkUpdate"];
        [EffectPlatform _requestWithURLString:urlString
                                   parameters:totalParameters
                                   completion:^(NSError * _Nonnull error, NSDictionary * _Nonnull json) {
            IESEffectLogInfo(@"check effect update|panel=%@|statusType=%@", panel, @(statusType));
            if (!error) {
                BOOL updated = [json[@"updated"] boolValue];
                dispatch_async(dispatch_get_main_queue(), ^{
                    !completion ?: completion(updated);
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    !completion ?: completion(NO);
                });
            }
        }];
    });
}

+ (void)thirdPartyStickerRecommandListWithCompletion:(void (^)(IESThirdPartyResponseModel *_Nullable response, NSError *_Nullable error))completion
{
    [self thirdPartyStickerRecommandListWithPageCount:0 cursor:0 completion:completion];
}

+ (void)thirdPartyStickerRecommendListWithType:(NSString *)type
                                    completion:(void (^)(IESThirdPartyResponseModel *_Nullable, NSError * _Nullable))completion {
    [self thirdPartyStickerRecommendListWithType:type
                                       pageCount:0
                                          cursor:0
                                      completion:completion];
}

+ (void)thirdPartyStickerRecommandListWithPageCount:(NSInteger)pageCount
                                             cursor:(NSInteger)cursor
                                         completion:(void (^)(IESThirdPartyResponseModel *_Nullable, NSError * _Nullable))completion {
    [self thirdPartyStickerRecommendListWithType:nil
                                       pageCount:pageCount
                                          cursor:cursor
                                      completion:completion];
}

+ (void)thirdPartyStickerRecommendListWithType:(NSString *)type
                                     pageCount:(NSInteger)pageCount
                                        cursor:(NSInteger)cursor
                                    completion:(void (^)(IESThirdPartyResponseModel * _Nullable, NSError * _Nullable))completion {
    [self thirdPartyStickerRecommendListWithType:type
                                       pageCount:pageCount
                                          cursor:cursor
                                 extraParameters:@{}
                                      completion:completion];
}

+ (void)thirdPartyStickerRecommendListWithType:(NSString *)type
                                     pageCount:(NSInteger)pageCount
                                        cursor:(NSInteger)cursor
                               extraParameters:(NSDictionary *)extraParameters
                                    completion:(void (^)(IESThirdPartyResponseModel * _Nullable, NSError * _Nullable))completion {
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSString *urlString = [platform _urlWithPath:@"/effect/api/stickers/recommend"];
    BOOL inValidParameters = NO;
    if (!platform.appId || !platform.osVersion) {
        inValidParameters = YES;
    }
    if (inValidParameters) {
        NSString *errorDiscription = [self _errorDescriptionMappingDic][@(IESEffectErrorParametorError)];
        NSError *error = [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain
                                             code:IESEffectErrorParametorError
                                         userInfo:@{NSLocalizedDescriptionKey: errorDiscription ?: @""}];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, error);
        });
        return;
    }

    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    if (pageCount != NSNotFound) {
        totalParameters[@"count"] = [NSString stringWithFormat:@"%ld", (long)pageCount];
    }
    if (cursor != NSNotFound) {
        totalParameters[@"cursor"] = [NSString stringWithFormat:@"%ld", (long)cursor];
    }
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    if (type && [type length] > 0) {
        totalParameters[@"library"] = type;
    }
    [totalParameters addEntriesFromDictionary:extraParameters];
    [EffectPlatform _requestWithURLString:urlString parameters:totalParameters completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch third-party sticker recommand|pageCount=%@|cursor=%@|error=%@", @(pageCount), @(cursor), error);
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(nil, error);
            });
            return;
        }
        NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
        if (serverError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(nil, serverError);
            });
            return;
        }
        NSError *mappingError;
        IESThirdPartyResponseModel *response = [MTLJSONAdapter modelOfClass:[IESThirdPartyResponseModel class]
                                                         fromJSONDictionary:jsonDic[@"data"]
                                                                      error:&mappingError];
        if ([jsonDic[@"_AME_Header_RequestID"] isKindOfClass:[NSString class]]) {
            response.requestID = jsonDic[@"_AME_Header_RequestID"];
        }
        if (mappingError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(nil, mappingError);
            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(response, nil);
        });
    }];
}

+ (void)thirdPartyStickefListWithKeyword:(NSString *)keyword completion:(void (^)(IESThirdPartyResponseModel *_Nullable response, NSError *_Nullable error))completion
{
    [self thirdPartyStickefListWithKeyword:keyword pageCount:NSNotFound cursor:NSNotFound completion:completion];
}

+ (void)thirdPartyStickefListWithKeyword:(NSString *)keyword type:(NSString *)type completion:(void (^)(IESThirdPartyResponseModel * _Nullable, NSError * _Nullable))completion
{
    [self thirdPartyStickefListWithKeyword:keyword type:nil pageCount:NSNotFound cursor:NSNotFound completion:completion];
}

+ (void)thirdPartyStickefListWithKeyword:(NSString *)keyword pageCount:(NSInteger)pageCount cursor:(NSInteger)cursor completion:(void (^)(IESThirdPartyResponseModel * _Nullable, NSError * _Nullable))completion
{
    [self thirdPartyStickefListWithKeyword:keyword type:nil pageCount:pageCount cursor:cursor completion:completion];
}

+ (void)thirdPartyStickefListWithKeyword:(NSString *)keyword
                                    type:(NSString *)type
                               pageCount:(NSInteger)pageCount
                                  cursor:(NSInteger)cursor
                              completion:(void (^)(IESThirdPartyResponseModel *_Nullable response, NSError *_Nullable error))completion {
    [self thirdPartyStickefListWithKeyword:keyword
                                      type:type
                                 pageCount:pageCount
                                    cursor:cursor
                           extraParameters:@{}
                                completion:completion];
}

+ (void)thirdPartyStickefListWithKeyword:(NSString *)keyword
                                    type:(NSString *)type
                               pageCount:(NSInteger)pageCount
                                  cursor:(NSInteger)cursor
                         extraParameters:(NSDictionary *)extraParameters
                              completion:(void (^)(IESThirdPartyResponseModel * _Nullable, NSError * _Nullable))completion {
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSString *urlString = [platform _urlWithPath:@"/effect/api/stickers/search"];
    BOOL inValidParameters = NO;
    if (!keyword || !platform.appId || !platform.osVersion) {
        inValidParameters = YES;
    }
    if (inValidParameters) {
        NSString *errorDiscription = [self _errorDescriptionMappingDic][@(IESEffectErrorParametorError)];
        NSError *error = [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain
                                             code:IESEffectErrorParametorError
                                         userInfo:@{NSLocalizedDescriptionKey: errorDiscription ?: @""}];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, error);
        });
        return;
    }
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    totalParameters[@"word"] = keyword;
    totalParameters[@"aid"] = platform.appId;
    totalParameters[@"os_version"] = platform.osVersion;
    if (pageCount != NSNotFound) {
        totalParameters[@"count"] = [NSString stringWithFormat:@"%ld", (long)pageCount];
    }
    if (cursor != NSNotFound) {
        totalParameters[@"cursor"] = [NSString stringWithFormat:@"%ld", (long)cursor];
    }
    if (type && [type length] > 0) {
        totalParameters[@"library"] = type;
    }
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    [totalParameters addEntriesFromDictionary:extraParameters];
    [EffectPlatform _requestWithURLString:urlString parameters:totalParameters completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch third-party sticker list|keyword|pageCount=%@|cursor=%@|error=%@", keyword, @(pageCount), @(cursor), error);
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(nil, error);
            });
            return;
        }
        NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
        if (serverError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(nil, serverError);
            });
            return;
        }
        NSError *mappingError;
        IESThirdPartyResponseModel *response = [MTLJSONAdapter modelOfClass:[IESThirdPartyResponseModel class]
                                                         fromJSONDictionary:jsonDic[@"data"]
                                                                      error:&mappingError];
        if ([jsonDic[@"_AME_Header_RequestID"] isKindOfClass:[NSString class]]) {
            response.requestID = jsonDic[@"_AME_Header_RequestID"];
        }
        if (mappingError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(nil, mappingError);
            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(response, nil);
        });
    }];
}

+ (void)fetchAndDownloadThirdPartyStickerListWithGifIDs:(NSString *)gifIDs
                                        extraParameters:(NSDictionary *)extraParameters
                                             completion:(void (^)(NSError * _Nullable,
                                                                  IESThirdPartyResponseModel * _Nullable,
                                                                  NSArray<IESThirdPartyStickerModel *> * _Nullable,
                                                                  NSArray<IESThirdPartyStickerModel *> * _Nullable))completion {
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSString *urlString = [platform _urlWithPath:@"/effect/api/stickers/list"];
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    totalParameters[@"gif_id"] = gifIDs;
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    [totalParameters addEntriesFromDictionary:extraParameters];
    [EffectPlatform _requestWithURLString:urlString
                             parameters:totalParameters
                             completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDict) {
        IESEffectLogInfo(@"fetch third-party sticker list|error=%@|gifIDs=%@", error, gifIDs);
        
        if (error) {
            IESEffectLogInfo(@"fetch third-party sticker list meets error=%@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(error, nil, nil, nil);
            });
            return;
        }
          
        NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDict];
        if (serverError) {
            IESEffectLogInfo(@"fetch third-party sticker list meets serverError=%@", serverError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(serverError, nil, nil, nil);
            });
            return;
        }
          
        NSError *mappingError = nil;
        IESThirdPartyResponseModel *gifsResponse = [MTLJSONAdapter modelOfClass:[IESThirdPartyResponseModel class]
                                                             fromJSONDictionary:jsonDict[@"data"][@"gifs"]
                                                                          error:&mappingError];
        if (mappingError) {
            IESEffectLogInfo(@"fetch third-party sticker list meets mappingError=%@", mappingError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(mappingError, nil, nil, nil);
            });
            return;
        }
          
        dispatch_group_t group = dispatch_group_create();
        NSMutableArray<IESThirdPartyStickerModel *> *downloadFailedStickers = [NSMutableArray array];
        NSMutableArray<IESThirdPartyStickerModel *> *downloadSuccessStickers = [NSMutableArray array];
        for (IESThirdPartyStickerModel *gifSticker in gifsResponse.stickerList) {
            dispatch_group_enter(group);
            [EffectPlatform downloadThirdPartyModel:gifSticker
                              downloadQueuePriority:NSOperationQueuePriorityNormal
                           downloadQualityOfService:NSQualityOfServiceDefault
                                           progress:^(CGFloat progress) {}
                                         completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                if (error || !filePath) {
                    [downloadFailedStickers addObject:gifSticker];
                } else {
                    [downloadSuccessStickers addObject:gifSticker];
                }
                dispatch_group_leave(group);
            }];
        }

        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *downloadError = nil;
            if (downloadSuccessStickers.count < gifsResponse.stickerList.count) {
                downloadError = [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain
                                                    code:IESEffectErrorDownloadFailed
                                                userInfo:@{NSLocalizedDescriptionKey : @"some or all gif stickers have been downloaded failed"}];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(downloadError, gifsResponse, downloadSuccessStickers, downloadFailedStickers);
            });
        });
    }];
}

+ (void)checkPanelUpdateWithPanel:(NSString *)panel
                       completion:(void (^)(BOOL needUpdate))completion
{
    [self checkPanelUpdateWithPanel:panel effectTestStatusType:IESEffectModelTestStatusTypeDefault completion:completion];
}

+ (void)checkPanelUpdateWithPanel:(NSString *)panel
             effectTestStatusType:(IESEffectModelTestStatusType)statusType
                       completion:(void (^)(BOOL needUpdate))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *version = [[EffectPlatform sharedInstance] _panelCloudLibVersioWithPanel:panel];
        NSMutableDictionary *totalParameters = [[NSMutableDictionary alloc] init];
        totalParameters[@"panel"] = panel;
        totalParameters[@"version"] = version;
        if (statusType != IESEffectModelTestStatusTypeDefault) {
            totalParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusType];
        }
        [totalParameters addEntriesFromDictionary:[[EffectPlatform sharedInstance] _commonParameters]];
        if ([EffectPlatform sharedInstance].iopParametersBlock) {
            [totalParameters addEntriesFromDictionary:[EffectPlatform sharedInstance].iopParametersBlock() ?: @{}];
        }
        NSString *urlString = [[EffectPlatform sharedInstance] _urlWithPath:@"/effect/api/panel/check"];
        [EffectPlatform _requestWithURLString:urlString
                                   parameters:totalParameters
                                   completion:^(NSError * _Nonnull error, NSDictionary * _Nonnull json) {
            IESEffectLogInfo(@"check panel update|panel=%@|statusType=%@", panel, @(statusType));
            if (!error) {
                BOOL updated = [json[@"updated"] boolValue];
                dispatch_async(dispatch_get_main_queue(), ^{
                    !completion ?: completion(updated);
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    !completion ?: completion(NO);
                });
            }
        }];
    });
}

+ (void)checkEffectUpdateWithPanel:(NSString *)panel
                          category:(NSString *)category
                        completion:(void (^)(BOOL needUpdate))completion;
{
    [self checkEffectUpdateWithPanel:panel category:category effectTestStatusType:IESEffectModelTestStatusTypeDefault completion:completion];
}

+ (void)checkEffectUpdateWithPanel:(NSString *)panel
                          category:(NSString *)category
              effectTestStatusType:(IESEffectModelTestStatusType)statusType
                        completion:(void (^)(BOOL needUpdate))completion;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *version = [[EffectPlatform sharedInstance] _categoryCloudLibVersioWithPanel:panel category:category];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableDictionary *totalParameters = [[NSMutableDictionary alloc] init];
            totalParameters[@"panel"] = panel ?: @"";
            totalParameters[@"category"] = category ?: @"";
            totalParameters[@"version"] = version ?: @"";
            if (statusType != IESEffectModelTestStatusTypeDefault) {
                totalParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusType];
            }
            [totalParameters addEntriesFromDictionary:[[EffectPlatform sharedInstance] _commonParameters]];
            if ([EffectPlatform sharedInstance].iopParametersBlock) {
                [totalParameters addEntriesFromDictionary:[EffectPlatform sharedInstance].iopParametersBlock() ?: @{}];
            }
            NSString *urlString = [[EffectPlatform sharedInstance] _urlWithPath:@"/effect/api/category/check"];
            [EffectPlatform _requestWithURLString:urlString
                                       parameters:totalParameters
                                       completion:^(NSError * _Nonnull error, NSDictionary * _Nonnull json) {
                IESEffectLogInfo(@"check panel update|panel=%@|category=%@|statusType=%@", panel, category, @(statusType));
                                           if (!error) {
                                               BOOL updated = [json[@"updated"] boolValue];
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   !completion ?: completion(updated);
                                               });
                                           }else {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   !completion ?: completion(NO);
                                               });
                                           }
                                       }];
        });
    });
}

#pragma mark - Request Utils

+ (void)requestWithURLString:(NSString *)urlString
                  parameters:(NSDictionary *)parameters
                  completion:(void (^)(NSError * _Nullable, NSDictionary * _Nullable))completion {
    [EffectPlatform _requestWithURLString:urlString
                               parameters:parameters
                               completion:completion];
}

+ (void)_requestWithURLString:(NSString *)urlString
                   parameters:(NSDictionary *)parameters
                   completion:(nonnull void (^)(NSError * _Nullable error, NSDictionary * _Nullable jsonDict))completion {
    [EffectPlatform _requestWithURLString:urlString
                               parameters:parameters
                                   cookie:nil
                               completion:completion];
}

+ (void)_requestWithURLString:(NSString *)urlString
                   parameters:(NSDictionary *)parameters
                       cookie:(NSString *)cookie
                   completion:(nonnull void (^)(NSError * _Nullable, NSDictionary * _Nullable))completion {
    [EffectPlatform _requestWithURLString:urlString
                               parameters:parameters
                                   cookie:cookie
                               httpMethod:@"GET"
                               completion:completion];
}

+ (void)_requestWithURLString:(NSString *)urlString
                   parameters:(NSDictionary *)parameters
                       cookie:(NSString *)cookie
                   httpMethod:(NSString *)httpMethod
                   completion:(nonnull void (^)(NSError * _Nullable, NSDictionary * _Nullable))completion {
    [[EffectPlatform sharedInstance] requestWithURLString:urlString
                                               parameters:parameters
                                                   cookie:cookie
                                               httpMethod:httpMethod
                                               completion:completion];
}

#pragma mark - Download

+ (void)downloadEffect:(IESEffectModel *)effectModel
              progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
            completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion
{
    [[IESEffectManager manager] downloadEffect:effectModel progress:progressBlock completion:^(NSString * _Nonnull path, NSError * _Nonnull error) {
        if (completion) {
            completion(error, path);
        }
    }];
}

+ (void)downloadEffect:(IESEffectModel *)effectModel
 downloadQueuePriority:(NSOperationQueuePriority)queuePriority
downloadQualityOfService:(NSQualityOfService)qualityOfService
              progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
            completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion
{
    [[IESEffectManager manager] downloadEffect:effectModel downloadQueuePriority:queuePriority downloadQualityOfService:qualityOfService progress:progressBlock completion:^(NSString * _Nonnull path, NSError * _Nonnull error) {
        if (completion) {
            completion(error, path);
        }
    }];
}

+ (void)downloadRequirements:(NSArray<NSString *> *)requirements
                  completion:(void (^)(BOOL success, NSError *error))completion
{
    if (requirements.count == 0) {
        !completion ?: completion(YES, nil);
        return;
    }
    
    [[IESEffectManager manager] downloadRequirements:requirements completion:completion];
}

+ (void)fetchResourcesWithRequirements:(NSArray<NSString *> *)requirements
                            modelNames:(NSDictionary<NSString *, NSArray<NSString *> *> *)modelNames
                            completion:(void (^)(BOOL success, NSError *error))completion {
    if (requirements.count == 0 && modelNames.count == 0) {
        !completion ?: completion(YES, nil);
        return;
    }
    
    [[IESEffectManager manager] fetchResourcesWithRequirements:requirements modelNames:modelNames completion:completion];
}

+ (void)fetchOnlineInfosAndResourcesWithModelNames:(NSArray<NSString *> *)modelNames
                                             extra:(NSDictionary *)parameters
                                        completion:(void (^)(BOOL success, NSError * error))completion {
    [[IESEffectManager manager] fetchOnlineInfosAndResourcesWithModelNames:modelNames extra:parameters completion:completion];
}

+ (NSDictionary<NSString *, IESAlgorithmRecord *> *)checkoutModelInfosWithRequirements:(NSArray<NSString *> *)requirements
                                                                            modelNames:(NSDictionary<NSString *, NSArray<NSString *> *> *)modelNames {

    return [[IESEffectManager manager] checkoutModelInfosWithRequirements:requirements modelNames:modelNames];
}

+ (void)downloadEffectWithURLS:(NSArray *)urls
                        toPath:(NSString *)path
              uncompressedPath:(NSString *)uncompressedPath
                           md5:(NSString *)md5
              trackingInfoDict:(NSDictionary *)trackingInfoDict
         downloadQueuePriority:(NSOperationQueuePriority)queuePriority
      downloadQualityOfService:(NSQualityOfService)qualityOfService
                      progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
                    completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion
{
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    if (!md5) {
        NSError *error = [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain code:IESEffectErrorFilePathNotFound userInfo:@{NSLocalizedDescriptionKey : @"md5 is nil"}];
        !completion ?: completion(error, nil);
        return;
    }
    [platform.infoDictLock lock];
    // 因为存在静默下载，可能一个下载任务会被触发多次，这里通过字典来保存两个 block
    NSMutableArray *completionBlocks = [EffectPlatform sharedInstance].downloadingCompletionDic[md5];
    NSMutableArray *progressBlocks = [EffectPlatform sharedInstance].downloadingProgressDic[md5];
    [platform.infoDictLock unlock];
    if (completionBlocks && progressBlocks) {
        [platform.infoDictLock lock];
        if (progressBlock) {
            [progressBlocks addObject:[progressBlock copy]];
        }
        if (completion) {
            [completionBlocks addObject:[completion copy]];
        }
        [platform.infoDictLock unlock];
        return;
    } else {
        completionBlocks = [NSMutableArray array];
        progressBlocks = [NSMutableArray array];
        if (progressBlock) {
            [progressBlocks addObject:[progressBlock copy]];
        }
        if (completion) {
            [completionBlocks addObject:[completion copy]];
        }
        [platform.infoDictLock lock];
        platform.downloadingCompletionDic[md5] = completionBlocks;
        platform.downloadingProgressDic[md5] = progressBlocks;
        [platform.infoDictLock unlock];
    }
    void(^wrapperProgressBlock)(CGFloat progress) = ^(CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [platform.infoDictLock lock];
            NSMutableArray *progressBlocks = [EffectPlatform sharedInstance].downloadingProgressDic[md5];
            for (EffectPlatformDownloadProgressBlock progressBlock in progressBlocks) {
                progressBlock(progress);
            }
            [platform.infoDictLock unlock];
        });
    };
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    void(^wrapperCompletion)(NSError *err, NSString *fp, NSDictionary *extraInfoDict) = ^(NSError *err, NSString *fp, NSDictionary *extraInfoDict){
        dispatch_async(platform.networkCallBackQueue, ^{
            NSError *error = err;
            NSString *filePath = fp;
            CFTimeInterval unzipStartTime = CFAbsoluteTimeGetCurrent();
            
            NSString *serviceName = @"effect_resource_unzip_success_rate";
            NSMutableDictionary *trackInfo = @{
                @"app_id" : platform.appId ?: @"",
                @"access_key" : platform.accessKey ?: @"",
                @"md5" : md5 ?: @"",
                @"download_urls" : urls ?: @[],
                @"uncompressed_path" : uncompressedPath ?: @"",
            }.mutableCopy;
            
            if (trackingInfoDict[@"effect_id"]) {
                trackInfo[@"effect_id"] = trackingInfoDict[@"effect_id"];
            }
            if (trackingInfoDict[@"resource_name"]) {
                trackInfo[@"resource_name"] = trackingInfoDict[@"resource_name"];
            }
            
            if (!error) {
                if (filePath) {
                    NSString *fileMD5 = [FileHash md5HashOfFileAtPath:filePath];
                    if (md5 && ![fileMD5 isEqualToString:md5]) {
                        NSString *errorString =
                        [NSString stringWithFormat: @"md5 is not matched. EffectMD5: %@, FileMD5: %@", md5, fileMD5];
                        NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionaryWithDictionary:@{NSLocalizedDescriptionKey : errorString}];
                        if (extraInfoDict) {
                            [errorUserInfo addEntriesFromDictionary:extraInfoDict];
                        }
                        error = [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain code:IESEffectErrorMD5NotMatched userInfo:[errorUserInfo copy]];
                        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                    }
                } else {
                    error = EffectPlatformEmptyFilePathError();
                }
                if (!error && uncompressedPath) {
                    unzipStartTime = CFAbsoluteTimeGetCurrent();
                    NSString *unzipTmpPath = [NSString stringWithFormat:@"%@_uncompress", uncompressedPath];
                    BOOL result = [SSZipArchive unzipFileAtPath:filePath toDestination:unzipTmpPath overwrite:YES password:nil error:&error];
                    if (result) {
                        NSError *moveError = nil;
                        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                        BOOL success = [[NSFileManager defaultManager] moveItemAtPath:unzipTmpPath toPath:uncompressedPath error:&moveError];
                        if (success) {
                            filePath = uncompressedPath;
                            
                            // track success
                            [platform.trackingDelegate postTracker:serviceName value:trackInfo status:0];
                        } else {
                            error = moveError ?: [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain code:IESEffectErrorUnzipFailed userInfo:@{NSLocalizedDescriptionKey : @"effect file unzip failed."}];
                            [[NSFileManager defaultManager] removeItemAtPath:uncompressedPath error:nil];
                            [[NSFileManager defaultManager] removeItemAtPath:unzipTmpPath error:nil];
                        }
                    } else {
                        // 解压失败，删除zip包和解压未完成的残余文件
                        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                        [[NSFileManager defaultManager] removeItemAtPath:uncompressedPath error:nil];
                        [[NSFileManager defaultManager] removeItemAtPath:unzipTmpPath error:nil];
                        error = [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain code:IESEffectErrorUnzipFailed userInfo:@{NSLocalizedDescriptionKey : @"effect file unzip failed."}];
                    }
                }
            }
            
            if (error) {
                // track error
                NSDictionary *extra = _addErrorInfoToTrackInfo(trackInfo, error);
                [platform.trackingDelegate postTracker:serviceName value:extra status:1];
            }
            
            [platform.infoDictLock lock];
            NSMutableArray *completionBlocks = platform.downloadingCompletionDic[md5];
            NSArray *completions = [completionBlocks copy];
            [platform.infoDictLock unlock];
            NSMutableDictionary *trackingDict = [@{ @"app_id" : platform.appId ?: @"",
                                                    @"access_key" : platform.accessKey ?: @""} mutableCopy];
            trackingDict[@"download_url"] = [urls componentsJoinedByString:@","] ?: @"";
            NSString *trackingName = @"";
            if (trackingInfoDict) {
                trackingName = trackingInfoDict[kTrackingName];
                NSMutableDictionary *mutableTrackingInfoDict = [trackingInfoDict mutableCopy];
                [mutableTrackingInfoDict removeObjectForKey:kTrackingName];
                [trackingDict addEntriesFromDictionary:mutableTrackingInfoDict];
            }
            if (extraInfoDict[IESEffectNetworkResponseStatus]) {
                trackingDict[@"http_status"] = extraInfoDict[IESEffectNetworkResponseStatus];
            }
            if (extraInfoDict[IESEffectNetworkResponseHeaderFields]) {
                trackingDict[@"http_header_fields"] = extraInfoDict[IESEffectNetworkResponseHeaderFields];
            }
            if (error) {
                trackingDict[@"error_code"] = @(error.code);
                trackingDict[@"error_msg"] = error.description ?: @"";
                trackingDict[@"error_domain"] = error.domain ?: @"";
            } else {
                trackingDict[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
                trackingDict[@"unzip_time"] = @((CFAbsoluteTimeGetCurrent() - unzipStartTime) * 1000);
                NSInteger fileSize = [EffectPlatform folderSizeAtPath:filePath];
                trackingDict[@"size"] = @(fileSize / 1024);
            }
            [platform.infoDictLock lock];
            [platform.downloadingCompletionDic removeObjectForKey:md5];
            [platform.downloadingProgressDic removeObjectForKey:md5];
            [platform.infoDictLock unlock];

            dispatch_async(dispatch_get_main_queue(), ^{
                for (EffectPlatformDownloadCompletionBlock completionBlock in completions) {
                    if (platform.trackingDelegate &&
                         trackingName.length > 0) {
                        [platform.trackingDelegate postTracker:trackingName
                                                         value:trackingDict
                                                        status:error ? 1 : 0];
                    }
                    completionBlock(error, error ? nil : filePath);
                }
            });
        });
    };
    [[IESFileDownloader sharedInstance] delegateDownloadFileWithURLs:urls
                                                        downloadPath:path
                                               downloadQueuePriority:queuePriority
                                            downloadQualityOfService:qualityOfService
                                                    downloadProgress:wrapperProgressBlock
                                                          completion:wrapperCompletion];

}

+ (void)downloadThirdPartyModel:(IESThirdPartyStickerModel *)thirdPartyModel
          downloadQueuePriority:(NSOperationQueuePriority)queuePriority
       downloadQualityOfService:(NSQualityOfService)qualityOfService
                       progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
                     completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion
{
    // 因为存在静默下载，可能一个下载任务会被触发多次，这里通过字典来保存两个 block
    [[EffectPlatform sharedInstance].infoDictLock lock];
    NSMutableArray *completionBlocks = [EffectPlatform sharedInstance].downloadingCompletionDic[thirdPartyModel.identifier];
    NSMutableArray *progressBlocks = [EffectPlatform sharedInstance].downloadingProgressDic[thirdPartyModel.identifier];
    [[EffectPlatform sharedInstance].infoDictLock unlock];
    if (completionBlocks && progressBlocks) {
        [progressBlocks addObject:[progressBlock copy]];
        [completionBlocks addObject:[completion copy]];
        return;
    } else {
        completionBlocks = [NSMutableArray array];
        progressBlocks = [NSMutableArray array];
        if (progressBlock) {
            [progressBlocks addObject:[progressBlock copy]];
        }
        if (completion) {
            [completionBlocks addObject:[completion copy]];
        }
        [[EffectPlatform sharedInstance].infoDictLock lock];
        [EffectPlatform sharedInstance].downloadingCompletionDic[thirdPartyModel.identifier] = completionBlocks;
        [EffectPlatform sharedInstance].downloadingProgressDic[thirdPartyModel.identifier] = progressBlocks;
        [[EffectPlatform sharedInstance].infoDictLock unlock];
    }
    void(^wrapperProgressBlock)(CGFloat progress) = ^(CGFloat progress) {
        [[EffectPlatform sharedInstance].infoDictLock lock];
        NSMutableArray *progressBlocks = [EffectPlatform sharedInstance].downloadingProgressDic[thirdPartyModel.identifier];
        [[EffectPlatform sharedInstance].infoDictLock unlock];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (EffectPlatformDownloadProgressBlock progressBlock in progressBlocks) {
                progressBlock(progress);
            }
        });
    };
    void(^wrapperCompletion)(NSError *err, NSString *fp, NSDictionary *dict) = ^(NSError *err, NSString *fp, NSDictionary *dict){
        dispatch_async([EffectPlatform sharedInstance].networkCallBackQueue, ^{
            NSError *error = err;
            if (!error && !fp) {
                error = EffectPlatformEmptyFilePathError();
            }
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSString *toPath = IESThirdPartyModelPathWithIdentifier(thirdPartyModel.sticker.url.lastPathComponent);
            if (!error && fp && [fileManager fileExistsAtPath:fp]) {
                NSString *folder = [toPath stringByDeletingLastPathComponent];
                if ([fileManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error]) {
                    if ([fileManager fileExistsAtPath:toPath]) {
                        [fileManager removeItemAtPath:toPath error:&error];
                    }
                    if (!error) {
                        [fileManager moveItemAtPath:fp toPath:toPath error:&error];
                    }
                }
            }
            [[EffectPlatform sharedInstance].infoDictLock lock];
            NSMutableArray *completionBlocks = [EffectPlatform sharedInstance].downloadingCompletionDic[thirdPartyModel.identifier];
            [[EffectPlatform sharedInstance].infoDictLock unlock];
            dispatch_async(dispatch_get_main_queue(), ^{
                for (EffectPlatformDownloadCompletionBlock completionBlock in completionBlocks) {
                    completionBlock(error, error ? nil : toPath);
                }
            });
            [[EffectPlatform sharedInstance].infoDictLock lock];
            [[EffectPlatform sharedInstance].downloadingCompletionDic removeObjectForKey:thirdPartyModel.identifier];
            [[EffectPlatform sharedInstance].downloadingProgressDic removeObjectForKey:thirdPartyModel.identifier];
            [[EffectPlatform sharedInstance].infoDictLock unlock];
        });
    };
    if (!thirdPartyModel.sticker.url || thirdPartyModel.sticker.url.length == 0) {
        [[EffectPlatform sharedInstance].infoDictLock lock];
        NSMutableArray *completionBlocks = [EffectPlatform sharedInstance].downloadingCompletionDic[thirdPartyModel.identifier];
        [[EffectPlatform sharedInstance].infoDictLock unlock];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = EffectPlatformEmptyFilePathError();
            for (EffectPlatformDownloadCompletionBlock completionBlock in completionBlocks) {
                completionBlock(error, nil);
            }
        });
        [[EffectPlatform sharedInstance].infoDictLock lock];
        [[EffectPlatform sharedInstance].downloadingCompletionDic removeObjectForKey:thirdPartyModel.identifier];
        [[EffectPlatform sharedInstance].downloadingProgressDic removeObjectForKey:thirdPartyModel.identifier];
        [[EffectPlatform sharedInstance].infoDictLock unlock];
        return;
    }
    NSString *downloadName = [NSString stringWithFormat:@"%ld_%@", (NSInteger)(NSDate.date.timeIntervalSince1970 * 1000), thirdPartyModel.identifier];
    NSString *downloadPath = [NSTemporaryDirectory() stringByAppendingPathComponent:downloadName];
    [[IESFileDownloader sharedInstance] delegateDownloadFileWithURLs:@[thirdPartyModel.sticker.url]
                                                        downloadPath:downloadPath
                                               downloadQueuePriority:queuePriority
                                            downloadQualityOfService:qualityOfService
                                                    downloadProgress:wrapperProgressBlock
                                                          completion:wrapperCompletion];
}


+ (void)downloadMyEffectListWithPanel:(NSString *)panel completion:(void (^)(NSError * _Nullable, NSArray<IESMyEffectModel *> * _Nullable))completion
{
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSString *urlString = [platform _urlWithPath:@"/effect/api/v3/effect/my"];
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    totalParameters[@"panel"] = panel;
    [totalParameters addEntriesFromDictionary:[[EffectPlatform sharedInstance] _commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    [EffectPlatform _requestWithURLString:urlString
                               parameters:totalParameters
                                   cookie:nil
                               completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
                                   if (error) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           !completion ?: completion(error, nil);
                                       });
                                       return;
                                   }
                                   NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
                                   if (serverError) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           !completion ?: completion(serverError, nil);
                                       });
                                       return;
                                   }
                                   NSError *mappingError;
                                   NSArray<IESMyEffectModel *> *myEffects = [MTLJSONAdapter modelsOfClass:[IESMyEffectModel class]
                                                                                            fromJSONArray:jsonDic[@"data"]
                                                                                                    error:&mappingError];
                                   for (IESMyEffectModel *myEffectModel in myEffects) {
                                       [myEffectModel updateEffects];
                                   }
                                   
                                   if (mappingError) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           !completion ?: completion(mappingError, nil);
                                       });
                                       return;
                                   }
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       !completion ?: completion(nil, myEffects);
                                   });
                               }];
}

#pragma mark - Update

+ (void)changeEffectsFavoriteWithEffectIDs:(NSArray<NSString *> *)effectIDS panel:(NSString *)panel addToFavorite:(BOOL)favorite completion:(void (^)(BOOL, NSError * _Nullable))completion
{
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSString *urlString = [platform _urlWithPath:@"/effect/api/v3/effect/favorite"];
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    totalParameters[@"effect_ids"] = effectIDS;
    totalParameters[@"type"] = @(favorite ? 1 : 0);
    totalParameters[@"panel"] = panel;
    [totalParameters addEntriesFromDictionary:[[EffectPlatform sharedInstance] _commonParameters]];
    [EffectPlatform _requestWithURLString:urlString
                               parameters:totalParameters
                                   cookie:nil
                               httpMethod:@"POST"
                               completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
                                   if (error) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           !completion ?: completion(NO, error);
                                       });
                                       return;
                                   }
                                   NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
                                   if (serverError) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           !completion ?: completion(NO, serverError);
                                       });
                                       return;
                                   } else {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           !completion ?: completion(YES, nil);
                                       });
                                   }
                               }];
    
}

#pragma mark - Download Moji Resource Bundle

+ (void)downloadMojiResourceWithIDMap:(NSString *)idMap completion:(nonnull void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    totalParameters[@"id_map"] = idMap ?: @"";
    [totalParameters addEntriesFromDictionary:[platform _commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    NSString *urlString = [platform _urlWithPath:@"/effect/api/moji/resource"];
    [EffectPlatform _requestWithURLString:urlString parameters:totalParameters completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(nil, error);
            });
            return;
        }
        NSError *serverError = [EffectPlatform _serverErrorFromJSON:jsonDic];
        if (serverError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(nil, serverError);
            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(jsonDic, nil);
        });
    }];
}

+ (void)downloadResourceWithEffectResourceModel:(IESEffectResourceModel *)model
                                       progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
                                     completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion
{
    if (model.resourceURI && model.resourceURI.length) {
        NSString *md5 = model.resourceURI;
        NSString *path = IESComposerResourceZipDirWithMD5(md5);
        NSString *uncompressPath = IESComposerResourceUncompressDirWithMD5(md5);
        NSMutableDictionary *trackingDict = [NSMutableDictionary dictionary];
        trackingDict[kTrackingName] = @"moji_resource_download_sucess_rate";
        trackingDict[@"name"] = model.name;
        trackingDict[@"value"] = model.value;
        [EffectPlatform downloadEffectWithURLS:model.fileDownloadURLs
                                        toPath:path
                              uncompressedPath:uncompressPath
                                           md5:md5
                              trackingInfoDict:trackingDict.copy
                         downloadQueuePriority:NSOperationQueuePriorityNormal
                      downloadQualityOfService:NSQualityOfServiceDefault
                                      progress:progressBlock
                                    completion:completion];
    } else {
        completion ? completion(nil, nil) : nil;
    }
}

+ (BOOL)isRequirementsDownloaded:(NSArray<NSString *> *)requirements
{
    return [[IESEffectManager manager] isAlgorithmRequirementsDownloaded:requirements];
}

+ (nullable NSString *)effectPathForEffectMD5:(NSString *)effectMD5 {
    if (!effectMD5) {
        return nil;
    }

    return [[IESEffectManager manager] effectPathForEffectMD5:effectMD5];
}

#pragma mark - Utils

#pragma mark - Public Functions

- (NSString *)urlWithPath:(NSString *)path
{
    return [self _urlWithPath:path];
}

+ (NSError *)serverErrorFromJSON:(NSDictionary *)jsonDic
{
    return [EffectPlatform _serverErrorFromJSON:jsonDic];
}

+ (NSDictionary *)errorDescriptionMappingDic
{
    return [EffectPlatform _errorDescriptionMappingDic];
}

- (NSString *)effectCloudLibVersionWithPanel:(NSString *)panel {
    return [self _effectCloudLibVersionWithPanel:panel];
}

#pragma mark - Private Functions
- (NSString *)_effectCloudLibVersionWithPanel:(NSString *)panel
{
    return [self.cache objectWithKey:ResponseCacheKeyWithPanel(panel)].version ?: @"";
}

- (NSString *)_panelCloudLibVersioWithPanel:(NSString *)panel
{
    return [self.cache newResponseWithKey:ResponseCacheKeyWithPanelForNew(panel)].version ?: @"";
}

- (NSString *)_categoryCloudLibVersioWithPanel:(NSString *)panel category:(NSString *)category
{
    return [self.cache newResponseWithKey:ResponseCacheKeyWithPanelAndCategoryAndCursor(panel, category, 0, 0)].categoryEffects.version ?: @"";
}

- (NSString *)_urlWithPath:(NSString *)path
{
    return [NSString stringWithFormat:@"%@%@", self.domain, path];
}

+ (NSError *)_serverErrorFromJSON:(NSDictionary *)jsonDic
{
    NSNumber *statusCode = jsonDic[@"status_code"];
    if ([statusCode intValue] == 0) {
        return nil;
    }
    NSString *errorDiscription = [EffectPlatform _errorDescriptionMappingDic][statusCode];
    if (errorDiscription.length == 0) {
        errorDiscription = jsonDic[@"message"];
    }
    NSError *serverError = [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain
                                               code:[statusCode integerValue]
                                           userInfo:@{NSLocalizedDescriptionKey: errorDiscription ?: @""}];
    return serverError;
}

+ (NSDictionary *)_errorDescriptionMappingDic
{
    return @{
             @(IESEffectErrorUnknowError) : @"unkown error",
             @(IESEffectErrorNotLoggedIn) : @"user not login",
             @(IESEffectErrorParametorError) : @"Illegal parameter (missing or wrong parameter)",
             @(IESEffectErrorIllegalAccessKey) : @"access_key illegal",
             @(IESEffectErrorIllegalAppVersion) : @"app_version illegal",
             @(IESEffectErrorIllegalSDKVersion) : @"sdk_version illegal",
             @(IESEffectErrorIllegalDeviceId) : @"device_id illegal",
             @(IESEffectErrorIllegalDevicePlatform) : @"device_platform illegal",
             @(IESEffectErrorIllegalDeviceType) : @"device_type illegal",
             @(IESEffectErrorIllegalChannel) : @"channel illegal",
             @(IESEffectErrorIllegalAppChannel) : @"app_channel illegal",
             @(IESEffectErrorIllegalPanel) : @"panel illegal",
             @(IESEffectErrorCurrentAppIsNotTestApp) : @"The current application is not a test application",
             @(IESEffectErrorIllegalApp) : @"The current application is not a test application",
             @(IESEffectErrorAccessKeyNotExists) : @"access_key not exist",
             };
}

+ (long long)fileSizeAtPath:(NSString *) filePath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

+ (long long)fileSizeAtPathC:(NSString *) filePath
{
    struct stat st;
    if (lstat([filePath cStringUsingEncoding:NSUTF8StringEncoding], &st) == 0) {
        return st.st_size;
    }
    return 0;
}

+ (long long )folderSizeAtPath:(NSString*) folderPath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath])
        return 0;
    NSString* fileName = [folderPath copy];
    long long folderSize = 0;
    
    BOOL isdir;
    [manager fileExistsAtPath:fileName isDirectory:&isdir];
    if (isdir != YES) {
        return [self fileSizeAtPath:fileName];
    } else {
        NSArray * items = [manager contentsOfDirectoryAtPath:fileName error:nil];
        for (int i =0; i<items.count; i++) {
            BOOL subisdir;
            NSString* fileAbsolutePath = [fileName stringByAppendingPathComponent:items[i]];
            
            [manager fileExistsAtPath:fileAbsolutePath isDirectory:&subisdir];
            if (subisdir==YES) {
                folderSize += [self folderSizeAtPath:fileAbsolutePath]; //文件夹就递归计算
            } else {
                folderSize += [self fileSizeAtPathC:fileAbsolutePath];//文件直接计算
            }
        }
    }
    return folderSize;
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

#pragma mark - monitor
NSDictionary * addErrorInfoToTrackInfo(NSDictionary *trackInfo, NSError *error) {
    return _addErrorInfoToTrackInfo(trackInfo, error);
}

NSDictionary * _addErrorInfoToTrackInfo(NSDictionary *trackInfo, NSError *error) {
    NSMutableDictionary *errorInfo = @{
        @"error_code" : @(error.code),
        @"error_msg" : error.description ?: @"",
        @"error_domain" : error.domain ?: @"",
    }.mutableCopy;
    
    [errorInfo addEntriesFromDictionary:trackInfo];
    errorInfo[@"status"] = @(1);
    return errorInfo.copy;
}

@end


@implementation EffectPlatform (DEPRECATED)

+ (void)downloadEffectListWithEffectIDS:(NSArray<NSString *> *)effectIDs
                             completion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects))completion {
    [self downloadEffectListWithEffectIDS:effectIDs
                                 gradeKey:nil
                               completion:completion];
}

+ (void)downloadEffectListWithEffectIDS:(NSArray<NSString *> *)effectIDs
                               gradeKey:(NSString *)gradeKey
                             completion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects))completion {
    [self fetchEffectListWithEffectIDS:effectIDs gradeKey:gradeKey completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects, NSArray<IESEffectModel *> * _Nullable bindEffects) {
        if (completion) {
            completion(error, effects);
        }
    }];
}

#pragma mark - Auto Clean Cache For Special Effect

- (void)trimDiskCacheToSize:(NSUInteger)fireSize targetSize:(NSUInteger)targetSize completion:(void(^)(NSDictionary *params, NSError * _Nullable error))completion;
{
    if (self.cacheCleanStatus == IESCacheCleanStatusStart || !fireSize || targetSize > fireSize) {
        return;
    }
    if (fireSize >= NSUIntegerMax / (1024 * 1024)) {
        fireSize = NSUIntegerMax;
    } else {
        fireSize = fireSize * 1024 * 1024;
    }
    if (targetSize >= NSUIntegerMax / (1024 * 1024)) {
        targetSize = NSUIntegerMax;
    } else {
        targetSize = targetSize * 1024 * 1024;
    }
    __weak typeof(self) weakSelf = self;
    self.autoCacheCleanBlock = dispatch_block_create(0, ^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf p_trimDiskCacheToSize:fireSize targetSize:targetSize completion:completion];
    });
    
    dispatch_async(self.ioQueue, self.autoCacheCleanBlock);
}

- (void)cancelCacheCleanIfNeeded
{
    if (self.cacheCleanStatus == IESCacheCleanStatusStart) {
        if (self.autoCacheCleanBlock) {
            dispatch_block_cancel(self.autoCacheCleanBlock);
            self.autoCacheCleanBlock = nil;
        }
        self.cacheCleanStatus = IESCacheCleanStatusCancel;
    }
}

- (void)addAllowList:(NSArray<NSString *> *)list
{
    [_lock lock];
    if (!self.allowPanelList) {
        self.allowPanelList = [[NSArray alloc] init];
    }
    NSMutableArray *arr = self.allowPanelList.mutableCopy;
    [arr addObjectsFromArray:list];
    self.allowPanelList = arr;
    [_lock unlock];
}

- (NSArray<IESEffectModel *> *)getEffectsFromCategories:(NSArray<IESCategoryModel *> *)categories
{
    NSArray<IESEffectModel *> *effects = [[NSArray alloc] init];
    for (IESCategoryModel *category in categories) {
        effects = [effects arrayByAddingObjectsFromArray:category.effects];
    }
    return effects.copy;
}
 
- (void)getEffectAllowListWithCompletion:(void(^)(NSDictionary * _Nullable effectAllowList))completionBlock
{
    __block NSMutableDictionary<NSString *, NSNumber *> *effectAllowList = @{}.mutableCopy;
    __block BOOL cancel = NO;
    
    [_lock lock];
    __block NSInteger count = self.allowPanelList.count;
    __weak typeof(self) weakSelf = self;
    [self.allowPanelList enumerateObjectsUsingBlock:^(NSString * _Nonnull panelName, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong typeof(self) strongSelf = weakSelf;
        IESEffectPlatformResponseModel *cacheResponse = [EffectPlatform cachedEffectsOfPanel:panelName];
        NSArray<IESEffectModel *> *effects;
        if (cacheResponse.categories.count) {
            effects = [strongSelf getEffectsFromCategories:cacheResponse.categories];
        } else {
            effects = cacheResponse.effects;
        }
        if (effects.count > 0) {
            [effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.childrenEffects.count > 0) {
                    for (IESEffectModel *effect in obj.childrenEffects) {
                        [effectAllowList setObject:@(YES) forKey:effect.md5];
                    }
                } else {
                    [effectAllowList setObject:@(YES) forKey:obj.md5];
                }
            }];
            if (--count == 0) {
                !completionBlock ? : completionBlock(effectAllowList.copy);
                *stop = YES;
                return ;
            }
        } else {
            [EffectPlatform downloadEffectListWithPanel:panelName completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                __strong typeof(self) strongSelf = weakSelf;
                if (!error && response) {
                    NSArray<IESEffectModel *> *effects;
                    if (response.categories.count) {
                        effects = [strongSelf getEffectsFromCategories:response.categories];
                    } else {
                        effects = cacheResponse.effects;
                    }
                    [effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (obj.childrenEffects.count > 0) {
                            for (IESEffectModel *effect in obj.childrenEffects) {
                                [effectAllowList setObject:@(YES) forKey:effect.md5];
                            }
                        } else {
                            [effectAllowList setObject:@(YES) forKey:obj.md5];
                        }
                    }];
                    if (--count == 0) {
                        dispatch_async(strongSelf.ioQueue, ^{
                            !completionBlock ? : completionBlock(effectAllowList.copy);
                        });
                        return ;
                    }
                } else {
                    cancel = YES;
                }
            }];
            if (cancel) {
                !completionBlock ? : completionBlock(nil);
                *stop = YES;
                return ;
            }
        }
    }];
    [_lock unlock];
}

- (void)p_deleteResourceFilesWithEffectAllowList:(NSDictionary * _Nullable)effectAllowList
                                     unusedFiles:(NSDictionary<NSString *, NSNumber *> *)unusedFiles
                                       cacheSize:(NSUInteger)cacheSize
                                       threshold:(NSUInteger)targetThreshold
                                           param:(NSDictionary *)paramDic
                                       startTime:(NSTimeInterval)startTime
                                      completion:(void(^)(NSDictionary *params, NSError * _Nullable error))completion
{
    __block NSError *error;
    __block NSInteger *failCount = 0;
    __block BOOL isCancelled = NO;
    __block NSInteger deleteFilesNum = 0;
    NSMutableArray<NSDictionary *> *deleteFiles = [[NSMutableArray alloc] init];
    __block NSUInteger remainedSize = cacheSize;
    NSMutableDictionary *params = paramDic.mutableCopy;
    NSArray<EffectCacheInfo *> *cacheArray = [self fetchAllResourceCacheInOrder];
    
    __weak typeof(self) weakSelf = self;
    [unusedFiles enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.cacheCleanStatus == IESCacheCleanStatusCancel) {
            isCancelled = YES;
            *stop = YES;
            return ;
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:key]) {
            if ([[effectAllowList objectForKey:[key lastPathComponent]] boolValue]) {
                return ;
            }
            if ([[NSFileManager defaultManager] removeItemAtPath:key error:&error]) {
                NSUInteger fileSize = [unusedFiles[key] longLongValue];
                remainedSize -= fileSize;
                deleteFilesNum ++;
                if (remainedSize <= targetThreshold) {
                    *stop = YES;
                    return ;
                }
            } else {
                failCount ++;
                error = [NSError errorWithDomain:error.domain code:error.code userInfo:@{NSLocalizedDescriptionKey: error.localizedDescription, @"errorInfo" : [NSString stringWithFormat:@"clean failed with path = %@, failed files count = %ld", key, (long)failCount]}];
            }
        }
    }];
    if (isCancelled) {
        [self cancelEffectCacheCleanWithParamDic:params.copy completion:completion];
        return;
    }
    for (EffectCacheInfo *info in cacheArray) {
        if (self.cacheCleanStatus == IESCacheCleanStatusCancel) {
            [self cancelEffectCacheCleanWithParamDic:params.copy completion:completion];
            return;
        }
        NSString *fileName = info.resourceName;
        NSString *fullPath = FullPathOfSubPath(IES_EFFECT_UNCOMPRESS_FOLDER_PATH);
        NSString *path = [fullPath stringByAppendingPathComponent:fileName];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            if (remainedSize <= targetThreshold) {
                break;
            }
            if ([[effectAllowList objectForKey:fileName] boolValue]) {
                continue;
            }
            if ([[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
                remainedSize -= info.cacheSize;
                [self deleteCacheItemWithResourceName:info.resourceName ? : @""];
                deleteFilesNum ++;
                //清理的缓存资源包信息
                [dateFormatter setDateFormat:@"yyyyMMdd HH:mm:ss"];
                NSString *lastAccessDateStr = [dateFormatter stringFromDate:info.lastAccessDate];
                
                NSMutableDictionary *params = @{}.mutableCopy;
                params[@"effectName"] = info.effectName;
                params[@"lastAccessDate"] = lastAccessDateStr;
                [deleteFiles addObject:params.copy];
            } else {
                failCount ++;
                error = [NSError errorWithDomain:error.domain code:error.code userInfo:@{NSLocalizedDescriptionKey: error.localizedDescription, @"errorInfo" : [NSString stringWithFormat:@"clean failed with path = %@, failed files count = %ld", path, (long)failCount]}];
            }
        }
    }

    params[@"total_time"] = @(CACurrentMediaTime() - startTime);
    params[@"complete_status"] = @(IESCacheCleanStatusFinished);
    params[@"complete_desc"] = @"finished";
    params[@"delete_files_num"] = @(deleteFilesNum);
    params[@"delete_files_size"] = @((cacheSize - remainedSize) / (1024.f * 1024.f));

    params[@"delete_files_info"] = deleteFiles.copy;
    if (completion) {
        completion(params.copy, error);
    }
    self.cacheCleanStatus = IESCacheCleanStatusDefault;
}

- (void)cancelEffectCacheCleanWithParamDic:(NSDictionary *)paramDic completion:(void(^)(NSDictionary *params, NSError * _Nullable error))completion
{
    NSMutableDictionary *params = paramDic.mutableCopy;
    self.cacheCleanStatus = IESCacheCleanStatusDefault;
    params[@"complete_status"] = @(IESCacheCleanStatusCancel);
    params[@"complete_desc"] = @"cancelled";
    if (completion) {
        completion(params.copy, nil);
    }
}

- (void)p_trimDiskCacheToSize:(NSUInteger)fireSize targetSize:(NSUInteger)targetSize completion:(void(^)(NSDictionary *params, NSError * _Nullable error))completion
{
    NSTimeInterval startTime = CACurrentMediaTime();
    self.cacheCleanStatus = IESCacheCleanStatusStart;
    NSString *fullPath = FullPathOfSubPath(IES_EFFECT_UNCOMPRESS_FOLDER_PATH);
    __block NSUInteger cacheSize = 0;
    __block NSMutableDictionary *params = @{}.mutableCopy;
    NSMutableDictionary<NSString *, NSNumber *> * unusedFiles = @{}.mutableCopy;
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:nil];
    for (NSString *content in contents) {
        if (self.cacheCleanStatus == IESCacheCleanStatusCancel) {
            [self cancelEffectCacheCleanWithParamDic:params.copy completion:completion];
            return;
        }
        NSString *path = [fullPath stringByAppendingPathComponent:content];
        NSUInteger fileSize = [EffectPlatform folderSizeAtPath:path];
        cacheSize += fileSize;
        if (![self containsResourceWithFileName:content]) {
            unusedFiles[path] = @(fileSize);
        }
    }

    params[@"cache_path"] = fullPath;
    params[@"cache_total_size"] = @(cacheSize / (1024.f * 1024.f));
    params[@"total_files_num"] = @(contents.count);
    if (cacheSize <= fireSize) {
        self.cacheCleanStatus = IESCacheCleanStatusDefault;
        if (completion) {
            params[@"complete_status"] = @(IESCacheCleanStatusDefault);
            params[@"complete_desc"] = @"no_clean";
            completion(params.copy, nil);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self getEffectAllowListWithCompletion:^(NSDictionary * _Nullable effectAllowList) {
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.allowPanelList.count && !effectAllowList) {
            [strongSelf cancelEffectCacheCleanWithParamDic:params.copy completion:completion];
            return ;
        }
        NSUInteger targetThreshold = targetSize;
        [strongSelf p_deleteResourceFilesWithEffectAllowList:effectAllowList
                                                 unusedFiles:unusedFiles.copy
                                                   cacheSize:cacheSize
                                                   threshold:targetThreshold
                                                       param:params.copy
                                                   startTime:startTime
                                                  completion:completion];
    }];
}

- (void)deleteCacheItemWithResourceName:(NSString *)resourceName
{
    if (resourceName) {
        __weak typeof(self) weakSelf = self;
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            __strong typeof(self) strongSelf = weakSelf;
            BOOL success = [db executeUpdate:@"DELETE FROM  EffectCacheModel WHERE resourceName=?", resourceName];
            if (!success) {
              NSError *error = [NSError errorWithDomain:db.lastError.domain code:db.lastErrorCode userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"[-deleteCacheItemWithResourceName] effect delete DB failed: file name:%@, errorMsg: %@", resourceName, db.lastErrorMessage]}];
              if (strongSelf.dbErrorBlock) {
                  strongSelf.dbErrorBlock(error);
              }
            }
        }];
    }
}

- (NSArray<EffectCacheInfo *> *)fetchAllResourceCacheInOrder
{
    __block NSMutableArray<EffectCacheInfo *> *arr = [[NSMutableArray alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        __strong typeof(self) strongSelf = weakSelf;
        FMResultSet *result = [db executeQuery:@"SELECT * FROM EffectCacheModel ORDER by lastAccessDate ASC"];
        if (![result next]) {
            NSError *error = [NSError errorWithDomain:db.lastError.domain code:db.lastErrorCode userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"[-fetchAllResourceCacheInOrder] effect fetch DB failed, errorMsg: %@", db.lastErrorMessage]}];
            if (strongSelf.dbErrorBlock) {
                strongSelf.dbErrorBlock(error);
            }
        }
        while ([result next]) {
            EffectCacheInfo *info = [[EffectCacheInfo alloc] init];
            info.resourceName = [result stringForColumn:@"resourceName"];
            info.effectName = [result stringForColumn:@"effectName"];
            info.lastAccessDate = [result dateForColumn:@"lastAccessDate"];
            info.cacheSize = [result unsignedLongLongIntForColumn:@"cacheSize"];
            [arr addObject:info];
        }
        [result close];
    }];
    return arr.copy;
}

//查询是否存在资源
- (BOOL)containsResourceWithFileName:(NSString *)resourceName
{
    __block BOOL isExist = NO;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *result;
        @try {
            result = [db executeQuery:@"SELECT * FROM EffectCacheModel WHERE resourceName=?", resourceName];
        } @catch (NSException *exception) {
            IESEffectLogError(@"containsResourceWithFileName error:%@", db.lastError);
        }
        if ([result next]) {
            isExist = YES;
        }
        [result close];
    }];
    return isExist;
}


@end
