//
//  BDPOfflineZipManager.m
//  Timor
//
//  Created by laichengfeng on 2019/8/1.
//

#import <Foundation/Foundation.h>
#import "BDPOfflineZipManager.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPModuleManager.h>
#include <sys/time.h>
#import <OPFoundation/BDPNetworking.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPSettingsManager.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import <OPFoundation/BDPBundle.h>
#import <SSZipArchive/SSZipArchive.h>
#import "coder.h"
#import <OPFoundation/BDPVersionManager.h>
#import <OPFoundation/TMAMD5.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <ECOInfra/OPError.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <LarkStorage/LarkStorage-Swift.h>

NSString * const kOfflineLastestUpdateKey = @"kOfflineLastestUpdateKey";

static size_t fsize(FILE* f)
{
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

@implementation BDPOfflineZipManager

static NSLock* localConfigLock = nil;


+ (void)updateOfflineZipIfNeed
{
    BDPLogInfo(@"updateOfflineZipIfNeed");
    localConfigLock = [[NSLock alloc] init];
    [self setupDefaultOfflineZipIfNeed];
    
    // 2019-8-30 by dingruoshan 增加检查update_config逻辑，用于屏蔽升级测试本地包，打包的时候注意这里要打开升级
    BOOL needCheckUpdateFromSettings = YES;
    NSDictionary* updateCfgDict = [self getUpdateConfigInOffline];
    if (updateCfgDict && [updateCfgDict objectForKey:@"enable_update"]) {
        needCheckUpdateFromSettings = ([updateCfgDict[@"enable_update"] integerValue] == 0?NO:YES);
    }
    if (!needCheckUpdateFromSettings) {
        return;
    }
    
    // 检查settings做离线包更新
    [BDPSettingsManager.sharedManager updateSettingsIfNeed:^(NSError *error) {
        // Invalid Settings
        if (error) {
            return;
        }
        BOOL needUpdate = NO;
        // lark的offlineZipConfig 始终为空，这里不做任何操作，移除后续的更新逻辑
        OPMonitorEvent *event = BDPMonitorWithName(kEventName_mp_offline_zip_update, nil).timing();
        event.kv(@"result", @"No need to update offline").flush();
    }];
}

+ (void)setupDefaultOfflineZipIfNeed
{
    BDPLogInfo(@"setupDefaultOfflineZipIfNeed");
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, BDPTypeNativeApp);
    NSString *offlineFolderPath = [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeOffline];
    // 离线包不存在
    if ([LSFileSystem fileExistsWithFilePath:offlineFolderPath isDirectory:nil] == NO) {
        [[self class] copyBundleOfflineZipToDestination];
        return;
    }
    // 本地配置文件不存在
    NSString *path = [[[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeOffline] stringByAppendingPathComponent:@"config.json"]; // xxx/Library/tma/app/offline/config.json
    if (![LSFileSystem fileExistsWithFilePath:path isDirectory:nil]) {
        [[self class] copyBundleOfflineZipToDestination];
        return;
    }
    // 低版本
    NSString *offlineUpdateVersion = [[NSUserDefaults standardUserDefaults] valueForKey:kOfflineLastestUpdateKey];
    if (![[BDPVersionManager localSDKVersionString] isEqualToString:offlineUpdateVersion]) {
        [[self class] copyBundleOfflineZipToDestination];
        return;
    }
}

+ (void)copyBundleOfflineZipToDestination
{
    BDPLogInfo(@"copyBundleOfflineZipToDestination");
    uint64_t startTs = getTimeInNanoSec();
    uint64_t unzippedTs = startTs;
    uint64_t endTs = startTs;
    
    // 目录定义
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, BDPTypeNativeApp);
    NSString *offlineFolderPath = [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeOffline]; // xxx/Library/tma/app/offline
    NSString *offlineFolderUnzipPath = [offlineFolderPath stringByAppendingString:@".temp"]; // xxx/Library/tma/app/offline.temp
    NSString *offlineFolderTempPath = [offlineFolderUnzipPath stringByAppendingPathComponent:[storageModule offlineFolderName]]; // xxx/Library/tma/app/offline.temp/offline
    
    [[LSFileSystem main] removeFolderIfNeedWithFolderPath:offlineFolderUnzipPath];
    [[LSFileSystem main] createFolderIfNeedWithFolderPath:offlineFolderUnzipPath];
    
    // 先解码并解压到临时目录
    OPMonitorEvent *event = BDPMonitorWithName(kEventName_mp_offline_zip_update, nil).timing();
    NSString const *sourcePath = @"zio.dat"; // offline.zip
    {
        // Decode Data File
        NSString *resource = [NSString stringWithFormat:@"dat.bundle/%@",sourcePath];
        NSString *path = [[BDPBundle mainBundle] pathForResource:resource ofType:@""];
        
        // UnZip
        NSInteger retryCount = 3; // 解压重试3次
        BOOL unzipSucceed = NO;
        while (retryCount > 0) {
            retryCount--;
            @try {
                NSError *unzipError;
                BOOL unzipResult = [SSZipArchive unzipFileAtPath:path toDestination:offlineFolderUnzipPath overwrite:YES password:ZIP_PASSWORD error:&unzipError];
                BOOL exist = [LSFileSystem fileExistsWithFilePath:offlineFolderTempPath isDirectory:nil];
                if (unzipResult && exist) {
                    // 解压成功
                    unzipSucceed = YES;
                    break;
                } else {
                    event.setError(OPErrorWithErrorAndMsg(GDMonitorCode.unzip_file_failed, unzipError, @"Unzip Bundle Error path:%@ toPath:%@", path, offlineFolderUnzipPath));
                }
            } @catch (NSException *exception) {
                event.setError(OPErrorWithMsg(GDMonitorCode.unzip_file_failed, @"Unzip Bundle Exception:{%@} path:%@ toPath:%@", exception, path, offlineFolderUnzipPath));
            }
        }
        if (!unzipSucceed) {
            // 这里失败了，就啥都别干了
            event.kv(@"result", @"Fail to unzip bundle offline zip").flush();
            return;
        }
    }
    unzippedTs = getTimeInNanoSec(); // 时间打点
    NSError *error = nil;
    [[LSFileSystem main] removeFolderIfNeedWithFolderPath:offlineFolderPath];
    BOOL moveResult = [[LSFileSystem main] moveItemAtPath:offlineFolderTempPath toPath:offlineFolderPath error:&error];
    
    if (error != nil || !moveResult) {
        BDPLogError(@"Copy Bundle Version Error:{%@}", error);
    }
    [[LSFileSystem main] removeFolderIfNeedWithFolderPath:offlineFolderUnzipPath];
    event.kv(@"result", @"Succeed to unzip bundle offline zip").flush();
    
    // 记录解压时的客户端SDK版本号
    NSString *localSDKVersionString = [BDPVersionManager localSDKVersionString];
    [NSUserDefaults.standardUserDefaults setValue:localSDKVersionString forKey:kOfflineLastestUpdateKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    // 解压性能统计
    endTs = getTimeInNanoSec(); // 时间打点
    BDPLogInfo(@"BDP Time Static unzippedTs = %llu, totalTs = %llu", unzippedTs - startTs, endTs - startTs);
}

+ (NSDictionary *)getLocalOfflineConfig
{
    NSString *path = [[[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeOffline] stringByAppendingPathComponent:@"config.json"]; // xxx/Library/tma/app/offline/config.json
    NSInputStream *inStream = [[NSInputStream alloc] initWithFileAtPath:path];
    [inStream open];
    NSDictionary *localConfig = nil;
    NSError *error;
    id data = [NSJSONSerialization JSONObjectWithStream:inStream options:NSJSONReadingAllowFragments error:&error];
    if ([data isKindOfClass:[NSDictionary class]]) {
        localConfig = (NSDictionary *)data;
    }
    [inStream close];
    return [localConfig copy];
}

+ (void)writeLocalOfflineConfig:(NSDictionary *)config
{
    NSString *path = [[[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeOffline] stringByAppendingPathComponent:@"config.json"]; // xxx/Library/tma/app/offline/config.json
    NSOutputStream *outStream = [[NSOutputStream alloc] initToFileAtPath:path append:NO];
    [outStream open];
    NSError *error;
    [NSJSONSerialization writeJSONObject:config toStream:outStream options:NSJSONWritingPrettyPrinted error:&error];
    [outStream close];
}

// 从加压后的离线包目录里面读取升级配置，如果用于测试需要屏蔽升级，需要这里配置成不升级
+ (NSDictionary*)getUpdateConfigInOffline {
    NSString* updateConfigPath = [[[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeOffline] stringByAppendingPathComponent:@"update_config.json"];
    if ([LSFileSystem fileExistsWithFilePath:updateConfigPath isDirectory:nil]) {
        NSData* data = [NSData lss_dataWithContentsOfFile:updateConfigPath error:nil];
        if ([data length] > 0) {
            NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([dict isKindOfClass:[NSDictionary class]]) {
                return dict;
            }
        }
    }
    return nil;
}

@end
