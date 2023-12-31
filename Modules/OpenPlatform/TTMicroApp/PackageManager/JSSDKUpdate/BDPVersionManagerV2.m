//
//  BDPVersionManager.m
//  Timor
//
//  Created by muhuai on 2018/2/7.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import "BDPVersionManagerV2.h"
#import "BDPAppPageFactory.h"
#import <OPFoundation/BDPBundle.h>
#import "BDPDefineBase.h"
#import <ECOInfra/BDPFileSystemHelper.h>
#import "BDPJSRuntimePreloadManager.h"
#import <OPFoundation/BDPMacroUtils.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPNetworking.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import "BDPStorageManager.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPUserAgent.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/NSURLSession+TMA.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <ECOInfra/OPError.h>
#import <SSZipArchive/SSZipArchive.h>
#include <sys/time.h>
#import <ECOInfra/BDPUtils.h>
#import "OPVersionDirHandler.h"
#import <OPFoundation/EEFeatureGating.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import "BDPTimorClient+Business.h"
#import <OPFoundation/BDPVersionManager.h>
#import "coder.h"
#import <LarkStorage/LarkStorage-swift.h>

#define kBDPErrorVersion @"-1"


// 迁移到 BDPVersionManager.m 中，解耦EMAConfig.m 对 kLocalTMASwitchKeyV2 依赖
//NSString * const kLocalTMASwitchKeyV2 = @"TMAkLocalTMASwitchKey";
NSString * const kBDPLocalTestEnableKeyV2 = @"kBDPLocalTestEnableKey";

NSString * const kBDPJSLibGreyHashFileNameV2 = @"greyHash";

// 对应正则表达'^(\d+)\.(\d+)(\.\d+)?' lark版本判断正则
NSString * const kLarkVersionRegexV2 = @"^(\\d+)\\.(\\d+)(\\.\\d+)?";

static size_t fsize(FILE* f) {
    fseek(f, 0, SEEK_END);   // seek to end of file
    size_t size = ftell(f);  // get current file pointer
    fseek(f, 0, SEEK_SET);   // seek back to beginning of file
    return size;
}

// 时间统计
static uint64_t getTimeInNanoSec()
{
    struct timeval currTime;
    gettimeofday(&currTime, NULL);
    return (uint64_t)currTime.tv_sec * 1000000 + (uint64_t)currTime.tv_usec;
}
static NSDictionary <NSNumber *,NSString *> * gRawJSBundleVersionMap = nil; // 未格式化的版本静态值，数字
static NSDictionary <NSNumber *,NSString *> * gRawJSBundleFormatVersionMap = nil;  // 格式化的四位版本，x.x.x.x
static NSDictionary <NSNumber *,NSString *> * gRawJSBundleFormatShortVersionMap = nil; // 格式化的前三位版本，x.x.x
static NSDictionary <NSNumber *,NSString *> * gRawJSGreyHashMap = nil; // greyHash静态值
@implementation BDPVersionManagerV2

// this method just implement BDPBasePluginDelegate, does noting.
+ (id<BDPBasePluginDelegate>)sharedPlugin {
    static BDPVersionManagerV2 *versionManagerV2Impl = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        versionManagerV2Impl = [[BDPVersionManagerV2 alloc] init];
    });
    return versionManagerV2Impl;
}

#define jssdkMapSemaphore [self JSSDKMapSemaphore]
+(dispatch_semaphore_t)JSSDKMapSemaphore {
    static dispatch_semaphore_t _JSSDKMapSemaphore;
    static dispatch_once_t onceTokenForUniqueIDMapLock;
    dispatch_once(&onceTokenForUniqueIDMapLock, ^{
        _JSSDKMapSemaphore = dispatch_semaphore_create(1);
    });
    return _JSSDKMapSemaphore;
}

+(void)gRawJSBundleVersionUpdateWith:(OPAppType)appType value:(NSString*)value
{
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        gRawJSBundleVersionMap = @{}.mutableCopy;
    });
    dispatch_semaphore_wait(jssdkMapSemaphore, DISPATCH_TIME_FOREVER);
    ((NSMutableDictionary *)gRawJSBundleVersionMap)[@(appType)] = value;
    dispatch_semaphore_signal(jssdkMapSemaphore);
}

+(void)gRawJSBundleFormatVersionUpdateWith:(OPAppType)appType value:(NSString*)value
{
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        gRawJSBundleFormatVersionMap = @{}.mutableCopy;
    });
    dispatch_semaphore_wait(jssdkMapSemaphore, DISPATCH_TIME_FOREVER);
    ((NSMutableDictionary *)gRawJSBundleFormatVersionMap)[@(appType)] = value;
    dispatch_semaphore_signal(jssdkMapSemaphore);
}

+(void)gRawJSBundleFormatShortVersionUpdateWith:(OPAppType)appType value:(NSString*)value
{
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        gRawJSBundleFormatShortVersionMap = @{}.mutableCopy;
    });
    dispatch_semaphore_wait(jssdkMapSemaphore, DISPATCH_TIME_FOREVER);
    ((NSMutableDictionary *)gRawJSBundleFormatShortVersionMap)[@(appType)] = value;
    dispatch_semaphore_signal(jssdkMapSemaphore);
}

+(void)gRawJSGreyHashUpdateWith:(OPAppType)appType value:(NSString*)value
{
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        gRawJSGreyHashMap = @{}.mutableCopy;
    });
    dispatch_semaphore_wait(jssdkMapSemaphore, DISPATCH_TIME_FOREVER);
    ((NSMutableDictionary *)gRawJSGreyHashMap)[@(appType)] = value;
    dispatch_semaphore_signal(jssdkMapSemaphore);
}
+ (BOOL)localTestEnable
{
    TMAKVStorage *storage = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].kvStorage;
    return [[storage objectForKey:kBDPLocalTestEnableKeyV2] boolValue];
}

+ (void)setLocalTestEnable:(BOOL)localTestEnable
{
    TMAKVStorage *storage = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].kvStorage;
    [storage setObject:@(localTestEnable) forKey:kBDPLocalTestEnableKeyV2];
}

+ (NSString *)packageName:(OPAppType)appType {
    if (appType == BDPTypeBlock) {
        return @"block_jssdk";
    }  else if (appType == BDPTypeSDKMsgCard) {
        return @"msg_card_template";
    }else if (appType == BDPTypeNativeApp) {
        BDPResolveModule(storageModule, BDPStorageModuleProtocol, appType);
        NSString * jsLibFolderName = [storageModule JSLibFolderName];
        return jsLibFolderName;
    }
    return nil;
}

#pragma mark - Update Base Lib
/*-----------------------------------------------*/
//          Update Base Lib - 基础库升级
/*-----------------------------------------------*/
+ (void)downloadLibWithURL:(NSString *)url
             updateVersion:(NSString *)updateVersion
               baseVersion:(NSString *)baseVersion
                  greyHash:(NSString *)greyHash
                   appType:(OPAppType)appType
                completion:(void (^)(BOOL, NSString *))completion
{
    //forbidden all download action with condition, just return
    if([OPSDKFeatureGating isBoxOff]) {
        BDPLogInfo(@"downloadLibWithURL forbidden right now");
        return;
    }
    // Get New SDK Version
    NSString *latestUpdateVersionString = updateVersion;
    NSString *latestBaseVersionString = baseVersion;

    BDPLogInfo(@"download start %@", BDPParamStr(appType, url, updateVersion, baseVersion));

    // Start Download New SDK
    NSTimeInterval downloadStartTime = [[NSDate date] timeIntervalSince1970];

    OPMonitorEvent *downloadEvent = BDPMonitorWithName(kEventName_mp_lib_download, nil).timing().kv(@"base_version", baseVersion).kv(@"update_version", updateVersion);
    [BDPHTTPRequestSerializer setTimeoutInterval:15];
    BDPNetworkRequestExtraConfiguration* config = [BDPNetworkRequestExtraConfiguration defaultBDPSerializerConfig];
    config.flags = BDPRequestAutoResume;
    config.type = BDPRequestTypeRequestForBinary;
    [BDPNetworking taskWithRequestUrl:url parameters:nil extraConfig:config completion:^(NSError *error, id obj , id<BDPNetworkResponseProtocol> response) {
        
        NSUInteger downloadDuration = (NSUInteger)([[NSDate date] timeIntervalSince1970] - downloadStartTime) * 1000;
        
        // Download Error
        if (error || !obj) {
            BDPLogError(@"download error %@", BDPParamStr(appType, url, error));
            // Event - Download Failure
            [self eventV3WithLibEvent:@"mp_lib_download_result"
                                 from:nil
                        latestVersion:latestUpdateVersionString
                       latestGreyHash:greyHash
                           resultType:BDPTrackerResultFail
                               errMsg:error.localizedDescription
                             duration:0
                              appType:appType];
            downloadEvent.kv(kEventKey_result_type, kEventValue_fail).setError(error).flush();
            
            if (completion) {
                completion(NO, error.localizedDescription);
            }
            return;
        }
        
        // Event - Download Success
        [self eventV3WithLibEvent:@"mp_lib_download_result"
                             from:nil
                    latestVersion:latestUpdateVersionString
                   latestGreyHash:greyHash
                       resultType:BDPTrackerResultSucc
                           errMsg:nil
                         duration:downloadDuration
                          appType:appType];
        downloadEvent.kv(kEventKey_result_type, kEventValue_success).timing().flush();
        
        // Start Install
        NSTimeInterval installStartTime = [[NSDate date] timeIntervalSince1970];
        NSURL *location = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[response URL].absoluteString lastPathComponent]] isDirectory:NO];
        BOOL result = [obj writeToURL:location atomically:YES];
        
        if (!result) {
            BDPLogError(@"failed to write the file %@", BDPParamStr(appType, url));
            if (completion) {
                completion(NO, error.localizedDescription);
            }
            return;
        }
        NSString *locationPath = [location.absoluteString componentsSeparatedByString:@"file://"][1];
        BDPResolveModule(storageModule, BDPStorageModuleProtocol, appType);
        NSString *destinationPath;
        if (appType == BDPTypeNativeApp) {
            destinationPath = [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib];
        } else {
            destinationPath = [OPVersionDirHandler versionDir:appType version:latestUpdateVersionString greyHash:greyHash];
        }
        NSString *tmpPath = [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeTemp];
        
        // Unzip
        OPMonitorEvent *unzipEvent = BDPMonitorWithName(kEventName_mp_lib_download, nil).timing();
        NSError *unzipError;
        BOOL zipSuccess = [SSZipArchive unzipFileAtPath:locationPath toDestination:tmpPath overwrite:YES password:nil error:&unzipError];

        NSString * libPackageName = [self packageName:appType];

        BOOL exist = [LSFileSystem fileExistsWithFilePath:[tmpPath stringByAppendingPathComponent:libPackageName] isDirectory:nil];
        if (!zipSuccess || !exist) {
            BDPLogError(@"unzipError %@", BDPParamStr(appType, @(zipSuccess), @(exist)));
            // Event - Install Failure
            NSString *errMsg = [NSString stringWithFormat:@"Unzip Error or File Not Exist: %@", unzipError.localizedDescription];
            [self eventV3WithLibEvent:@"mp_lib_install_result"
                                 from:nil
                        latestVersion:latestUpdateVersionString
                       latestGreyHash:greyHash
                           resultType:BDPTrackerResultFail
                               errMsg:errMsg
                             duration:downloadDuration
                              appType:appType];
            unzipEvent.kv(@"result", @"unzip_error").setError(unzipError).flush();
            
            if (completion) {
                completion(NO, unzipError.localizedDescription);
            }
            return;
        }
        
        //
        NSString *bundleCheckPath = [[tmpPath stringByAppendingPathComponent:libPackageName] stringByAppendingPathComponent:@"basebundlecheck"];
        NSString *versionContent = [NSString lss_stringWithContentsOfFile:bundleCheckPath encoding:NSUTF8StringEncoding error:nil];
        if ([[self versionStringWithContent:versionContent] isEqualToString:kBDPErrorVersion]) {
            
            BDPLogError(@"bundleCheckError %@", BDPParamStr(appType, versionContent));
            // Event - Install Failure
            NSString *errMsg = @"basebundlecheck file is't contain a valid version";
            [self eventV3WithLibEvent:@"mp_lib_install_result"
                                 from:nil
                        latestVersion:latestUpdateVersionString
                       latestGreyHash:greyHash
                           resultType:BDPTrackerResultFail
                               errMsg:errMsg
                             duration:downloadDuration
                              appType:appType];
            
            if (completion) {
                completion(NO, unzipError.localizedDescription);
            }
            return;
        }
        
        BDPLogInfo(@"Remote SDK Zip File Updated from %@", BDPParamStr(appType, url));
        dispatch_semaphore_t copyActionSemaphore = [self gRawJSBundleCopyActionSemaphoreWith:appType];
        dispatch_semaphore_wait(copyActionSemaphore, DISPATCH_TIME_FOREVER); // 防止安装内置包过程中与网络更新冲突，使用内置包安装锁保护
        [[LSFileSystem main] createFolderIfNeedWithFolderPath:[[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeApp]];
        [OPVersionDirHandler clearCacheSDK:appType];
        [BDPVersionManager resetLocalLibVersionCache:appType];  // 改了JSLibPath目录，清一下jssdk版本号内存缓存

        // Move to DestPath
        NSError *moveError;
        BOOL moveSuccess = [[LSFileSystem main] moveItemAtPath:[tmpPath stringByAppendingPathComponent:libPackageName] toPath:destinationPath error:&moveError];
        BOOL destinationFolderExist = NO;
        if (appType != BDPTypeNativeApp) {
            if (!moveSuccess && moveError.code == NSFileWriteFileExistsError) {
                // block 多版本缓存
                [OPVersionDirHandler updateLatestSDKVersionFile:versionContent appType:appType];
                [OPVersionDirHandler updateLatestSDKGreyHashFile:greyHash appType:appType];
                [[LSFileSystem main] removeFolderIfNeedWithFolderPath:[tmpPath stringByAppendingPathComponent:libPackageName]];
                destinationFolderExist = YES;
            } else {
                [OPVersionDirHandler updateLatestSDKVersionFile:versionContent appType:appType];
                [OPVersionDirHandler updateLatestSDKGreyHashFile:greyHash appType:appType];
            }
        }

        dispatch_semaphore_signal(copyActionSemaphore);

        if (!moveSuccess && !destinationFolderExist) {
            // Move Failure
            BDPLogError(@"moveError %@", BDPParamStr(moveError));
            [self eventV3WithLibEvent:@"mp_lib_install_result"
                                 from:nil
                        latestVersion:latestUpdateVersionString
                       latestGreyHash:greyHash
                           resultType:BDPTrackerResultFail
                               errMsg:moveError.localizedDescription
                             duration:0
                              appType:appType];
            unzipEvent.kv(@"result", @"move_error").setError(moveError).flush();
            
            if (completion) {
                completion(NO, moveError.localizedDescription);
            }
            return;
        }
        NSUInteger installDuration = (NSUInteger)([[NSDate date] timeIntervalSince1970] - installStartTime) * 1000;
        [self eventV3WithLibEvent:@"mp_lib_install_result"
                             from:nil
                    latestVersion:latestUpdateVersionString
                   latestGreyHash:greyHash
                       resultType:BDPTrackerResultSucc
                           errMsg:nil
                         duration:installDuration
                          appType:appType];
        unzipEvent.kv(@"result", kEventValue_success).timing().flush();
        BDPLogInfo(@"moveSuccess %@", BDPParamStr(appType, latestUpdateVersionString, latestBaseVersionString));
        if (completion) {
            completion(YES, nil);
        }
    }];
}

/// 判断是否应该更新头条js sdk。兼容宿主Lark不需要更新js sdk的情况
+ (BOOL)shouldNotUpdateJSSDK {
    if ([BDPTimorClient sharedClient].currentNativeGlobalConfiguration.shouldNotUpdateJSSDK) {
        return YES;
    }
    return NO;
}

+ (void)updateLibComplete:(BOOL)isSuccess
{
//    if (isSuccess) {
    // 释放并预加载JSCore & WebView
//    [[BDPTimorClient sharedClient] prepareTimor]; // 预加载逻辑调整，不在此处做预加载
//    }
    [self eventSdkValidation];
}

/// 判断逻辑https://bytedance.feishu.cn/docs/doccnrGC5opPGAzP5H5YYtmv9ye
/// 1. 优先判断远端版本号与bundle版本号是否一致，如果不一致，不更新
/// 2. 判断出现greyHash从无到有或从有到无的逻辑, 更新
/// 3. 判断greyHash远端本地都存在的逻辑，如果不一致升级，一致不升级
/// 4. 如果都没有greyHash的情况，按照4位版本号对比

+ (BOOL)isNeedUpdateLib:(NSString *)version greyHash:(NSString *)greyHash appType:(OPAppType)appType
{
    NSString *bundleBaseVersion = [self shortVersionStringWithContent:[self innerBundleVersionWith:appType]];
    NSString *baseVersion = [self shortVersionStringWithVersion:version];
    if (bundleBaseVersion && ![bundleBaseVersion isEqualToString:baseVersion]) {
        return NO;
    }
    NSString *localGreyHash = [self localLibGreyHash:appType] ?: @"";
    greyHash = greyHash ?: @"";
    if (BDPIsEmptyString(localGreyHash) && !BDPIsEmptyString(greyHash)) {
        return YES;
    }
    if (!BDPIsEmptyString(localGreyHash) && BDPIsEmptyString(greyHash)) {
        return YES;
    }
    if (!BDPIsEmptyString(localGreyHash) && !BDPIsEmptyString(greyHash)) {
        if (![localGreyHash isEqualToString:greyHash]) {
            return YES;
        }
        return NO;
    }
    if ([self isLocalSdkLowerThanVersion:version appType:appType]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isLocalSdkLowerThanVersion:(NSString *)version
{
    return [self isLocalSdkLowerThanVersion:version appType:BDPTypeNativeApp];
}

+ (BOOL)isLocalSdkLowerThanVersion:(NSString *)version appType:(OPAppType)appType
{
    if (version.length > 0 && [[self class] localLibVersion:appType] < [[self class] iosVersion2Int:version]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isLocalLarkVersionLowerThanVersion:(nullable NSString *)minLarkVersion {
    // 读取info.plist中的lark版本
    NSString *localLarkVersion = [self localLarkVersion];

    BDPLogInfo(@"[MinLarkVersion] larkVersion: %@ minLarkVersion: %@", localLarkVersion, minLarkVersion);

    // lark版本去除如-alpha/-beta后缀
    NSString *minLarkVersionCorrected = [self larkVersionCorrect:minLarkVersion];
    NSString *localLarkVersionCorrected = [self larkVersionCorrect:localLarkVersion];

    // 如果本地版本经过校验后是空字符串,则先认为符合要求(前置已检查,这边只是为了兜底)
    if (BDPIsEmptyString(localLarkVersionCorrected)) {
        BDPLogWarn(@"[MinLarkVersion] larkVersion from local is invalid %@", localLarkVersionCorrected);
        return NO;
    }

    BOOL result = [self compareVersion:localLarkVersionCorrected with:minLarkVersionCorrected] < 0;

    BDPLogInfo(@"[MinLarkVersion] larkVersionCorrected: %@ minLarkVersionCorrected: %@ result: %d", localLarkVersionCorrected, minLarkVersionCorrected, result);

    return result;
}

+ (NSString *)latestVersionMsgCardSDKPath
{
    return [self latestVersionkPathWith:OPAppTypeSDKMsgCard fileName:@"template.js"];
}

+ (NSString *)latestVersionCardWithPath:(NSString *)path
{
    return [self latestVersionkPathWith:OPAppTypeSDKMsgCard fileName:path];
}

+ (NSString *)latestVersionBlockPath {
    return [self latestVersionkPathWith:OPAppTypeBlock fileName:@"blockit_core.js"];
}
+ (NSString *)latestVersionkPathWith:(OPAppType)appType fileName:(NSString*)fileName {
    NSString *dir = [OPVersionDirHandler latestVersionDir:appType];
    NSString *path = [dir stringByAppendingPathComponent:fileName];
    if ([LSFileSystem fileExistsWithFilePath:path isDirectory:nil] == NO) {
        BDPLogError(@"get latestVersionBlockPath fail, path not exist");
        // 文件不存在，重新解压一次
        dispatch_semaphore_t copyActionSemaphore = [self gRawJSBundleCopyActionSemaphoreWith:appType];
        dispatch_semaphore_wait(copyActionSemaphore, DISPATCH_TIME_FOREVER);
        [[LSFileSystem main] removeFolderIfNeedWithFolderPath:dir]; // 应对单个文件被删除的情况，flex测试
        dispatch_semaphore_signal(copyActionSemaphore);
        [BDPVersionManager setupBundleVersionIfNeed:appType];
    }
    dir = [OPVersionDirHandler latestVersionDir:appType];
    return [dir stringByAppendingPathComponent:fileName];
}

#pragma mark - Setup Bundle Version

+ (NSString *)innerBundleVersionWith:(OPAppType)appType {
    return [OPVersionDirHandler innerBundleVersionWith:appType];
}

+ (void)setupBundleVersionIfNeed:(OPAppType)appType
{
    // 本地没有正在使用的版本， 使用内置
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, appType);
    NSString *libPath;
    switch(appType){
        case BDPTypeNativeApp:
            libPath = [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib];
            break;
        case BDPTypeBlock:
        case BDPTypeSDKMsgCard:
            libPath = [OPVersionDirHandler latestVersionDir:appType];
            break;
        default:
            NSAssert(NO, @"setupBundleVersionIfNeed error: AppType:%@check logic is ready or not", @(appType));
            break;
    }
    if ([LSFileSystem fileExistsWithFilePath:libPath isDirectory:nil] == NO) {
        [self copyBundleVersionToDestination:appType];
        return;
    }

    NSString *version = [self innerBundleVersionWith:appType];
    if (!version) {
        BDPLogError(@"inner bundle version is nil! appType: %@", @(appType))
        return;
    }
    NSString *bundleBaseVersion = [self shortVersionStringWithContent:version];
    if ([bundleBaseVersion isEqualToString:kBDPErrorVersion]) {
        OPErrorWithMsg(GDMonitorCode.lib_version_decode_failed, @"bundle base version is -1 error version");
        return;
    }
    NSString *localBaseVersion = [self localLibBaseVersionString:appType];
    // 本地使用的base版本与内置的base版本不一致，则替换，兼容升降机的逻辑
    if (!localBaseVersion || ![localBaseVersion isEqualToString:bundleBaseVersion]) {
        [self copyBundleVersionToDestination:appType];
    }
}

+ (void)setupDefaultVersionIfNeed
{
    NSString *libPath = [[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib];
    //本地没有正在使用的版本
    dispatch_semaphore_t gRawJSBundleCopyActionSemaphore = [self gRawJSBundleCopyActionSemaphoreWith:OPAppTypeGadget];
    dispatch_semaphore_wait(gRawJSBundleCopyActionSemaphore, DISPATCH_TIME_FOREVER);
    // 为防止 JSSDK 安装过程中打开小程序，触多次内置包安装动作，此处判断文件是否存在时使用安装锁保护
    BOOL jssdkExist = [LSFileSystem fileExistsWithFilePath:libPath isDirectory:nil];
    dispatch_semaphore_signal(gRawJSBundleCopyActionSemaphore);
    if (jssdkExist == NO) {
        [[self class] copyBundleVersionToDestination:BDPTypeNativeApp];

        // 释放并预加载JSCore & WebView
        // prepareTimor 中有setting 开关，判断是否要更新预加载来源
        [BDPTimorClient updatePreloadFromForPrepareTimor:@"default_jssdk_setup_v2"];
        [[BDPTimorClient sharedClient] prepareTimor];
    }
}

/// JSSDK 预置包安装锁，保证JSSDK预置包安装过程中多线程时，JSSDK文件不会被意外删除
///
/// 为防止拷贝过程中外部读取到错误的文件，外部在做 jssdk 内置包安装动作的判定时可使用此锁做保护
+(dispatch_semaphore_t)gRawJSBundleCopyActionSemaphoreWith:(OPAppType)appType
{
    static NSDictionary * _gRawJSBundleCopyActionSemaphoreMap;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        _gRawJSBundleCopyActionSemaphoreMap = @{}.mutableCopy;
    });
    dispatch_semaphore_t _gRawJSBundleCopyActionSemaphore = nil;
    @synchronized (self) {
        _gRawJSBundleCopyActionSemaphore = _gRawJSBundleCopyActionSemaphoreMap[@(appType)];
        if(_gRawJSBundleCopyActionSemaphore == nil) {
            _gRawJSBundleCopyActionSemaphore = dispatch_semaphore_create(1);
            ((NSMutableDictionary *)_gRawJSBundleCopyActionSemaphoreMap)[@(appType)] = _gRawJSBundleCopyActionSemaphore;
        }
    }
    return _gRawJSBundleCopyActionSemaphore;
}

// 内部私有方法，获取jssdk版本号缓存的锁
+(dispatch_semaphore_t)gRawJSBundleVersionSemaphoreWith:(OPAppType)appType
{
    static NSDictionary * gRawJSBundleVersionSemaphoreMap;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        gRawJSBundleVersionSemaphoreMap = @{}.mutableCopy;
    });
    dispatch_semaphore_t _gRawJSBundleVersionSemaphore = nil;
    @synchronized (self) {
        _gRawJSBundleVersionSemaphore = gRawJSBundleVersionSemaphoreMap[@(appType)];
        if(_gRawJSBundleVersionSemaphore == nil) {
            _gRawJSBundleVersionSemaphore = dispatch_semaphore_create(1);
            ((NSMutableDictionary *)gRawJSBundleVersionSemaphoreMap)[@(appType)] = _gRawJSBundleVersionSemaphore;
        }
    }
    return _gRawJSBundleVersionSemaphore;
}
/// 内置包安装：解压、复制内置 JSSDK 文件到 Library 相应目录内
///
/// 为防止安装被触发多次，在读取内置包目录判定是否需要安装时，需要获取 gRawJSBundleCopyActionSemaphore 锁，防止安装过程中读取文件夹内容
+ (void)copyBundleVersionToDestination:(OPAppType)appType {
    dispatch_semaphore_t copyActionSemaphore = [self gRawJSBundleCopyActionSemaphoreWith:appType];
    dispatch_semaphore_wait(copyActionSemaphore, DISPATCH_TIME_FOREVER);

    /// 时间

    uint64_t startTs = getTimeInNanoSec();
    uint64_t unzippedTs = startTs;
    uint64_t endTs = startTs;
    
    // 目录定义
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, appType);
    NSString *libPath = [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib];
    NSString *libTempPath = [libPath stringByAppendingString:@".temp"]; // xxx/Library/tma/app/__dev__.temp
    NSString * libPackageName = [self packageName:appType];

    NSString *libTempLibPath = [libTempPath stringByAppendingPathComponent:libPackageName]; // xxx/Library/tma/app/__dev__.temp/__dev__

    // 解压结果
    BOOL unzipResult = NO;

    // 埋点
    OPMonitorEvent *event = [[OPMonitorEvent alloc] initWithService:nil name:@"mp_lib_install" monitorCode:nil];

    NSString *fileName = @"dat.bundle/delta.txz.dat";
    NSString *zipPassword = ZIP_PASSWORD;
    BDPBundleResourceType fileType = BDPBundleResourceTypeTXZJSSDK;
    if (appType == BDPTypeBlock) {
        fileName = @"block_jssdk.txz";
        zipPassword = nil;
        fileType = BDPBundleResourceTypeTXZ;
    }else if (appType == BDPTypeSDKMsgCard) {
        fileName = @"msg_card_template.txz";
        zipPassword = nil;
        fileType = BDPBundleResourceTypeTXZ;
    }
    unzipResult = [self unzipBundleFile:fileName
                               fileType:fileType
                         targetTempPath:libTempPath
                        checkResultPath:libTempLibPath
                            zipPassword:zipPassword
                       withMonitorEvent:event];

    unzippedTs = getTimeInNanoSec(); // 解压结束打点
    if(!unzipResult) {
        // 解压失败,上报埋点、解锁退出流程
        event.flush();
        dispatch_semaphore_signal(copyActionSemaphore);
        return;
    }

    NSString *bundleVersion;
    //非小程序（Block、消息卡片统一判断）
    if (appType != BDPTypeNativeApp) {
        bundleVersion = [self innerBundleVersionWith:appType];
        [[LSFileSystem main] createFolderIfNeedWithFolderPath:libPath]; // 创建上级目录，否则move会失败

        libPath = [OPVersionDirHandler versionDir:appType version:[BDPVersionManager versionStringWithContent:bundleVersion] greyHash:@""];
    }
    NSError *error = nil;
    [[LSFileSystem main] removeFolderIfNeedWithFolderPath:libPath];

    BOOL moveResult = [[LSFileSystem main] moveItemAtPath:libTempLibPath toPath:libPath error:&error];
    if (error != nil || !moveResult) {
        event.setResultTypeFail()
            .addCategoryValue(@"stage", @"move")
            .setError(error);
        BDPLogError(@"Copy Bundle Version Error:{%@}", error);
    } else {
        [OPVersionDirHandler updateLatestSDKVersionFile:bundleVersion appType:appType];
        [OPVersionDirHandler updateLatestSDKGreyHashFile:@"" appType:appType];
    }
    [[LSFileSystem main] removeFolderIfNeedWithFolderPath:libTempPath];
    dispatch_semaphore_signal(copyActionSemaphore);


    [self resetLocalLibVersionCache:appType];  // 清一下jssdk版本号内存缓存

    // 解压性能统计
    endTs = getTimeInNanoSec(); // 时间打点
    int64_t totalTimeMs = (endTs - startTs)/1000;
    int64_t unzipTimeMs = (unzippedTs - startTs) / 1000;
    event.addMetricValue(@"totalTime", totalTimeMs)
        .addMetricValue(@"unzipTime", unzipTimeMs)
        .flush();
    BDPLogInfo(@"BDP Time Static unzippedTs = %llu, totalTs = %llu", unzipTimeMs, totalTimeMs);
}

+(BOOL)unzipBundleFile: (NSString *)bundleFileName
              fileType: (BDPBundleResourceType) fileType
            targetTempPath: (NSString *)targetTempPath
       checkResultPath: (NSString *)checkResultPath
        zipPassword: (NSString *)zipPassword
      withMonitorEvent: (OPMonitorEvent *) event {

    // 先清空临时目录
    [[LSFileSystem main] removeFolderIfNeedWithFolderPath:targetTempPath];
    [[LSFileSystem main] createFolderIfNeedWithFolderPath:targetTempPath];

    // Decode Data File
    NSString *path = [[BDPBundle mainBundle] pathForResource:bundleFileName ofType:@""];

    event.addCategoryValue(@"resource", bundleFileName);

    // UnZip
    NSInteger retryCount = 3; // 解压重试3次
    BOOL unzipSucceed = NO;
    while (retryCount > 0) {
        retryCount--;
        @try {
            NSError *extractError;
            [BDPBundleResourceExtractor extractBundleResourceWithPath:path
                                                               type:fileType
                                                         targetPath:targetTempPath
                                                           password:zipPassword
                                                          overwrite:YES
                                                              error:&extractError];
            BOOL exist = [LSFileSystem fileExistsWithFilePath:checkResultPath isDirectory:nil];
            if(extractError == nil && exist) {
                unzipSucceed = YES;
                break;
            } else {
                NSArray<NSString *> *contents = [LSFileSystem contentsOfDirectoryWithDirPath:targetTempPath error:nil];
                event.setError(extractError)
                    .addCategoryValue(@"unzipExist", exist)
                    .addCategoryValue(@"unzipContent", contents);
            }
        } @catch (NSException *exception) {
            BDPLogError(@"copyBundleVersionToDestination throws exception! %@", exception);
            event.addCategoryValue(@"unzipException", exception.description);
            OPErrorWithMsg(GDMonitorCode.unzip_file_failed, @"Unzip Bundle Exception:{%@} path:%@ toPath:%@", exception, path, targetTempPath);
        }
    }

    if (!unzipSucceed) {
        // 解压失败
        event.addCategoryValue(@"stage", @"unzip")
            .setResultTypeFail();
        BDPLogError(@"copyBundleVersionToDestination failed multi times!");
        return false;
    } else {
        event.setResultTypeSuccess()
            .addMetricValue(@"remainUnzipTimes", retryCount);
        return true;
    }
}

#pragma mark - AppServiceControl - "tmaSwitch"
/*-----------------------------------------------*/
//          "tmaSwitch" - 小程序/小游戏开关
/*-----------------------------------------------*/
+ (BOOL)serviceEnabled
{
    TMAKVStorage *storage = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].kvStorage;
    return ![[storage objectForKey:kLocalTMASwitchKeyV2] boolValue];
}

#pragma mark - JSVersionControl - "version operation"
// 内部私有方法，直接获取basebundlecheck中的版本号（先检查内存缓存，如果没有读文件到缓存中）
+ (NSString *)_unformatedLocalLibVersionString:(OPAppType)appType
{
    dispatch_semaphore_wait(jssdkMapSemaphore, DISPATCH_TIME_FOREVER);
    NSString *retVersion = gRawJSBundleVersionMap[@(appType)]; // 记个中间变量内存副本来判断，防止多线程同时直接写原变量时，读操作出问题。
    dispatch_semaphore_signal(jssdkMapSemaphore);
    if (retVersion == nil) {
        // 2019.12.11 - BugFix: 本地无基础库时安装默认版本，避免返回 -1
        NSString *version;
        dispatch_semaphore_t copyActionSemaphore = [self gRawJSBundleCopyActionSemaphoreWith:appType];
        dispatch_semaphore_t versionSemaphore = [self gRawJSBundleVersionSemaphoreWith:appType];
        if (appType != BDPTypeNativeApp) {
            BOOL needCopy = NO;
            NSString *libPath = [OPVersionDirHandler versionDir:appType version:[BDPVersionManager versionStringWithContent:[OPVersionDirHandler latestSDKVersion:appType]] greyHash:[OPVersionDirHandler latestSDKGreyHash:appType]];
            dispatch_semaphore_wait(copyActionSemaphore, DISPATCH_TIME_FOREVER);
            // 检测有无内置包
            if (![LSFileSystem fileExistsWithFilePath:libPath isDirectory:nil]) {
                needCopy = YES;
            }
            dispatch_semaphore_signal(copyActionSemaphore);
            if (needCopy) {
                [[self class] copyBundleVersionToDestination:appType];
            }
            version = [OPVersionDirHandler latestSDKVersion:appType];

        } else {
            NSString *libPath = [[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib];
            dispatch_semaphore_wait(copyActionSemaphore, DISPATCH_TIME_FOREVER);
            // 为防止 JSSDK 安装过程中打开小程序，触多次内置包安装动作，此处判断文件是否存在时使用安装锁保护
            BOOL libPathFileExist = [LSFileSystem fileExistsWithFilePath:libPath isDirectory:nil];
            dispatch_semaphore_signal(copyActionSemaphore);
            if (!libPathFileExist) {
                [[self class] copyBundleVersionToDestination:appType];
            }
            NSString *bundleCheck = [libPath stringByAppendingPathComponent:@"basebundlecheck"];
            version = [NSString lss_stringWithContentsOfFile:bundleCheck encoding:NSUTF8StringEncoding error:nil];

        }
        // 加载文件并读取版本号
        dispatch_semaphore_wait(versionSemaphore, DISPATCH_TIME_FOREVER);
        [self gRawJSBundleVersionUpdateWith:appType value:version];
        retVersion = version;
        dispatch_semaphore_signal(versionSemaphore);
    }
    return retVersion;
}

// 内部私有化方法，直接获取basebundlecheck_greyhash的信息（先检查内存缓存，如果没有，读文件到缓存）
+ (NSString * _Nullable)_localLibGreyHash:(OPAppType)appType
{
    dispatch_semaphore_wait(jssdkMapSemaphore, DISPATCH_TIME_FOREVER);
    NSString *greyHash = gRawJSGreyHashMap[@(appType)];
    dispatch_semaphore_signal(jssdkMapSemaphore);
    if (greyHash) {
        return greyHash;
    }
    
    NSString *greHashInFile = @"";
    dispatch_semaphore_t versionSemaphore = [self gRawJSBundleVersionSemaphoreWith:appType];
    if (appType == BDPTypeNativeApp) {
        NSString *libPath = [[BDPGetResolvedModule(BDPStorageModuleProtocol, appType) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib];
        if (![LSFileSystem fileExistsWithFilePath:libPath isDirectory:nil]) {
            // 如果JSLib目录都没有，不处理，下次进入的时候再获取
            BDPLogWarn(@"get grey hash nil, jsLib path not exist")
            return nil;
        }
        NSString *greHashPath = [libPath stringByAppendingPathComponent:kBDPJSLibGreyHashFileNameV2];
        // 如果存储greyHash的文件不存，则为正常情况，认为是使用的非GreyHash版本，不读取文件
        if ([LSFileSystem fileExistsWithFilePath:greHashPath isDirectory:nil]) {
            NSError *error;
            greHashInFile = [NSString lss_stringWithContentsOfFile:greHashPath encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                BDPLogError(@"read hash from file fail, error=%@", error);
            }
        }
    } else {
        greHashInFile = [OPVersionDirHandler latestSDKGreyHash:appType];
    }
    dispatch_semaphore_wait (versionSemaphore, DISPATCH_TIME_FOREVER);
    [self gRawJSGreyHashUpdateWith:appType value:greHashInFile];
    greyHash = greHashInFile;
    dispatch_semaphore_signal(versionSemaphore);

    return greyHash;
}

+ (void)resetLocalLibVersionCache:(OPAppType)appType
{
    dispatch_semaphore_t versionSemaphore = [self gRawJSBundleVersionSemaphoreWith:appType];
    dispatch_semaphore_wait(versionSemaphore, DISPATCH_TIME_FOREVER);
    [self resetLocalLibVersionCacheWithoutLock:appType];
    dispatch_semaphore_signal(versionSemaphore);
}

+ (void)resetLocalLibCache {
    dispatch_semaphore_t versionSemaphore = [self gRawJSBundleVersionSemaphoreWith:OPAppTypeGadget];
    dispatch_semaphore_wait(versionSemaphore, DISPATCH_TIME_FOREVER);
    // 清理内存缓存
    [self resetLocalLibVersionCacheWithoutLock];
    
    // 清理本地文件
    [NSFileManager.defaultManager removeItemAtPath:[[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib] error:nil];
    
    dispatch_semaphore_signal(versionSemaphore);
    
    // 清理预加载逻辑，放到锁外执行，不需要保证一致性
    [BDPJSRuntimePreloadManager releaseAllPreloadRuntimeWithReason:@"reset_lib_cache_v2"];
    [BDPAppPageFactory releaseAllPreloadedAppPageWithReason:@"reset_lib_cache_v2"];
}

+ (void)resetLocalLibVersionCacheWithoutLock {
    [self resetLocalLibVersionCacheWithoutLock:BDPTypeNativeApp];
}
/// WARNING! 该方法为清理内存JSVersion无锁版本。如果使用，务必要保证添加versionCacheLock, 或直接使用 +resetLocalLibVersionCache
+ (void)resetLocalLibVersionCacheWithoutLock:(OPAppType)appType {
    [self gRawJSGreyHashUpdateWith:appType value:nil];
    [self gRawJSBundleVersionUpdateWith:appType value:nil];
    [self gRawJSBundleFormatVersionUpdateWith:appType value:nil];
    [self gRawJSBundleFormatShortVersionUpdateWith:appType value:nil];
}

#pragma mark - JSVersionControl - "sdkUpdateVersion"
/*-----------------------------------------------*/
//    "sdkUpdateVersion" - 基础库版本控制(4位版本)
//    "localLibGreyHash" - 本地版本的GreyHash，随机字符串，可能为 nil 或 empty。nil 等价 empty 的使用
/*-----------------------------------------------*/
+ (long long)localLibVersion
{
    return [self localLibVersion:BDPTypeNativeApp];
}

+ (long long)localLibVersion:(OPAppType)appType
{
    return [self iosVersion2Int:[self localLibVersionString:appType]];
}

+ (NSString *)localLibVersionString
{
    return [self localLibVersionString:BDPTypeNativeApp];
}

+ (NSString *)localLibVersionString:(OPAppType)appType
{
    dispatch_semaphore_wait(jssdkMapSemaphore, DISPATCH_TIME_FOREVER);
    NSString * gRawJSBundleFormatVersion = gRawJSBundleFormatVersionMap[@(appType)];
    dispatch_semaphore_signal(jssdkMapSemaphore);
    if (!gRawJSBundleFormatVersion) {
        NSString *version = [self _unformatedLocalLibVersionString:appType];
        gRawJSBundleFormatVersion = [self versionStringWithContent:version];
        [self gRawJSBundleFormatVersionUpdateWith:appType value:gRawJSBundleFormatVersion];
    }
    return gRawJSBundleFormatVersion;
}

+ (NSString * _Nullable)localLibGreyHash {
    return [self localLibGreyHash:BDPTypeNativeApp];
}

+ (NSString * _Nullable)localLibGreyHash:(OPAppType)appType {
    NSString *greyHash = [self _localLibGreyHash:appType];
    return greyHash;
}

#pragma mark - JSVersionControl - "sdkVersion"
/*-----------------------------------------------*/
//      "sdkVersion" - 基础库版本控制(3位版本)
/*-----------------------------------------------*/
+ (long long)localLibBaseVersion
{
    return [self iosVersion2Int:[self localLibBaseVersionString]];
}

+ (NSString *)localLibBaseVersionString
{
    return [self localLibBaseVersionString:BDPTypeNativeApp];
}

+ (NSString *)localLibBaseVersionString:(OPAppType)appType
{
    dispatch_semaphore_wait(jssdkMapSemaphore, DISPATCH_TIME_FOREVER);
    NSString * gRawBlockJSBundleFormatShortVersion = gRawJSBundleFormatShortVersionMap[@(appType)];
    dispatch_semaphore_signal(jssdkMapSemaphore);
    if (gRawBlockJSBundleFormatShortVersion) {
        return gRawBlockJSBundleFormatShortVersion;
    } else {
        NSString *version = [self _unformatedLocalLibVersionString:appType];
        gRawBlockJSBundleFormatShortVersion = [self shortVersionStringWithContent:version];
        [self gRawJSBundleFormatShortVersionUpdateWith:appType value:gRawBlockJSBundleFormatShortVersion];
        return gRawBlockJSBundleFormatShortVersion;
    }
}

#pragma mark - iOS SDK Version
/*-----------------------------------------------*/
//       "iOS SDK Version" - 客户端SDK版本
/*-----------------------------------------------*/
+ (long long)localSDKVersion
{
    return [self iosVersion2Int:kBundleSDKVersion];
}

+ (NSString *)localSDKVersionString
{
    return kBundleSDKVersion;
}

#pragma mark - Utils
/*-----------------------------------------------*/
//                  Utils - 工具
/*-----------------------------------------------*/
+ (NSInteger)iosVersion2Int:(NSString *)str
{
    NSMutableArray *parts = [[str componentsSeparatedByString:@"."] mutableCopy];
    if ([parts count] == 3) {
        [parts addObject:@"0"];
    }
    if ([parts count] != 4) {
        return [kBDPErrorVersion integerValue];
    }
    NSInteger iversion = 0;
    NSInteger ratio = 1;
    for (NSInteger i = [parts count] - 1; i >= 0; i--) {
        NSInteger partInt = ((NSString *)parts[i]).integerValue;
        iversion += ratio * partInt;
        ratio = ratio * 100;
    }
    return iversion;
}

+(NSInteger)compareVersion:(NSString * _Nullable)unsafeV1 with:(NSString * _Nullable)unsafeV2
{
    //检查类型，确保NSString合法
    NSString * v1 = BDPSafeString(unsafeV1);
    NSString * v2 = BDPSafeString(unsafeV2);
    
    int i = 0, j = 0;
    while(i < v1.length || j < v2.length)
    {
        //long long 保险一点，如果版本位数很长也能支持（例如 1.202205181220, long会溢出）
        long long num1 = 0, num2 = 0;
        //从高往低逐位比较，
        //逐位*10，且将字符char的ASCII值转成可比较的数字
        while(i < v1.length && [v1 characterAtIndex:i] != '.') num1 = num1 * 10 + [v1 characterAtIndex:i++] - '0';
        while(j < v2.length && [v2 characterAtIndex:j] != '.') num2 = num2 * 10 + [v2 characterAtIndex:j++] - '0';
        //如果有结果了直接返回
        if(num1 > num2) return 1;
        else if( num1 < num2) return -1;
        i++;
        j++;
    }
    return 0;
}

+(NSString *)returnLargerVersion:(NSString * _Nullable)v1 with:(NSString * _Nullable)v2
{
    //如果v1 比 v2小，返回v2，不然返回v1
    return [self compareVersion:v1 with:v2] < 0 ? v2 : v1;
}

+ (NSString *)versionStringWithContent:(NSString *)content
{
    content = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([self isValidVersion:content]) {
        if ([content length] < 7) {
            content = [@"0000000" stringByReplacingCharactersInRange:NSMakeRange(7 - content.length, content.length) withString:content];
        }
        NSString *fourthStr = [content substringWithRange:NSMakeRange(content.length - 2, 2)];
        NSString *thirdStr = [content substringWithRange:NSMakeRange(content.length - 4, 2)];
        NSString *secondStr = [content substringWithRange:NSMakeRange(content.length - 6, 2)];
        NSString *firstStr = [content substringToIndex:content.length - 6];

        fourthStr = [@([fourthStr integerValue]) stringValue];
        thirdStr = [@([thirdStr integerValue]) stringValue];
        secondStr = [@([secondStr integerValue]) stringValue];
        firstStr = [@([firstStr integerValue]) stringValue];
        
        NSString *version = [NSString stringWithFormat:@"%@.%@.%@.%@",firstStr, secondStr, thirdStr, fourthStr];
        NSInteger versionCode = [self iosVersion2Int:version];
        return versionCode > 0 ? version : kBDPErrorVersion;
    }
    return kBDPErrorVersion;
}

+ (NSString *)shortVersionStringWithVersion:(NSString *)version {
    version = [version stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray<NSString *> *versionList =  [version componentsSeparatedByString:@"."];
    if (versionList.count < 3 || versionList.count > 4) {
        return kBDPErrorVersion;
    }
    NSArray<NSString *> *shortVersion = [versionList subarrayWithRange:NSMakeRange(0, 3)];
    return [shortVersion componentsJoinedByString:@"."];
}

+ (NSString *)shortVersionStringWithContent:(NSString *)content
{
    content = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([self isValidVersion:content]) {
        if ([content length] < 7) {
            content = [@"0000000" stringByReplacingCharactersInRange:NSMakeRange(7 - content.length, content.length) withString:content];
        }
        NSString *thirdStr = [content substringWithRange:NSMakeRange(content.length - 4, 2)];
        NSString *secondStr = [content substringWithRange:NSMakeRange(content.length - 6, 2)];
        NSString *firstStr = [content substringToIndex:content.length - 6];
        
        thirdStr = [@([thirdStr integerValue]) stringValue];
        secondStr = [@([secondStr integerValue]) stringValue];
        firstStr = [@([firstStr integerValue]) stringValue];
        
        NSString *version = [NSString stringWithFormat:@"%@.%@.%@",firstStr, secondStr, thirdStr];
        NSInteger versionCode = [self iosVersion2Int:version];
        return versionCode > 0 ? version : kBDPErrorVersion;
    }
    return kBDPErrorVersion;
}

+ (BOOL)isValidVersion:(NSString *)version
{
    if (BDPIsEmptyString(version)) {
        return NO;
    }
    
    NSCharacterSet *versionSet = [NSCharacterSet characterSetWithCharactersInString:version];
    return [[NSCharacterSet decimalDigitCharacterSet] isSupersetOfSet:versionSet];
}

+ (BOOL)isValidLocalLarkVersion {
    NSString *localLarkVersionCorrected = [self larkVersionCorrect:[self localLarkVersion]];
    return [self isValidLarkVersion:localLarkVersionCorrected];
}

+ (BOOL)isValidLarkVersion:(nullable NSString *)larkVersion {
    if (BDPIsEmptyString(larkVersion)) {
        return NO;
    }

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", kLarkVersionRegexV2];
    return [predicate evaluateWithObject:larkVersion];
}

+ (NSString *)versionCorrect:(nullable NSString *)version {
    return [self larkVersionCorrect:version];
}

/// 去除lark版本中的-beta或-alpha的后缀
/// @param larkVersion lark版本
+ (NSString *)larkVersionCorrect:(NSString *)larkVersion {
    if (BDPIsEmptyString(larkVersion)) {
        BDPLogWarn(@"[MinLarkVersion] lark version is empty");
        return @"";
    }

    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:kLarkVersionRegexV2 options: NSRegularExpressionCaseInsensitive error:&error];

    if (error) {
        BDPLogWarn(@"[MinLarkVersion] config regex failed: %@", error);
        return @"";
    }

    NSTextCheckingResult *result = [regex firstMatchInString:larkVersion options:NSMatchingReportProgress range:NSMakeRange(0, [larkVersion length])];

    if (!result) {
        BDPLogWarn(@"[MinLarkVersion] larkVersion: %@ not match", larkVersion);
        return @"";
    }

    return [larkVersion substringWithRange:result.range];
}

+ (NSString *)localLarkVersion {
    return [OPApplicationService current].envConfig.larkVersion;
}
#pragma mark - Event Track
/*-----------------------------------------------*/
//             Event Track - 埋点相关
/*-----------------------------------------------*/
+ (void)eventV3WithLibEvent:(NSString *)event
                       from:(NSString *)from
              latestVersion:(NSString *)latestVersion
             latestGreyHash:(NSString *)greyHash
                 resultType:(NSString *)resultTypes
                     errMsg:(NSString *)errMsg
                   duration:(NSUInteger)duration
                    appType:(OPAppType)appType
{
    if (!event || !event.length) {
        return;
    }
    
    BDPExecuteOnMainQueue(^{
        // Base Params
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params setValue:[self localLibVersionString:appType] forKey:BDPTrackerLibVersionKey];
        [params setValue:latestVersion forKey:@"latest_version"];
        [params setValue:greyHash forKey:BDPTrackerLibGreyHashKey];
        [params setValue:BDPTrackerApp forKey:BDPTrackerParamSpecialKey];
        [params setValue:resultTypes forKey:BDPTrackerResultTypeKey];
        [params setValue:from forKey:@"from"];
        if (![event isEqualToString:@"mp_lib_validation_result"]) {
            // Extra Params
            [params setValue:errMsg forKey:BDPTrackerErrorMsgKey];
            [params setValue:@(duration) forKey:BDPTrackerDurationKey];
        }
        [params setValue:OPAppTypeToString(appType) forKey:@"app_type"];
        [BDPTracker event:event attributes:params uniqueID:nil];
    });
}

+ (void)eventSdkValidation
{
    // mp_sdk_validation 用于统计SDK版本分布情况，上报时机为基础库更新ready后
    [BDPTracker event:@"mp_sdk_validation" attributes:nil uniqueID:nil];
}


@end
