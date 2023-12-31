//
//  BDPPackageLocalManager.m
//  Timor
//
//  Created by houjihu on 2020/5/21.
//

#import "BDPPackageLocalManager.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import "BDPPackageModuleProtocol.h"
#import "BDPPackageModule.h"
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPPackageDownloadDispatcher.h"
#import <OPFoundation/NSError+BDPExtension.h>
#import "BDPPackageManagerStrategy.h"
#import <OPFoundation/BDPSchemaCodec.h>
#import <OPFoundation/BDPCommonManager.h>
#import "BDPWarmBootManager.h"
#import "BDPPackageStreamingFileHandle.h"
#import <OPFoundation/EEFeatureGating.h>
#import "BDPSubPackageManager.h"
#import <OPSDK/OPSDK-Swift.h>

@implementation BDPPackageLocalManager

+ (NSString *)localPackagePathForContext:(BDPPackageContext *)context {
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, context.uniqueID.appType);
    // TODO: yinyuan 这里用了 identifier 来当做 appID 使用，需要确认
    return [[storageModule sharedLocalFileManager] appPkgPathWithUniqueID:context.uniqueID name:context.packageName];
}

+ (NSString *)localPackageDirectoryPathForContext:(BDPPackageContext *)context {
    return [self localPackageDirectoryPathForUniqueID:context.uniqueID packageName:context.packageName];
}

+ (NSString *)localPackageDirectoryPathForUniqueID:(BDPUniqueID *)uniqueID packageName:(NSString *)packageName {
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, uniqueID.appType);
    // TODO: yinyuan 这里用了 identifier 来当做 appID 使用，需要确认
    return [[storageModule sharedLocalFileManager] appPkgDirPathWithUniqueID:uniqueID name:packageName];
}

+ (BOOL)isLocalPackageExsit:(BDPPackageContext *)context {
    return  [self isLocalPackageExsit:context.uniqueID packageName:context.packageName];
}

+ (BOOL)isLocalPackageExsit:(BDPUniqueID *)uniqueID packageName:(NSString*)packageName originalMetaStr:(NSString *)metaString targetPage:(nullable NSString *)targetPage
{
    //先判断uniqueID是否命中开关，如果不命中用原来的方法判断packageName（整包）即可，速度会快一些
    if ([[BDPSubPackageManager sharedManager] enableSubPackageWithUniqueId:uniqueID]&&[OPSDKFeatureGating enablePackageExistCheckSubpackageSupport]) {
        BDPModuleManager *moduleManager = [BDPGetResolvedModule(CommonAppLoadProtocol, uniqueID.appType) moduleManager];
        MetaContext * metaContext = [[MetaContext alloc] initWithUniqueID:uniqueID token:nil];
        _Nullable id<MetaInfoModuleProtocol> metaModule = (id<MetaInfoModuleProtocol>)[moduleManager resolveModuleWithProtocol:@protocol(MetaInfoModuleProtocol)];
        id<AppMetaProtocol> appMeta = [metaModule buildMetaWith:metaString context:metaContext];
        BDPPackageContext * pacakgeContext = [[BDPPackageContext alloc] initWithAppMeta:appMeta
                                                                            packageType:BDPPackageTypePkg
                                                                            packageName:nil
                                                                                  trace:nil];
        //命中分包开关并且subPakcages长度大于0，则开了分包
        if(pacakgeContext.isSubpackageEnable) {
            NSArray * subPackages = [pacakgeContext requiredSubPackagesWithPagePath:targetPage];
            for (BDPPackageContext * subPackageContext in subPackages) {
                //和Android对齐了一下这个逻辑，分包情况下只要有一个包存在，则表明本地已存在包
                //1、独立分包（分包||主包）
                //2、普通分包（分包||主包
                //只要一个条件是true，就是已存在
                if ([self isLocalPackageExsit:subPackageContext.uniqueID packageName:subPackageContext.packageName]) {
                    BDPLogTagInfo(BDPTag.packageManager, @"isLocalPackageExsit return true because subpacakge:%@ is existed" , subPackageContext.packageName);
                    return YES;
                }
            }
            BDPLogTagInfo(BDPTag.packageManager, @"no one of subpackages existed");
        }
    }
    return [self isLocalPackageExsit:uniqueID packageName:packageName];
}

+ (BOOL)isLocalPackageExsit:(BDPUniqueID *)uniqueID packageName:(NSString *)packageName{
    BDPType appType = uniqueID.appType;
    // 检查数据库存储的本地包下载是否完成
    id<BDPPackageInfoManagerProtocol> packageInfoManager = BDPGetResolvedModule(BDPPackageModuleProtocol, appType).packageInfoManager;
    // TODO: yinyuan 确认 identifier 当做 appID 使用
    BOOL pkgDownloaded = ([packageInfoManager queryPkgInfoStatusOfUniqueID:uniqueID pkgName:packageName] == BDPPkgFileLoadStatusDownloaded);
    BOOL exist = pkgDownloaded;
    BDPLogTagInfo(BDPTag.packageManager, @"%@(%@): local package: info exist(%@)", uniqueID.identifier, packageName, @(pkgDownloaded));
    // double check：检查本地包目录是否存储
    // 文件夹存在时，代码包可能正在下载。
    // 故先判断存储信息记录的是已下载状态，再判断文件夹不存在，则清理对应的信息和文件
    if (pkgDownloaded) {
        BOOL packageDirectoryExist = [self isPackageDirectoryExistForUniqueID:uniqueID packageName:packageName];
        BDPLogTagInfo(BDPTag.packageManager, @"%@(%@): local package: file exist(%@)", uniqueID.identifier, packageName, @(packageDirectoryExist));
        // 如果文件夹不存在，则清理对应的信息和文件
        if (!packageDirectoryExist) {
            [self deleteLocalPackageWithUniqueID:uniqueID pacakgeName:packageName error:nil];
            exist = NO;
        }
    }
    BDPLogTagInfo(BDPTag.packageManager, @"%@ (%@): local package: info pkgDownloaded(%@), return: (%@)", uniqueID.identifier, packageName, @(pkgDownloaded), @(exist));
    return exist;
}

+ (BOOL)deleteLocalPackageWithContext:(BDPPackageContext *)context error:(NSError **)error {
    return [self deleteLocalPackageWithUniqueID:context.uniqueID pacakgeName:context.packageName error:error];
}
+ (BOOL)deleteLocalPackageWithUniqueID:(OPAppUniqueID *)uniqueID pacakgeName:(NSString*)packageName error:(NSError **)error {
    // 删除本地包之前，先停止相关包下载任务
    BDPPackageModule *packageModule = BDPGetResolvedModule(BDPPackageModuleProtocol, uniqueID.appType);
    if (![packageModule isKindOfClass:[BDPPackageModule class]]) {
        NSString *errorMessage = [NSString stringWithFormat:@"resoved instance(%@) conforms to BDPPackageModuleProtocol is not BDPPackageModule", packageModule];
        NSAssert(NO, errorMessage);
        NSError *moduleError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, errorMessage);
        if (error) {
            *error = moduleError;
        }
        return NO;
    }
    // TODO: 此处强转类型需要适配确认
    [packageModule.packageDownloadDispatcher stopDownloadTaskWithUniqueID:uniqueID packageName:packageName error:(OPError **)error];

    // 删除记录本地包状态的信息
    // TODO: yinyuan 确认 identifier 当做 appID 使用
    [packageModule.packageInfoManager deletePkgInfoOfUniqueID:uniqueID pkgName:packageName];

    // 删除本地包
    NSString *packageDirectoryPath = [self localPackageDirectoryPathForUniqueID:uniqueID packageName:packageName];
    return [self deleteLocalPackageWithPackageDirectoryPath:packageDirectoryPath error:error];
}

+ (NSFileHandle *)createFileHandleForContext:(BDPPackageContext *)context error:(NSError **)error {
    // 创建中间文件夹
    NSError *createDirError;
    BOOL createSuccess = [self createPackageDirectoryIfNotExistsForContext:context error:&createDirError];
    if (!createSuccess) {
        if (error) {
            *error = createDirError;
        }
        return nil;
    }

    // 创建文件
    NSString *pkgPath = [self localPackagePathForContext:context];
    if (![LSFileSystem fileExistsWithFilePath:pkgPath isDirectory:nil]) {
        if (![[LSFileSystem main] createFileAtPath:pkgPath contents:nil attributes:nil]) {
            //https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ErrorHandlingCocoa/ErrorObjectsDomains/ErrorObjectsDomains.html#//apple_ref/doc/uid/TP40001806-CH202-CJBDCIJJ
            //https://stackoverflow.com/questions/1860070/more-detailed-error-from-createfileatpath
            //createFileAtPath 没有返回NSError对象，可以通过 errno 拿到全局后通过 strerror 转换描述
            NSString *errorMessage = [NSString stringWithFormat:@"create pkg temp file(%@) failed, Error was code: %d - message: %s", pkgPath, errno, strerror(errno)];
            NSError *createFileError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_create_file_failed, errorMessage);
            if (error) {
                *error = createFileError;
            }
            return nil;
        }
    }
    return [[LSFileSystem main] fileUpdatingHandleWithFilePath:pkgPath error:nil];
}

/// 检查代码包目录是否存在
+ (BOOL)isPackageDirectoryExistForUniqueID:(OPAppUniqueID *)uniqueID packageName:(NSString *)packageName {
    NSString *pkgDirPath = [self localPackageDirectoryPathForUniqueID:uniqueID packageName:packageName];
    BOOL isDir = NO; // 这边兜底, 出现过外部直接把pkg目录当文件复写掉的情况
    BOOL exists = [LSFileSystem fileExistsWithFilePath:pkgDirPath isDirectory:&isDir];
    if (exists && isDir) {
        return YES;
    }
    return NO;
}

+ (BOOL)createPackageDirectoryIfNotExistsForContext:(BDPPackageContext *)context error:(NSError **)error {
    NSString *pkgDirPath = [self localPackageDirectoryPathForContext:context];
    BOOL isDir = NO; // 这边兜底, 出现过外部直接把pkg目录当文件复写掉的情况
    BOOL exists = [LSFileSystem fileExistsWithFilePath:pkgDirPath isDirectory:&isDir];
    if (exists && isDir) {
        return YES;
    }
    // 存在且非目录，则删除
    if (exists && !isDir) {
        NSError *removeError;
        BOOL removeSuccess = [[LSFileSystem main] removeItemAtPath:pkgDirPath error:&removeError];
        if (!removeSuccess) {
            removeError = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_delete_file_failed, removeError, BDPParamStr(pkgDirPath));
            if (error) {
                *error = removeError;
            }
            return NO;
        }
    }
    NSError *createDirError;
    BOOL createSuccess = [[LSFileSystem main] createDirectoryAtPath:pkgDirPath withIntermediateDirectories:YES attributes:nil error:&createDirError];
    if (createSuccess) {
        return YES;
    }
    // 创建包目录失败
    createDirError = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_create_file_failed, createDirError, BDPParamStr(pkgDirPath));
    if (error) {
        *error = createDirError;
    }
    return NO;
}

+ (BOOL)deleteAllLocalPackagesWithUniqueID:(BDPUniqueID *)uniqueID error:(NSError **)error {
    // TODO: yinyuan 确认 identifier 当做 appID 使用
    return [self deleteLocalPackagesForUniqueID:uniqueID excludedPackageNames:@[] error:error];
}

+ (BOOL)deleteLocalPackagesExcludeContext:(BDPPackageContext *)context error:(NSError **)error {
    NSMutableArray  *excludedPackages = (context.packageName?@[context.packageName]:@[]).mutableCopy;
    //检查一下分包，分包的内容也是不能删的
    [context.subPackages enumerateObjectsUsingBlock:^(BDPPackageContext * _Nonnull subPackage, NSUInteger idx, BOOL * _Nonnull stop) {
        if (subPackage.packageName) {
            [excludedPackages addObject:subPackage.packageName];
        }
    }];
    return [self deleteLocalPackagesForUniqueID:context.uniqueID excludedPackageNames:excludedPackages error:error];
}

+ (BOOL)deleteLocalPackagesForUniqueID:(BDPUniqueID *)uniqueID excludedPackageName:(NSString *)excludedPackageName error:(NSError **)error {
    return [self deleteLocalPackagesForUniqueID:uniqueID excludedPackageNames:@[excludedPackageName] error:error];
}

+ (BOOL)deleteLocalPackagesForUniqueID:(BDPUniqueID *)uniqueID excludedPackageNames:(NSArray<NSString *> *)excludedPackages error:(NSError **)error {
    if([OPSDKFeatureGating shouldKeepDataWith:uniqueID]){
        return YES;
    }
    NSMutableArray<NSString *> * excludedPackageNameList = @[].mutableCopy;
    [excludedPackageNameList addObjectsFromArray:excludedPackages];
    
    NSSet<BDPUniqueID *> * uniqueIds = [BDPWarmBootManager sharedManager].aliveAppUniqueIdSet;
    //先检查热启动列表（正在运行）中存在的包，如果刚好当前uniqueID还在运行中，这些包不能清
    //https://bytedance.feishu.cn/docs/doccnDFaGOfQjAErMR55S8pGRFf#
    if ([uniqueIds containsObject:uniqueID]) {
        BDPCommon * common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        if ([common.reader isKindOfClass:[BDPPackageStreamingFileHandle class]]) {
            BDPPackageContext * excludedContext = [(BDPPackageStreamingFileHandle *)common.reader packageContext];
            //判断一下是不是已经存在，存在就不添加
            if (![excludedPackageNameList containsObject:excludedContext.packageName]) {
                [excludedPackageNameList addObject:excludedContext.packageName];
            }
        }
    }

    id<BDPPackageInfoManagerProtocol> packageInfoManager = BDPGetResolvedModule(BDPPackageModuleProtocol, uniqueID.appType).packageInfoManager;
    // TODO: yinyuan 确认 identifier 当做 appID 使用
    NSArray<NSString *> *pkgNames = [packageInfoManager queryPkgNamesOfUniqueID:uniqueID status:BDPPkgFileLoadStatusDownloaded];
    BDPLogInfo(@"Start to delete packageName list(%@) exclude (%@) for id(%@), type(%@)", pkgNames, excludedPackageNameList, uniqueID.identifier, @(uniqueID.appType));
    for (NSString *packageName in pkgNames) {
        // 排查指定的包目录
        if (BDPIsEmptyString(packageName) || [excludedPackageNameList containsObject:packageName]) {
            continue;
        }
        // 由于H5小程序与小程序的文件系统是复用的，因此删除文件夹时需要判断应用类型以及文件夹命名规则
        if (![BDPPackageManagerStrategy shouldDeleteLocalPackageForAppType:uniqueID.appType packageName:packageName]) {
            continue;
        }
        NSString *toDeletePackageName = packageName;
        // TODO: yinyuan 确认 identifier 当做 appID 使用
        NSString *toDeletePackageDirectoryPath = [self localPackageDirectoryPathForUniqueID:uniqueID packageName:toDeletePackageName];
        BDPLogInfo(@"Begin to delete packageDirectory (%@) for id(%@), type(%@)", toDeletePackageDirectoryPath, uniqueID.identifier, @(uniqueID.appType));
        NSError *deleteError;
        BOOL deleteSuccess = [self deleteLocalPackageWithPackageDirectoryPath:toDeletePackageDirectoryPath error:&deleteError];
        if (!deleteSuccess) {
            if (error) {
                *error = deleteError;
            }
            return NO;
        }
        // TODO: yinyuan 确认 identifier 当做 appID 使用
        [packageInfoManager deletePkgInfoOfUniqueID:uniqueID pkgName:toDeletePackageName];
    }
    return YES;
}

+ (BOOL)deleteLocalPackageWithPackageDirectoryPath:(NSString *)packageDirectoryPath error:(NSError **)error {
    if (BDPIsEmptyString(packageDirectoryPath)) {
        NSString *errorMessage = [NSString stringWithFormat:@"no pacakgePath: %@", packageDirectoryPath];
        NSError *emptyPathError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, errorMessage);
        if (error) {
            *error = emptyPathError;
        }
        return NO;
    }
    BOOL exists = [LSFileSystem fileExistsWithFilePath:packageDirectoryPath isDirectory:nil];
    if (!exists) {
        return NO;
    }
    NSError *removedError;
    BOOL removedSuccess = [[LSFileSystem main] removeItemAtPath:packageDirectoryPath error:&removedError];
    if (!removedSuccess) {
        removedError = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_delete_file_failed, removedError, BDPParamStr(packageDirectoryPath));
        if (error) {
            *error = removedError;
        }
        return NO;
    }
    BDPLogTagInfo(BDPTag.packageManager, @"Success to delete packagePath(%@)", packageDirectoryPath);
    return YES;
}

@end
