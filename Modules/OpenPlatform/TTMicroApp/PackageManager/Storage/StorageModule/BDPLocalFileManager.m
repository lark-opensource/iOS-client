//
//  BDPLocalFileManager.m
//  Timor
//
//  Created by liubo on 2018/11/15.
//

#import "BDPLocalFileManager.h"
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPVersionManager.h>
#import <OPFoundation/BDPFileSystemPluginDelegate.h>

#import <OPFoundation/NSData+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import <FMDB/FMDatabaseQueue.h>
#import "BDPStorageStrategy.h"
#import "BDPPackageModuleProtocol.h"
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPCommonManager.h>
#import <ECOInfra/EMAFeatureGating.h>
#import <TTMicroApp/TTMicroApp-Swift.h>

#define BDP_BASE_APP_FOLDER_NAME @"app"
#define BDP_BASE_TMP_FOLDER_NAME @"app_tmp"
#define BDP_BASE_RESOURCE_FOLDER_NAME @"__resources__"
#define BDP_JSLIB_COMPONENTS_FOLDER_NAME @"__components__"

#define BDP_JSLIB_APPCORE_FILE_NAME @"tma-core.js"

#define BDP_APP_LIST_CACHE_NAME @"appListCache"

#define BDP_APP_RESOURCE_FOLDER_NAME @"resources"
#define BDP_APP_STORAGE_FILE_NAME @"userStorage.db"

#define BDP_WEBP_HOOK_FILE_NAME @"webp-hook.js"

#define APP_AUXILIARY_FOLDER @"__auxiliary__"

#define BDP_CACHE_FODLER_NAME @"tma_cache"

typedef struct BDPMatchResult {
    /** 是否匹配条件 */
    BOOL isMatched;
    /** 是否完全一致 */
    BOOL isEqual;
    /** 匹配到的位置 */
    NSUInteger toIndex;
} BDPMatchResult;

@interface BDPLocalFileManager ()

@property (nonatomic, assign) BDPType type;

@property (nonatomic, copy) NSString *accountToken;
/// xxx/Library/tma
@property (nonatomic, copy) NSString *baseFolderPath;
/// xxx/Library/tma/app_tmp
@property (nonatomic, copy) NSString *tempFolderPath;
/// xxx/Library/tma/app
@property (nonatomic, copy) NSString *appFolderPath;
/// xxx/Library/tma/app/__dev__
@property (nonatomic, copy) NSString *JSLibPath;
/// xxx/Library/tma/app/__components__
@property (nonatomic, copy) NSString *componentsPath;
/// xxx/Library/tma/app/__dev__/h5jssdk
@property (nonatomic, copy) NSString *H5JSLibPath;
/// xxx/Library/tma/app/offline
@property (nonatomic, copy) NSString *offlineFolderPath;
/// xxx/Library/tma/app/__resources__
@property (nonatomic, copy) NSString *resourceFolderPath;
/// xxx/Library/tma/app/internalBundle
@property (nonatomic, copy) NSString *internalBundleFolderPath;

/// /tma/app/下新增的文件夹辛苦该属性getter方法中，登记一下
@property (nonatomic, copy) NSSet *appFolderNameSet;

#pragma mark - Database

/// 供应用全局存储数据的数据库操作队列
@property (nonatomic, strong, readwrite) FMDatabaseQueue *dbQueue;

/// 支持分用户维度存储KV键值对的Storage
@property (nonatomic, strong, readwrite) TMAKVStorage *kvStorage;

@end

@implementation BDPLocalFileManager

#pragma mark - Life Cycle

static NSMutableDictionary<NSNumber *, BDPLocalFileManager *> *kSingletonInstances = nil;
+ (instancetype)sharedInstanceForType:(BDPType)type {
    BDPLocalFileManager *instance = nil;
    @synchronized (self) {
        if (!kSingletonInstances) {
            kSingletonInstances = [NSMutableDictionary<NSNumber *, BDPLocalFileManager *> dictionary];
        }
        instance = kSingletonInstances[@(type)];
        if (!instance) {
            instance = [[BDPLocalFileManager alloc] initWithType:type];
            [instance buildLocalFileManager];
            kSingletonInstances[@(type)] = instance;
        }
    }
    return instance;
}

+ (void)clearAllSharedInstances {
    @synchronized (self) {
        [kSingletonInstances enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, BDPLocalFileManager * _Nonnull obj, BOOL * _Nonnull stop) {
            [obj closeDBQueue];
        }];
        [kSingletonInstances removeAllObjects];
    }
}

+ (void)clearSharedInstanceForType:(BDPType)type {
    @synchronized (self) {
        BDPLocalFileManager *fileManager = kSingletonInstances[@(type)];
        [fileManager closeDBQueue];
        kSingletonInstances[@(type)] = nil;
    }
}

- (instancetype)initWithType:(BDPType)type {
    return [self initWithType:type accountToken:nil];
}

- (instancetype)initWithType:(BDPType)type accountToken:(NSString *)accountToken {
    if (self = [super init]) {
        self.type = type;
        self.accountToken = accountToken;
        [self initPaths];
    }
    return self;
}

- (void)dealloc {
    [self closeDBQueue];
}

- (void)initPaths {
    BDPPlugin(fileSystemPlugin, BDPFileSystemPluginDelegate);

    NSString *libraryPath = [fileSystemPlugin bdp_documentRootDirectoryWithCustomAccountToken:self.accountToken];

    NSString *baseFolderName = [BDPStorageStrategy rootDirectoryPathForType:self.type];
    _baseFolderPath = [libraryPath stringByAppendingPathComponent:baseFolderName];
    _appFolderPath = [_baseFolderPath stringByAppendingPathComponent:BDP_BASE_APP_FOLDER_NAME];
    _tempFolderPath = [_baseFolderPath stringByAppendingPathComponent:BDP_BASE_TMP_FOLDER_NAME];
    _JSLibPath = [_appFolderPath stringByAppendingPathComponent:[BDPLocalFileManager JSLibFolderName]];
    _H5JSLibPath = [_appFolderPath stringByAppendingPathComponent:[BDPLocalFileManager H5JSLibFolderName]];
    _componentsPath = [_appFolderPath stringByAppendingFormat:[BDPLocalFileManager componentsFolderName]];
    _resourceFolderPath = [_appFolderPath stringByAppendingPathComponent:BDP_BASE_RESOURCE_FOLDER_NAME];
    _offlineFolderPath = [_appFolderPath stringByAppendingPathComponent:[BDPLocalFileManager offlineFolderName]];
    _internalBundleFolderPath = [_appFolderPath stringByAppendingPathComponent:BDP_INTERNALBUNDLE_FOLDER_NAME];
    
    _appFolderNameSet = [NSSet setWithObjects:BDP_JSLIB_FOLDER_NAME, BDP_H5JSLIB_FOLDER_NAME, BDP_APP_RESOURCE_FOLDER_NAME, BDP_OFFLINE_FOLDER_NAME, BDP_INTERNALBUNDLE_FOLDER_NAME, nil];
}

- (void)buildLocalFileManager {
    
    [[LSFileSystem main] createFolderIfNeedWithFolderPath:_baseFolderPath];
    [[LSFileSystem main] createFolderIfNeedWithFolderPath:_appFolderPath];
    [[LSFileSystem main] createFolderIfNeedWithFolderPath:_tempFolderPath];
    [[LSFileSystem main] createFolderIfNeedWithFolderPath:_resourceFolderPath];
    BDPLogTagInfo(kBDPLocalFileManagerLogTag, @"%@", _baseFolderPath);

    [self buildDBDatabase];
}

#pragma mark - Database

// 老版本
#define DB_OLD_VERSION_FILENAME @"BDPStorageV01.db"
// 当前版本
#define DB_CUR_VERSION_FILENAME @"BDPStorageV02.db"
#define BDP_STORAGE_KV_NAME @"BDPKVStorageTable"

- (void)buildDBDatabase {
    NSString *dbFilePath = [[self baseFolderPath] stringByAppendingPathComponent:DB_CUR_VERSION_FILENAME];
    self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbFilePath];

    self.kvStorage = [TMAKVStorage storageForName:BDP_STORAGE_KV_NAME dbQueue:self.dbQueue];
}

- (void)closeDBQueue {
    if (self.dbQueue != nil) {
        [self.dbQueue close];
        self.dbQueue = nil;
    }
}

#pragma mark - Folder Name

+ (NSString *)JSLibFolderName {
    return BDP_JSLIB_FOLDER_NAME;
}

+ (NSString *)H5JSLibFolderName {
    return BDP_H5JSLIB_FOLDER_NAME;
}

+ (NSString *)componentsFolderName {
    return BDP_JSLIB_COMPONENTS_FOLDER_NAME;
}

+ (NSString *)offlineFolderName {
    return BDP_OFFLINE_FOLDER_NAME;
}

#pragma mark - Basic Path

/// 获取指定应用目录/文件路径类型的路径
/// @param type 应用目录/文件路径类型
- (NSString *)pathForType:(BDPLocalFilePathType)type {
    switch (type) {
        case BDPLocalFilePathTypeBase:
            return self.baseFolderPath;
        case BDPLocalFilePathTypeApp:
            return self.appFolderPath;
        case BDPLocalFilePathTypeTemp:
            return self.tempFolderPath;
        case BDPLocalFilePathTypeJSLib:
            return self.JSLibPath;
        case BDPLocalFilePathTypeH5JSLib:
            return self.H5JSLibPath;
        case BDPLocalFilePathTypeComponents:
            return self.componentsPath;
        case BDPLocalFilePathTypeResource:
            return self.resourceFolderPath;
        case BDPLocalFilePathTypeOffline:
            return self.offlineFolderPath;
        case BDPLocalFilePathTypeInternalBundle:
            return self.internalBundleFolderPath;
        case BDPLocalFilePathTypeJSLibAppCore:
            return [self JSLibAppCorePath];
        case BDPLocalFilePathTypeJSLibWebpHook:
            return [self JSLibWebpHookPath];
        default:
            break;
    }
    NSString *errorMessage = [NSString stringWithFormat:@"illegal type: %@", @(type)];
    NSAssert(NO, errorMessage);
    BDPLogError(errorMessage);
    return nil;
}

#pragma mark - App Data Path

///xxx/Library/tma/appListCache/[userID]：小程序最近使用列表所在目录
- (NSString *)appListCachePathWithUserID:(NSString *)userID {
    if ([userID length] <= 0) {
        return nil;
    }
    NSString *reVal = [_baseFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", BDP_APP_LIST_CACHE_NAME, userID]];
    return reVal;
}

//xxx/Library/tma/app/tt00a0000bc0000def
- (NSString *)appBasicPathWithUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return nil;
    }
    return [self.appFolderPath stringByAppendingPathComponent:uniqueID.identifier];
}

//xxx/Library/tma/app/tt00a0000bc0000def/1.0.0
- (NSString *)appVersionPathWithUniqueID:(BDPUniqueID *)uniqueID version:(NSString *)version {
    if (!uniqueID.isValid || [version length] <= 0) {
        return nil;
    }
    NSString *reVal = [[self appBasicPathWithUniqueID:uniqueID] stringByAppendingPathComponent:version];
    return reVal;
}

- (NSString *)appPkgDirPathWithUniqueID:(BDPUniqueID *)uniqueID name:(NSString *)name {
    if (!uniqueID.isValid || !name.length) {
        return nil;
    }
    return [[self appBasicPathWithUniqueID:uniqueID] stringByAppendingPathComponent:name];
}

- (NSString *)appPkgPathWithUniqueID:(BDPUniqueID *)uniqueID name:(NSString *)name {
    return [[self appPkgDirPathWithUniqueID:uniqueID name:name] stringByAppendingPathComponent:BDPLocalPackageFileName];
}

- (NSString *)appPkgAuxiliaryDirWithUniqueID:(BDPUniqueID *)uniqueID name:(NSString *)name {
    return [[self appPkgDirPathWithUniqueID:uniqueID name:name] stringByAppendingPathComponent:APP_AUXILIARY_FOLDER];
}

- (NSString *)appPkgAuxiliaryPathWithUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName fileName:(NSString *)fileName {
    return [[self appPkgAuxiliaryDirWithUniqueID:uniqueID name:pkgName] stringByAppendingPathComponent:fileName];
}

//xxx/Library/tma/app/tt00a0000bc0000def/tmp
- (NSString *)appTempPathWithUniqueID:(BDPUniqueID *)uniqueID {
    NSString *reVal = [[self appBasicPathWithUniqueID:uniqueID] stringByAppendingPathComponent:BDP_APP_TMP_FOLDER_NAME];
    return reVal;
}

//xxx/Library/tma/app/tt00a0000bc0000def/sandbox
- (NSString *)appSandboxPathWithUniqueID:(BDPUniqueID *)uniqueID {
    NSString *reVal = [[self appBasicPathWithUniqueID:uniqueID] stringByAppendingPathComponent:BDP_APP_SANDBOX_FOLDER_NAME];
    return reVal;
}

//xxx/Library/tma/app/tt00a0000bc0000def/private_tmp
- (NSString *)appPrivateTmpPathWithUniqueID:(OPAppUniqueID *)uniqueID {
    NSString *reVal = [[self appBasicPathWithUniqueID:uniqueID] stringByAppendingPathComponent:APP_PRIVATE_TEMP_FOLDER_NAME];
    return reVal;
}

//xxx/Library/tma/app/tt00a0000bc0000def/userStorage.db
- (NSString *)appStorageFilePathWithUniqueID:(BDPUniqueID *)uniqueID {
    NSString *reVal = [[self appBasicPathWithUniqueID:uniqueID] stringByAppendingPathComponent:BDP_APP_STORAGE_FILE_NAME];
    return reVal;
}

- (NSSet<NSString *> *)appFolderSpecialFileNames {
    return [NSSet setWithObjects:BDP_APP_TMP_FOLDER_NAME, BDP_APP_SANDBOX_FOLDER_NAME, BDP_APP_STORAGE_FILE_NAME, nil];
}

//xxx/Library/tma/app/__dev__/tma-core.js
- (NSString *)JSLibAppCorePath {
    NSString * jsRootPath = [self JSLibPath];
    NSString *reVal = [jsRootPath stringByAppendingPathComponent:BDP_JSLIB_APPCORE_FILE_NAME];
    return reVal;
}

//xxx/Library/tma/app/__components__
- (NSString *)componentsPath {
    return [[self appFolderPath] stringByAppendingPathComponent: BDP_JSLIB_COMPONENTS_FOLDER_NAME];
}

/// xxx/Library/tma/app/__dev__/webp-hook.js
- (NSString *)JSLibWebpHookPath {
    NSString * jsRootPath = [self JSLibPath];
    NSString *reVal = [jsRootPath stringByAppendingPathComponent:BDP_WEBP_HOOK_FILE_NAME];
    return reVal;
}

#pragma mark - App Resource Path

//xxx/Library/tma/app/tt00a0000bc0000def/resources
- (NSString *)appResourceFolderPathWithUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return nil;
    }
    
    NSString *reVal = [[self appBasicPathWithUniqueID:uniqueID] stringByAppendingPathComponent:BDP_APP_RESOURCE_FOLDER_NAME];
    return reVal;
}

//xxx/Library/tma/app/tt00a0000bc0000def/resources/resID
- (NSString *)appResourcePathWithUniqueID:(BDPUniqueID *)uniqueID resourceID:(NSString *)resID {
    if (!uniqueID.isValid || [resID length] <= 0) {
        return nil;
    }
    
    NSString *reVal = [[self appResourceFolderPathWithUniqueID:uniqueID] stringByAppendingPathComponent:resID];
    return reVal;
}

#pragma mark - Resource Path

// 替换 【BDP_TTFILE_SCHEME +（APP_TEMP_DIR_NAME or APP_USER_DIR_NAME）】 为 realPath
- (NSString *)convertTTFilePathToRealPath:(NSString *)ttFilePath uniqueID:(BDPUniqueID *)uniqueID useFileScheme:(BOOL)useFileScheme {
    if ([ttFilePath hasPrefix:BDP_TTFILE_SCHEME]) { // ttfile干掉query
        ttFilePath = [ttFilePath bdp_urlWithoutParmas];
    }

    NSString *resultStr = nil;
    NSMutableString *tmpStr = [ttFilePath mutableCopy];
    BDPMatchResult result = {0, 0, 0};
    if ((result = [[self class] checkScheme:BDP_TTFILE_SCHEME andPrefixPath:APP_TEMP_DIR_NAME ofUrl:ttFilePath]).isMatched) {
        [tmpStr deleteCharactersInRange:NSMakeRange(0, result.toIndex)];
        NSString *tmpPath = [self appTempPathWithUniqueID:uniqueID];
        resultStr = [NSString stringWithFormat:@"%@/%@", tmpPath, tmpStr];
        NSString *standPath = [resultStr stringByStandardizingPath];
        if (![standPath hasPrefix:tmpPath]) {
            return nil;
        }
    } else if ((result = [[self class] checkScheme:BDP_TTFILE_SCHEME andPrefixPath:APP_USER_DIR_NAME ofUrl:ttFilePath]).isMatched) {
        [tmpStr deleteCharactersInRange:NSMakeRange(0, result.toIndex)];
        NSString *sandboxPath = [self appSandboxPathWithUniqueID:uniqueID];
        resultStr = [NSString stringWithFormat:@"%@/%@", sandboxPath, tmpStr];
        NSString *standPath = [resultStr stringByStandardizingPath];
        if (![standPath hasPrefix:sandboxPath]) {
            return nil;
        }
    }
    return resultStr;
}

- (BDPLocalFileInfo *)universalFileInfoWithRelativePath:(NSString *)rPath
                                               uniqueID:(OPAppUniqueID *)uniqueID
                                          useFileScheme:(BOOL)useFileScheme {
    if (!rPath || ![rPath isKindOfClass:[NSString class]] || !uniqueID.isValid) {
        BDPLogError(@"invalid params: %@", BDPParamStr(rPath, uniqueID));
        return nil;
    }

    BDPLocalFileInfo *fileInfo = [[BDPLocalFileInfo alloc] init];
    // 有common的直接取对应model的pkgName。无common的（如网页应用）则没有pkgName
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
    NSString *pkgName = common.model.pkgName ?: @"";
    // TODO: 需要确认是使用 appID 还是 identifier
    fileInfo.appId = uniqueID.appID;
    fileInfo.pkgName = pkgName;
    fileInfo.path = rPath;

    //Check Http(s) Address
    if ([rPath hasPrefix:@"http://"] || [rPath hasPrefix:@"https://"]) {
        return fileInfo;
    }

    NSString *resultStr = nil;
    NSMutableString *tmpStr = [rPath mutableCopy];
    BDPMatchResult result = {0, 0, 0};
    if ((result = [[self class] checkScheme:BDP_TTFILE_SCHEME andPrefixPath:APP_TEMP_DIR_NAME ofUrl:rPath]).isMatched) {
        resultStr = [self convertTTFilePathToRealPath:rPath uniqueID:uniqueID useFileScheme:useFileScheme];
        if (resultStr == nil) {
            return nil;
        }
    } else if ((result = [[self class] checkScheme:BDP_TTFILE_SCHEME andPrefixPath:APP_USER_DIR_NAME ofUrl:rPath]).isMatched) {
        resultStr = [self convertTTFilePathToRealPath:rPath uniqueID:uniqueID useFileScheme:useFileScheme];
        if (resultStr == nil) {
            return nil;
        }
    } else if (!BDPIsEmptyString(pkgName)) {
        // 以下都是基于有pkgName，会转换成pkg包目录下的文件
        if ([rPath hasPrefix:[self appPkgAuxiliaryDirWithUniqueID:uniqueID name:pkgName]]) { // 如果资源是在pkg包的辅助目录下(音视频文件)
            fileInfo.path = rPath;
            return fileInfo;
        } else if ([rPath hasPrefix:APP_AUXILIARY_FOLDER]) {
            NSString *pkgPath = [self appPkgDirPathWithUniqueID:uniqueID name:pkgName];
            fileInfo.path = [pkgPath stringByAppendingPathComponent:rPath];
            return fileInfo;
        } else {
            if ([rPath hasPrefix:@"./"]) {
                [tmpStr deleteCharactersInRange:[rPath rangeOfString:@"./"]];
            } else if ([rPath hasPrefix:@"/"]) {
                [tmpStr deleteCharactersInRange:NSMakeRange(0, 1)];
            } else if ([rPath containsString:@":"]) {
                return nil;
            }
            NSString *rootPath = [self appPkgDirPathWithUniqueID:uniqueID name:pkgName];
            resultStr = [rootPath stringByAppendingPathComponent:rPath];
            NSString *standPath = [resultStr stringByStandardizingPath];
            if (![standPath hasPrefix:rootPath]) {
                return nil;
            }
            fileInfo.isInPkg = YES;
            fileInfo.pkgPath = tmpStr;
        }
    } else {
        // 没有包目录，目前没有给默认包目录的做法，不应该走到这
        // 等待后续infra组定义H5存储模型后动态调整
        NSAssert(NO, @"should not enter here");
        return nil;
    }

    if (useFileScheme) {
        resultStr = [NSString stringWithFormat:@"file://%@", resultStr];
        resultStr = [resultStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }

    fileInfo.path = resultStr;
    return fileInfo;
}

- (BDPLocalFileInfo *)fileInfoWithRelativePath:(NSString *)rPath
                          uniqueID:(BDPUniqueID *)uniqueID
                                       pkgName:(NSString *)pkgName
                                 useFileScheme:(BOOL)useFileScheme {
    if (!rPath || ![rPath isKindOfClass:[NSString class]] || !uniqueID.isValid || !pkgName) {
        BDPLogError(@"invalid params: %@", BDPParamStr(rPath, uniqueID, pkgName));
        return nil;
    }
    
    BDPLocalFileInfo *fileInfo = [[BDPLocalFileInfo alloc] init];
    // TODO: 需要确认是使用 appID 还是 identifier
    fileInfo.appId = uniqueID.appID;
    fileInfo.pkgName = pkgName;
    fileInfo.path = rPath;
    
    //Check Http(s) Address
    if ([rPath hasPrefix:@"http://"] || [rPath hasPrefix:@"https://"]) {
        return fileInfo;
    }
    
    NSString *resultStr = nil;
    NSMutableString *tmpStr = [rPath mutableCopy];
    BDPMatchResult result = {0, 0, 0};
    if ((result = [[self class] checkScheme:BDP_TTFILE_SCHEME andPrefixPath:APP_TEMP_DIR_NAME ofUrl:rPath]).isMatched) {
        resultStr = [self convertTTFilePathToRealPath:rPath uniqueID:uniqueID useFileScheme:useFileScheme];
        if (resultStr == nil) {
            return nil;
        }
    } else if ((result = [[self class] checkScheme:BDP_TTFILE_SCHEME andPrefixPath:APP_USER_DIR_NAME ofUrl:rPath]).isMatched) {
        resultStr = [self convertTTFilePathToRealPath:rPath uniqueID:uniqueID useFileScheme:useFileScheme];
        if (resultStr == nil) {
            return nil;
        }
    } else if ([rPath hasPrefix:[self appPkgAuxiliaryDirWithUniqueID:uniqueID name:pkgName]]) { // 如果资源是在pkg包的辅助目录下(音视频文件)
        fileInfo.path = rPath;
        return fileInfo;
    } else if ([rPath hasPrefix:APP_AUXILIARY_FOLDER]) {
        NSString *pkgPath = [self appPkgDirPathWithUniqueID:uniqueID name:pkgName];
        fileInfo.path = [pkgPath stringByAppendingPathComponent:rPath];
        return fileInfo;
    } else {
        if ([rPath hasPrefix:@"./"]) {
            [tmpStr deleteCharactersInRange:[rPath rangeOfString:@"./"]];
        } else if ([rPath hasPrefix:@"/"]) {
            [tmpStr deleteCharactersInRange:NSMakeRange(0, 1)];
        } else if ([rPath containsString:@":"]) {
            return nil;
        }
        NSString *rootPath = [self appPkgDirPathWithUniqueID:uniqueID name:pkgName];
        resultStr = [rootPath stringByAppendingPathComponent:rPath];
        NSString *standPath = [resultStr stringByStandardizingPath];
        if (![standPath hasPrefix:rootPath]) {
            return nil;
        }
        fileInfo.isInPkg = YES;
        fileInfo.pkgPath = tmpStr;
    }
    
    if (useFileScheme) {
        resultStr = [NSString stringWithFormat:@"file://%@", resultStr];
        resultStr = [resultStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    fileInfo.path = resultStr;
    return fileInfo;
}

//xxx/Library/tma/app/__resources__/resID
- (NSString *)resourcePathWithResourceID:(NSString *)resID {
    if ([resID length] <= 0) {
        return nil;
    }
    NSString *reVal = [_resourceFolderPath stringByAppendingPathComponent:resID];
    return reVal;
}

#pragma mark - App Model File Handle

- (BOOL)appVersionFolderExistForModel:(BDPModel *)appModel {
    if (appModel == nil || !appModel.uniqueID.isValid || [[appModel version] length] <= 0) {
        return NO;
    }
    
    NSString *filePath = [self appVersionPathWithUniqueID:[appModel uniqueID] version:[appModel version]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return YES;
    }
    return NO;
}

#pragma mark - Clean
//xxx/Library/tma/app/tt00a0000bc0000def/sandbox
//xxx/Library/tma/app/tt00a0000bc0000def/userStorage.db
- (void)cleanAllUserCacheExceptIdentifiers:(NSSet<NSString *> *)identifiers {
    // 新老目录都要尝试删除
    NSArray<NSString *> *folders = @[self.appFolderPath];
    
    for (NSString *folderPath in folders) {
        NSArray *filePaths = [LSFileSystem contentsOfDirectoryWithDirPath:folderPath error:nil];
        
        for (NSString *subPath in filePaths) {
            if ([self.appFolderNameSet containsObject:subPath]) { // 非小程序目录跳过
                continue;
            }
            if (identifiers && [identifiers containsObject:subPath]) { // subPath文件名命中要排除的identifier
                continue;
            }
            NSArray *filesInApp = [LSFileSystem contentsOfDirectoryWithDirPath:[NSString stringWithFormat:@"%@/%@", folderPath, subPath] error:nil];
            for (NSString *path in filesInApp) {
                if ([path isEqualToString:BDP_APP_SANDBOX_FOLDER_NAME]) {
                    // Clear All User Files (../tma/app/[identifier]/sandbox)
                    NSString *sandboxPath = [NSString stringWithFormat:@"%@/%@/%@", folderPath, subPath, BDP_APP_SANDBOX_FOLDER_NAME];
                    [[LSFileSystem main] removeItemAtPath:sandboxPath error:nil];
                    BDPLogInfo(@"fileManager remove: %@", path);
                } else if ([path isEqualToString:BDP_APP_STORAGE_FILE_NAME]) {
                    // Clear Storage File (../tma/app/[identifier]/userStorage.db)
                    NSString *storageFilePath = [NSString stringWithFormat:@"%@/%@/%@", folderPath, subPath, BDP_APP_STORAGE_FILE_NAME];
                    [[LSFileSystem main] removeItemAtPath:storageFilePath error:nil];
                    BDPLogInfo(@"fileManager remove: %@", path);
                }
            }
        }
    }
}

- (void)cleanOldAppCacheExceptIdentifiers:(NSSet<NSString *> *)identifiers {
    if (!self.appFolderPath) {
        return;
    }
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.appFolderPath error:nil];
    for (NSString *fileName in fileNames) {
        if ([self.appFolderNameSet containsObject:fileName]) { // 非小程序目录跳过
            continue;
        }
        if ([identifiers containsObject:fileName]) { // fileName文件名命中要排除的 identifier
            continue;
        }
        NSString *filePath = [self.appFolderPath stringByAppendingPathComponent:fileName];
        BDPLogInfo(@"fileManager remove: %@", filePath);
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
}

- (void)cleanAllAppCacheExceptIdentifiers:(NSSet<NSString *> *)identifiers {
    NSArray<NSString *> *folderPaths = @[self.appFolderPath ?: @""];
    for (NSString *folderPath in folderPaths) {
        NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
        for (NSString *fileName in fileNames) {
            if ([self.appFolderNameSet containsObject:fileName]) { // 非小程序目录跳过
                continue;
            }
            if ([identifiers containsObject:fileName]) { // fileName文件名命中要排除的identifier
                continue;
            }
            NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
            BDPLogInfo(@"fileManager remove: %@", filePath);
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }
}

//删除xxx/Library/tma目录并重建，JSLib将被保留。
- (void)restoreToOriginalState {
    // Refactor: 该方法执行时, 还需考虑内存中的缓存对象，未来移到DiskManager中, 避免引入其他依赖
    
    //保留当前的JSLib
    NSString *jsSDKPath = [self JSLibPath];
    NSString *tempSDKPath = [[[self baseFolderPath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:BDP_JSLIB_FOLDER_NAME];
    [[LSFileSystem main] moveItemAtPath:jsSDKPath toPath:tempSDKPath error:nil];
    [BDPVersionManager resetLocalLibVersionCache:OPAppTypeGadget];  // 改了JSLibPath目录，清一下jssdk版本号内存缓存
    
    [[LSFileSystem main] removeFolderIfNeedWithFolderPath:_appFolderPath];
    [[LSFileSystem main] removeFolderIfNeedWithFolderPath:_tempFolderPath];
        
    [[LSFileSystem main] createFolderIfNeedWithFolderPath:_baseFolderPath];
    [[LSFileSystem main] createFolderIfNeedWithFolderPath:_appFolderPath];
    [[LSFileSystem main] createFolderIfNeedWithFolderPath:_tempFolderPath];
    [[LSFileSystem main] createFolderIfNeedWithFolderPath:_resourceFolderPath];
    // 删除app文件夹的时候，删除代码包下载信息存储表格
    [self clearPkgInfoTable];
    
    //保留当前的JSLib
    [[LSFileSystem main] moveItemAtPath:tempSDKPath toPath:jsSDKPath error:nil];
    [BDPVersionManager setupDefaultVersionIfNeed];
    
    BDPLogTagInfo(kBDPLocalFileManagerLogTag, @"%@", _baseFolderPath);
}

- (void)restoreToOriginalStateExceptAppFolder {
    [BDPFileSystemHelper removeFolderIfNeed:_tempFolderPath];
    
    [BDPFileSystemHelper createFolderIfNeed:_baseFolderPath];
    [BDPFileSystemHelper createFolderIfNeed:_tempFolderPath];
    [BDPFileSystemHelper createFolderIfNeed:_resourceFolderPath];
}

/// 删除代码包下载信息存储表格
- (void)clearPkgInfoTable {
    [BDPGetResolvedModule(BDPPackageModuleProtocol, self.type).packageInfoManager clearPkgInfoTable];
}

- (void)restoreAppFolderToOriginalState {
    // tma/app下仅保留__dev__
    NSString *jsSDKPath = [self JSLibPath];
    NSString *tempSDKPath = [[[self baseFolderPath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:BDP_JSLIB_FOLDER_NAME];
    [[NSFileManager defaultManager] moveItemAtPath:jsSDKPath toPath:tempSDKPath error:nil];
    [BDPVersionManager resetLocalLibVersionCache:OPAppTypeGadget];  // 改了JSLibPath目录，清一下jssdk版本号内存缓存
    
    // 删除重建
    [BDPFileSystemHelper removeFolderIfNeed:self.appFolderPath];
    [BDPFileSystemHelper createFolderIfNeed:self.appFolderPath];
    // 删除app文件夹的时候，删除代码包下载信息存储表格
    [self clearPkgInfoTable];
    
    // __dev__还原位置
    [[NSFileManager defaultManager] moveItemAtPath:tempSDKPath toPath:jsSDKPath error:nil];
    
    [BDPVersionManager setupDefaultVersionIfNeed];
}

#pragma mark - Utilities
+ (BDPMatchResult)checkScheme:(NSString *)scheme
              andPrefixPath:(NSString *)prefixPath
                      ofUrl:(NSString *)url {
    if (scheme && prefixPath && (url.length > scheme.length + prefixPath.length)) {
        NSInteger uIndex = 0;
        NSInteger sIndex = 0;
        // scheme
        while (sIndex < scheme.length && [scheme characterAtIndex:sIndex] == [url characterAtIndex:uIndex]) {
            uIndex = ++sIndex;
        }
        if ([url characterAtIndex:uIndex++] == ':') {
            // 过滤 分隔符/
            while (uIndex < url.length && [url characterAtIndex:uIndex] == '/') {
                uIndex++;
            }
            // prefix path
            NSInteger pIndex = 0;
            while (uIndex < url.length
                   && pIndex < prefixPath.length
                   && [prefixPath characterAtIndex:pIndex] == [url characterAtIndex:uIndex]) {
                uIndex++;
                pIndex++;
            }
            if (uIndex < url.length && [url characterAtIndex:uIndex] == '/') {
                uIndex++;
            }
            if (pIndex == prefixPath.length) {
                return (BDPMatchResult){YES, uIndex == url.length, uIndex};
            }
            
        }
    }
    return (BDPMatchResult){NO, NO, 0};
}

- (BOOL)hasWriteRightsForPath:(NSString *)path onUniqueID:(BDPUniqueID *)uniqueID {
    return [self containsInSandboxDirForPath:path onUniqueID:uniqueID];
}

- (BOOL)hasDownloadFileRightsForPath:(NSString *)path onUniqueID:(BDPUniqueID *)uniqueID {// 和 hasRemoveRightsForPath 一样的方法？
    return [self containsInSandboxDirForPath:path onUniqueID:uniqueID] || [self containsInTempDirForPath:path onUniqueID:uniqueID];
}

- (BOOL)hasRemoveRightsForPath:(NSString *)path onUniqueID:(BDPUniqueID *)uniqueID {
    return [self containsInSandboxDirForPath:path onUniqueID:uniqueID] || [self containsInTempDirForPath:path onUniqueID:uniqueID];
}

/// 确认path 不是 ttfile://user 并且也不是 sandbox目录， 且在sandbox目录里面
- (BOOL)containsInSandboxDirForPath:(NSString *)path onUniqueID:(BDPUniqueID *)uniqueID {
    NSString *sandboxPath = [self appSandboxPathWithUniqueID:uniqueID];

    // 去除路径最末尾的@"/"
    if ([path hasSuffix:@"/"]) {
        path = [path substringWithRange:NSMakeRange(0, ((int)[path length]-1))];
    }

    // Bug: equal失效
    // path 不是 ttfile:user 并且也不是 sandbox目录， 在sandbox目录里面、是可以操作的。
    return ![path isEqualToString:APP_FILE_USER_PREFIX()]
    && ![path isEqualToString:sandboxPath]
    && ([path hasPrefix:APP_FILE_USER_PREFIX()] || [path hasPrefix:sandboxPath]);
}

/// 确认path 不是 ttfile://temp 并且也不是 temp目录， 且在temp目录里面
- (BOOL)containsInTempDirForPath:(NSString *)path onUniqueID:(BDPUniqueID *)uniqueID {
    NSString *tempPath = [self appTempPathWithUniqueID:uniqueID];

    // 去除路径最末尾的@"/"
    if ([path hasSuffix:@"/"]) {
        path = [path substringWithRange:NSMakeRange(0, ((int)[path length]-1))];
    }

    // path 不是 ttfile:user 并且也不是 sandbox目录， 在sandbox目录里面、是可以操作的。
    return ![path isEqualToString:APP_FILE_TEMP_PREFIX()]
    && ![path isEqualToString:tempPath]
    && ([path hasPrefix:APP_FILE_TEMP_PREFIX()] || [path hasPrefix:tempPath]);
}

- (BOOL)hasWriteRightsForRootPathOrSubpath:(NSString *)directory onUniqueID:(BDPUniqueID *)uniqueID {
    NSString *sandboxPath = [self appSandboxPathWithUniqueID:uniqueID];
    if ([directory hasSuffix:@"/"]) { // 去除路径最末尾的@"/"
        directory = [directory substringWithRange:NSMakeRange(0, directory.length - 1)];
    }
    // path是 ttfile://user || sandbox目录 || ttfile://user目录的子目录 || sandbox目录的子目录，是可以操作的。
    return [directory hasPrefix:APP_FILE_USER_PREFIX()] || [directory hasPrefix:sandboxPath];
}

+ (BOOL)hasAccessRightsForPath:(NSString *)path onSandbox:(id<BDPSandboxProtocol> )sandbox {
    /// 标准化读写能力，根目录可读不可写
    if ([EMAFeatureGating boolValueForKey:@"ecosystem.sandbox.standard.readaccess"]) {
        NSString *standardPath = path.stringByStandardizingPath;
        NSString *standardPkgPath = sandbox.rootPath.stringByStandardizingPath;
        NSString *standardUserPath = sandbox.userPath.stringByStandardizingPath;
        NSString *standardTempPath = sandbox.tmpPath.stringByStandardizingPath;

        BOOL accessPkg = !BDPIsEmptyString(standardPkgPath) && [standardPath hasPrefix:standardPkgPath];
        BOOL accessUser = !BDPIsEmptyString(standardUserPath) && [standardPath hasPrefix:standardUserPath];
        BOOL accessTemp = !BDPIsEmptyString(standardTempPath) && [standardPath hasPrefix:standardTempPath];
        return accessPkg || accessUser || accessTemp;
    }
    return [path hasPrefix:sandbox.rootPath] || [path hasPrefix:sandbox.userPath] || [path hasPrefix:sandbox.tmpPath];
}

/// 用户有读权限的目录：包文件夹目录，user目录，tmp目录; 有写权限的目录：user目录，tmp目录
- (BOOL)hasAccessRightsForPath:(NSString *)path onUniqueID:(OPAppUniqueID *)uniqueID {
    // 所有形态都支持user和tmp
    // 此处遵循BDPMinimalSandboxProtocol的实现
    NSString *userPath = [[self appSandboxPathWithUniqueID:uniqueID] stringByAppendingString:@"/"];
    NSString *tmpPath = [[self appTempPathWithUniqueID:uniqueID] stringByAppendingString:@"/"];

    // 有common的支持pkg, 直接取对应sandbox里的rootPath
    NSString *pkgPath = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID].sandbox.rootPath;

    /// 标准化读写能力，根目录可读不可写
    if ([EMAFeatureGating boolValueForKey:@"ecosystem.sandbox.standard.readaccess"]) {
        NSString *standardPath = path.stringByStandardizingPath;
        NSString *standardPkgPath = pkgPath.stringByStandardizingPath;
        NSString *standardUserPath = userPath.stringByStandardizingPath;
        NSString *standardTempPath = tmpPath.stringByStandardizingPath;

        BOOL accessPkg = !BDPIsEmptyString(standardPkgPath) && [standardPath hasPrefix:standardPkgPath];
        BOOL accessUser = !BDPIsEmptyString(standardUserPath) && [standardPath hasPrefix:standardUserPath];
        BOOL accessTemp = !BDPIsEmptyString(standardTempPath) && [standardPath hasPrefix:standardTempPath];
        return accessPkg || accessUser || accessTemp;
    }
    return (!BDPIsEmptyString(pkgPath) && [path hasPrefix:pkgPath]) || [path hasPrefix:userPath] || [path hasPrefix:tmpPath];
}

#pragma mark - ttfile相关

+ (NSString *)generateRandomFilePathWithType:(BDPFolderPathType)type
                                     sandbox:(id<BDPMinimalSandboxProtocol> )sandbox
                                   extension:(NSString *)extension
                               addFileScheme:(BOOL)addFileScheme {
    NSString *randomPath = BDPRandomString(15);
    if (extension.length > 0) {
        randomPath = [NSString stringWithFormat:@"%@.%@", randomPath, extension];
    }
    NSString *result = nil;
    switch (type) {
        case BDPFolderPathTypeUser:
            result = [sandbox.userPath stringByAppendingPathComponent:randomPath];
            break;
        case BDPFolderPathTypeTemp:
            result = [sandbox.tmpPath stringByAppendingPathComponent:randomPath];
            break;
        default:
            break;
    }
    
    return result && addFileScheme ? [@"file://" stringByAppendingString:result] : result;
}

+ (NSString *)addTimorAParamsIfNeededForPath:(NSString *)path sandbox:(id<BDPSandboxProtocol> )sandbox {
    NSString *result = path;
    if (sandbox && sandbox.uniqueID.appType == BDPTypeNativeApp && result.pathExtension.length > 0) { // 小程序带上identifier跟包的参数, 不然如果走拦截完全无法区分去哪里加载资源
        NSURL *url = [NSURL URLWithString:path];
        if (![url.query containsString:BDP_PKG_AID_PARAM]) {
            if (url.query.length) {
                result = [NSString stringWithFormat:@"%@&%@=%@&%@=%@", path, BDP_PKG_AID_PARAM, sandbox.uniqueID.identifier, BDP_PKG_NAME_PARAM, sandbox.pkgName];
            } else {
                result = [NSString stringWithFormat:@"%@?%@=%@&%@=%@", path, BDP_PKG_AID_PARAM, sandbox.uniqueID.identifier, BDP_PKG_NAME_PARAM, sandbox.pkgName];
            }
        }
    }
    return result;
}

@end
