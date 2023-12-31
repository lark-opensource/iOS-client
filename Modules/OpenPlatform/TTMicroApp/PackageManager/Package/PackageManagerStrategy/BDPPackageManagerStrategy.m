//
//  BDPPackageManagerStrategy.m
//  Timor
//
//  Created by houjihu on 2020/5/21.
//

#import "BDPPackageManagerStrategy.h"
#import <OPFoundation/TMAMD5.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import <SSZipArchive/SSZipArchive.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPLocalFileConst.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPPackageCardInstaller.h"
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import <OPFoundation/NSError+BDPExtension.h>
#import "BDPPackageUncompressedFileHandle.h"
#import "BDPPackageStreamingFileHandle.h"
#import <OPFoundation/BDPModel+H5Gadget.h>
#import <OPFoundation/BDPUtils.h>

@implementation BDPPackageManagerStrategy

#pragma mark - Public

+ (BOOL)verifyPackageWithContext:(BDPPackageContext *)context packagePath:(NSString *)packagePath error:(NSError **)error {
    NSString *md5 = context.md5;
    NSString *fileMD5 = [TMAMD5 getMD5withPath:packagePath];
    // 兼容md5为空的情况
    BOOL checks = (md5.length ? [fileMD5 hasPrefix:md5] : YES);
    if (!checks) {
        NSString *errorMessage = [NSString stringWithFormat:@"verify package failed with meta md5(%@) vs file md5(%@) for packagePath(%@) size(%@)", md5, fileMD5, packagePath, @([LSFileSystem fileSizeWithPath:packagePath])];
        NSError *verifyError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_download_md5_verified_failed, errorMessage);
        if (error) {
            *error = verifyError;
        }
    }
    return checks;
}

+ (BOOL)installPackageWithContext:(BDPPackageContext *)context packagePath:(NSString *)packagePath installPath:(NSString *)installPath error:(NSError **)error {
    return [self installPackageWithContext:context packagePath:packagePath installPath:installPath isApplePie:NO error:error];
}
+ (BOOL)installPackageWithContext:(BDPPackageContext *)context packagePath:(NSString *)packagePath installPath:(NSString *)installPath isApplePie:(BOOL)isApplePie error:(NSError **)error {
    BOOL result = NO;
    CommonMonitorWithNameIdentifierType(kEventName_op_common_package_install_start, context.uniqueID)
    .addTag(BDPTag.packageManager)
    .kv(kEventKey_load_type, BDPPkgFileReadTypeInfo(context.readType))
    .kv(kEventKey_app_version, context.version)
    .kv(kEventKey_package_name, context.packageName)
    .bdpTracing(context.trace)
    .flush();
    OPMonitorEvent *monitorResult =
    CommonMonitorWithNameIdentifierType(kEventName_op_common_package_install_result, context.uniqueID)
    .addTag(BDPTag.packageManager)
    .kv(kEventKey_load_type, BDPPkgFileReadTypeInfo(context.readType))
    .kv(kEventKey_app_version, context.version)
    .kv(kEventKey_package_name, context.packageName)
    .bdpTracing(context.trace)
    .timing();
    BDPPackageType packageType = context.packageType;
    switch (packageType) {
        case BDPPackageTypeZip: {
            result = [self unzipWithContext:context fromPath:packagePath toPath:installPath error:error];
            break;
        }
        case BDPPackageTypePkg: {
            //如果是ODR类型，需要特殊处理（ODR只有zip）
            if(isApplePie){
                result = [self unzipWithContext:context fromPath:packagePath toPath:installPath error:error];
                if(result) {
                    NSString * buildinUnzipFrom = [[installPath stringByAppendingPathComponent:context.uniqueID.identifier] stringByAppendingPathExtension:@"pkg"];
                    NSString * buildinFinalDist = [installPath stringByAppendingPathComponent:BDPLocalPackageFileName];
                    //如果目标文件已存在，直接返回安装成功
                    if ([NSFileManager.defaultManager fileExistsAtPath:buildinFinalDist]) {
                        return YES;
                    }
                    result = [NSFileManager.defaultManager copyItemAtPath:buildinUnzipFrom
                                                                   toPath:buildinFinalDist
                                                                    error:error];
                    [NSFileManager.defaultManager removeItemAtPath:buildinUnzipFrom error:nil];
                }
            } else {
                result = [self moveWithContext:context fromPath:packagePath toPath:installPath error:error];
            }
            break;
        }
        case BDPPackageTypeRaw: {
            // 增量更新的patch包下载完成后也是移动一下文件
            result = [self moveWithContext:context fromPath:packagePath toPath:installPath error:error];
            break;
        }
        default:
            break;
    }
    if (result) {
        monitorResult
        .setMonitorCode(CommonMonitorCodePackage.pkg_install_success)
        .setResultTypeSuccess()
        .timing()
        .flush();
    } else {
        NSError *resultError = error ? (*error) : nil;
        monitorResult
        .setMonitorCode(CommonMonitorCodePackage.pkg_install_failed)
        .setResultTypeFail()
        .setError(resultError)
        .timing()
        .flush();
    }
    return result;
}

/// 用于包下载完成后，加载包里的内容。此时不再依赖于下载中的任何信息
+ (id<BDPPkgFileManagerHandleProtocol>)packageReaderAfterDownloadedForPackageContext:(BDPPackageContext *)packageContext {
    return [self packageReaderAfterDownloadedForPackageContext:packageContext createLoadStatus:BDPPkgFileLoadStatusDownloaded];
}

/// 用于包下载完成后，加载包里的内容
+ (id<BDPPkgFileManagerHandleProtocol>)packageReaderAfterDownloadedForPackageContext:(BDPPackageContext *)packageContext createLoadStatus:(BDPPkgFileLoadStatus)createLoadStatus {
    id<BDPPkgFileManagerHandleProtocol> packageReader;
    BDPPackageType packageType = packageContext.packageType;
    switch (packageType) {
        case BDPPackageTypeZip: {
            packageReader = [[BDPPackageUncompressedFileHandle alloc] initWithPackageContext:packageContext createLoadStatus:createLoadStatus];
            break;
        }
        case BDPPackageTypePkg: {
            packageReader = [[BDPPackageStreamingFileHandle alloc] initAfterDownloadedWithPackageContext:packageContext];
            break;
        }
        default:
            break;
    }
    return packageReader;
}

/// 用于流式包下载过程中，加载包里的内容。非流式包在下载完成前会返回为nil
+ (nullable id<BDPPkgFileManagerHandleProtocol>)packageReaderForDownloadContext:(BDPPackageDownloadContext *)downloadContext {
    id<BDPPkgFileManagerHandleProtocol> packageReader;
    BDPPackageContext *packageContext = downloadContext.packageContext;
    BDPPackageType packageType = packageContext.packageType;
    switch (packageType) {
        case BDPPackageTypeZip: {
            // 针对非流式包(zip)，只能等包下载完成后才能加载包里的内容，不依赖于下载中的信息
            if (downloadContext.loadStatus == BDPPkgFileLoadStatusDownloaded) {
                packageReader = [self packageReaderAfterDownloadedForPackageContext:packageContext createLoadStatus:downloadContext.createLoadStatus];
            } else {
                packageReader = nil;
            }
            break;
        }
        case BDPPackageTypePkg: {
            // 针对流式包(ttpkg)，在包下载中即可加载包里的内容
            packageReader = [[BDPPackageStreamingFileHandle alloc] initWithDownloadContext:downloadContext];
            break;
        }
        default:
            break;
    }
    return packageReader;
}

+ (BOOL)shouldDeleteLocalPackageForAppType:(BDPType)appType packageName:(NSString *)packageName {
    if (BDPIsEmptyString(packageName)) {
        return NO;
    }
    if (appType == BDPTypeNativeApp) {  // 针对小程序，判断文件夹不符合H5小程序包文件夹命名规则才删除
        return ![BDPModel isH5FolderName:packageName];
    }
    return YES;
}

#pragma mark - Install Package

/// 安装zip格式的代码包
+ (BOOL)unzipWithContext:(BDPPackageContext *)context fromPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError **)error {
    // Unzip
    NSError *unzipError;
    BOOL zipSuccess = [SSZipArchive unzipFileAtPath:sourcePath toDestination:destinationPath overwrite:YES password:nil error:&unzipError];
    if (!zipSuccess) {
        NSString *errorMessage = @"unzip failed";
        unzipError = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_install_failed, unzipError, BDPParamStr(context.packageName, errorMessage, sourcePath, destinationPath));
        if (error) {
            *error = unzipError;
        }
        return NO;
    }
    [[LSFileSystem main] removeFolderIfNeedWithFolderPath:sourcePath];
    // 如果是卡片类型，则需要解析配置文件，然后再根据配置移动文件目录才算安装完成
    if (context.uniqueID.appType == BDPTypeNativeCard) {
        NSError *installError;
        BOOL installed = [BDPPackageCardInstaller installWithPackageDirectoryPath:destinationPath error:&installError];
        if (!installed) {
            NSString *errorMessage = @"install card failed";
            installError = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_install_failed, installError, BDPParamStr(errorMessage, sourcePath, destinationPath));
            if (error) {
                *error = installError;
            }
            return NO;
        }
    }
    BDPLogTagInfo(BDPTag.packageManager, @"id(%@): Succeed to unzip package %@, destinationPath: %@", context.uniqueID.identifier, sourcePath, destinationPath);
    return YES;
}

/// 流式包，暂只做移动目录
+ (BOOL)moveWithContext:(BDPPackageContext *)context fromPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError **)error {
    destinationPath = [destinationPath stringByAppendingPathComponent:BDPLocalPackageFileName];
    if ([sourcePath isEqualToString:destinationPath]) {
        return YES;
    }
    NSError *moveError;
    BOOL moveSuccess = [[NSFileManager defaultManager] moveItemAtPath:sourcePath toPath:destinationPath error:&moveError];
    if (!moveSuccess) {
        NSString *errorMessage = @"move file error";
        moveError = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_install_failed, moveError, BDPParamStr(errorMessage, sourcePath, destinationPath));
        if (error) {
            *error = moveError;
        }
        return NO;
    }
    BDPLogTagInfo(BDPTag.packageManager, @"id(%@): Succeed to move package %@, destinationPath: %@", context.uniqueID.identifier, sourcePath, destinationPath);
    return YES;
}

@end
