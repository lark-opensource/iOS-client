//
//  OPVersionDirHandler.m
//  TTMicroApp
//
//  Created by yi on 2022/5/31.
//

#import "OPVersionDirHandler.h"
#import "BDPStorageManager.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPBundle.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import <OPFoundation/EEFeatureGating.h>
#import <ECOInfra/BDPUtils.h>
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/OPError.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPVersionManagerV2.h"
#import <LarkStorage/LarkStorage-swift.h>

static dispatch_semaphore_t gUpdatedVersionSemaphore = nil;

@interface OPVersionDirHandler ()
@property (nonatomic, strong) NSMutableArray *updatedVersions;
@end
@implementation OPVersionDirHandler

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        gUpdatedVersionSemaphore = dispatch_semaphore_create(1);
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _enableFixBlockCopyBundleIssue = [EMAFeatureGating boolValueForKey:EEFeatureGatingKeyBlockJSSDKFixCopyBundleIssue];
    }
    return self;
}

- (NSArray *)updatedSDKVersions {
    return _updatedVersions;
}

- (void)appendUpdateVersion:(NSString *)version {
    dispatch_semaphore_wait(gUpdatedVersionSemaphore, DISPATCH_TIME_FOREVER);

    if (!_updatedVersions) {
        _updatedVersions = [NSMutableArray array];
    }
    if (![_updatedVersions containsObject:version]) {
        [_updatedVersions addObject:version];
    }
    dispatch_semaphore_signal(gUpdatedVersionSemaphore);

}

+ (NSString *)latestVersionBlockPath {
    return [BDPVersionManagerV2 latestVersionBlockPath];
}

// 获取最新的sdk路径
+ (NSString *)latestVersionDir:(OPAppType)appType {
    return [self versionDir:appType version:[BDPVersionManager localLibVersionString:appType] greyHash:[self latestSDKGreyHash:appType]];
}

// 根据version 和 greyHash 获得 sdk 路径
+ (NSString *)versionDir:(OPAppType)appType version:(NSString *)version greyHash:(NSString *)greyHash {
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, appType);
    NSString *destinationPath = [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib];
    NSString *folderName = version;
    if (greyHash.length > 0) {
        folderName = [NSString stringWithFormat:@"%@_%@", version, greyHash];
    }
    destinationPath = [destinationPath stringByAppendingPathComponent:folderName];
    return destinationPath;
}

// 更新保存最新版本号的文件
+ (void)updateLatestSDKVersionFile:(NSString *)version appType:(OPAppType)appType {
    if ([OPVersionDirHandler sharedInstance].updatedVersions.count < 1) {
        // 初始化状态，记录启动lark时sdk 版本，以防止误删文件
        [[OPVersionDirHandler sharedInstance] appendUpdateVersion:[BDPVersionManager versionStringWithContent:[OPVersionDirHandler latestSDKVersion:appType]]];
    }
    // lark 生命周期内更新的版本记录保存，防止误删
    [[OPVersionDirHandler sharedInstance] appendUpdateVersion:[BDPVersionManager versionStringWithContent:version]];
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, appType);
    NSString *libPath = [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib];
    NSString *path = [libPath stringByAppendingPathComponent:@"lastest_sdk_version"];
    [version writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// 获得最新的版本号，没有则获取bundle内版本号
+ (NSString *)latestSDKVersion:(OPAppType)appType {
    NSString *version = [NSString lss_stringWithContentsOfFile:[self latestSDKVersionFilePath:appType] encoding:NSUTF8StringEncoding error:nil];
    if (!version) {
        //没有则返回内置包的版本号
        version = [self innerBundleVersionWith:appType];
    }
    return version;
}

+ (NSString *)innerBundleVersionWith:(OPAppType)appType {
    NSDictionary * verisonFileMap = @{@(OPAppTypeBlock): @"block_jssdk_version",
                                      @(OPAppTypeGadget): @"dat.bundle/siren.dat",
                                      @(OPAppTypeSDKMsgCard): @"msg_card_template_version"};
    BOOL shouldBase64Decode = appType == OPAppTypeGadget;
    NSString * fileName = verisonFileMap[@(appType)];
    if (BDPIsEmptyString(fileName)) {
        OPErrorWithMsg(GDMonitorCode.lib_version_decode_failed, @"fileName is nil");
        return nil;
    }
    NSString *path = [[BDPBundle mainBundle] pathForResource:fileName ofType:@""];
    if (BDPIsEmptyString(path)) {
        OPErrorWithMsg(GDMonitorCode.lib_version_decode_failed, @"%@ not exist", fileName);
        return nil;
    }
    NSError *error = nil;
    NSString *content = [NSString lss_stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        OPErrorWithError(GDMonitorCode.lib_version_decode_failed, error);
        return nil;
    }
    return shouldBase64Decode? [NSString bdp_stringFromBase64String:content] : content;
}

// 获取最新版本号文件的路径
+ (NSString *)latestSDKVersionFilePath:(OPAppType)appType {
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, appType);
    NSString *libPath = [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib];
    NSString *path = [libPath stringByAppendingPathComponent:@"lastest_sdk_version"];
    return path;
}

+ (void)updateLatestSDKGreyHashFile:(NSString *)greyHash appType:(OPAppType)appType {
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, appType);
    NSString *libPath = [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib];
    NSString *path = [libPath stringByAppendingPathComponent:@"lastest_greyhash"];
    greyHash = greyHash ?: @""; // 正式版覆盖
    [greyHash writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (NSString *)latestSDKGreyHash:(OPAppType)appType {
    NSString *greyHash = [NSString lss_stringWithContentsOfFile:[self latestSDKGreyHashFilePath:appType] encoding:NSUTF8StringEncoding error:nil];
    return greyHash;
}

+ (NSString *)latestSDKGreyHashFilePath:(OPAppType)appType {
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, appType);
    NSString *libPath = [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib];
    NSString *path = [libPath stringByAppendingPathComponent:@"lastest_greyhash"];
    return path;
}


/*
 清理策略
 1. 判断是否是js sdk 文件夹，否则不删除
 2. 判断是否为lark生命周期中更新过的版本，是则不删除
 3. 文件为当前使用版本，则不删除
 4. 其他删除
 */
+ (void)clearCacheSDK:(OPAppType)appType {
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, appType);
    if (appType == OPAppTypeBlock) {
        NSString *latestGreyHash = [BDPVersionManager localLibGreyHash:appType];
        NSString *latestVersion = [BDPVersionManager versionStringWithContent:[self latestSDKVersion:appType]];
        NSString *greyHashVersion = latestVersion;
        if (latestGreyHash.length > 0) {
            greyHashVersion = [NSString stringWithFormat:@"%@_%@", latestVersion, latestGreyHash];
        }

        NSString *libPath = [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib];
        NSArray *fileNames = [LSFileSystem contentsOfDirectoryWithDirPath:libPath error:nil];
        for (NSInteger i = 0; i < fileNames.count; i++) {
            NSString *fileName = fileNames[i];
            NSString *filePath = [libPath stringByAppendingPathComponent:fileName];
            BOOL isDirectory = NO;
            // 过滤掉文件，从文件夹中查找
            if ([LSFileSystem fileExistsWithFilePath:filePath isDirectory:&isDirectory] && !isDirectory) {
                continue;
            }

            if (![fileName containsString:@"."]) {
                continue;
            }
            // 在一次生命过程中更新过的sdk不能删除，防止使用方在使用旧的
            if ([[[OPVersionDirHandler sharedInstance] updatedVersions] containsObject:fileName]) {
                continue;
            }
            
            if ([fileName isEqualToString:greyHashVersion]) {
                continue;
            }
            [[LSFileSystem main] removeFolderIfNeedWithFolderPath:filePath];
        }
    } else if (appType == OPAppTypeGadget) {
        [[LSFileSystem main] removeFolderIfNeedWithFolderPath:[[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib]];
    }
}
@end
