//
//  BDPPackageUncompressedFileHandle.m
//  Timor
//
//  Created by houjihu on 2020/7/16.
//

#import "BDPPackageUncompressedFileHandle.h"
#import "BDPPackageLocalManager.h"
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import "BDPAppLoadDefineHeader.h"
#import <OPFoundation/NSError+BDPExtension.h>
#import <ECOInfra/OPError.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPCommonMonitorHelper.h>

@interface BDPPackageUncompressedFileHandle ()

/// 包管理上下文
@property (nonatomic, strong, readwrite) BDPPackageContext *packageContext;
/// 开始下载代码包时的下载状态
@property (nonatomic, assign) BDPPkgFileLoadStatus createLoadStatus;

@end

@implementation BDPPackageUncompressedFileHandle

- (instancetype)initWithPackageContext:(BDPPackageContext *)packageContext {
    return [self initWithPackageContext:packageContext createLoadStatus:BDPPkgFileLoadStatusUnknown];
}

- (instancetype)initWithPackageContext:(BDPPackageContext *)packageContext createLoadStatus:(BDPPkgFileLoadStatus)createLoadStatus {
    if (self = [super init]) {
        self.packageContext = packageContext;
        self.createLoadStatus = createLoadStatus;
    }
    return self;
}

#pragma mark - BDPPkgFileSyncReadHandleProtocol

/** 同步加载Data */
- (nullable NSData *)readDataWithFilePath:(NSString *)filePath error:(NSError * *)error {
    if (BDPIsEmptyString(filePath)) {
        NSError *fileError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"readDataWithFilePath with empty filePath");
        if (error) {
            *error = fileError;
        }
        return nil;
    }
    NSString *fullPath = [self fullPathInPkgDirForPath:filePath];
    NSData *data = [[LSFileSystem main] contentsWithFilePath:fullPath];
    return data;
}

/** 同步批量加载Data，如果包未下载完成会直接返回空 */
- (NSArray<NSData *> *)readDatasWithFilePaths:(NSArray<NSString *> *)filePaths error:(NSError **)error {
    if (BDPIsEmptyArray(filePaths)) {
        NSError *fileError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"readDatasWithFilePaths with empty filePaths");
        if (error) {
            *error = fileError;
        }
        return nil;
    }
    NSMutableArray *datas = NSMutableArray.array;
    for (NSString *filePath in filePaths) {
        NSData *data = [self readDataWithFilePath:filePath error:error];
        if (data) {
            [datas addObject:data];
        }
    }
    return datas;
}

/** 同步获取辅助文件的URL. 针对非流式包，不需要从包文件写入到辅助文件，这里直接返回路径即可 */
- (nullable NSURL *)urlOfDataWithFilePath:(NSString *)filePath error:(NSError * *)error {
    if (BDPIsEmptyString(filePath)) {
        NSError *fileError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"urlOfDataWithFilePath with empty filePath");
        if (error) {
            *error = fileError;
        }
        return nil;
    }
    NSString *fullPath = [self fullPathInPkgDirForPath:filePath];
    return [NSURL fileURLWithPath:fullPath];
}

/** 文件是否存在包内 */
- (BOOL)fileExistsInPkgAtPath:(NSString *)filePath {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return NO;
    }
    NSString *fullPath = [self fullPathInPkgDirForPath:filePath];
    return [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
}

/** 获取文件大小, 若不存在则会返回负数 */
- (int64_t)fileSizeInPkgAtPath:(NSString *)filePath {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return 0;
    }
    NSString *fullPath = [self fullPathInPkgDirForPath:filePath];
    return [BDPFileSystemHelper sizeWithPath:fullPath];
}

/** 获取目录下的所有文件名 */
- (nullable NSArray<NSString *> *)contentsOfPkgDirAtPath:(NSString *)dirPath {
    if (BDPIsEmptyString(dirPath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return nil;
    }
    NSString *fullPath = [self fullPathInPkgDirForPath:dirPath];
    NSError *error;
    NSArray<NSString *> *fileArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:&error];
    if (error) {
        error = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_install_invalid_params, error, @"fullPath:(%@)", fullPath);
    }
    return fileArray;
}

#pragma mark - BDPPkgCommonAsyncReadDataHandleProtocol

/** 异步加载Data */
- (void)asyncReadDataWithFilePath:(NSString *)filePath
                    dispatchQueue:(nullable dispatch_queue_t)dispatchQueue
                       completion:(BDPPkgFileReadDataBlock)completion {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath (%@) with empty completion", filePath);
        return;
    }
    dispatch_queue_t queue = dispatchQueue ?: dispatch_get_main_queue();
    dispatch_async(queue, ^{
        NSError *error;
        NSData *data = [self readDataWithFilePath:filePath error:&error];
        completion(error, self.packageContext.packageName, data);
    });
}

/// 异步加载Data，文件存到app包辅助文件目录
- (void)asyncReadDataURLWithFilePath:(NSString *)filePath
                       dispatchQueue:(nullable dispatch_queue_t)dispatchQueue
                          completion:(BDPPkgFileReadURLBlock)completion {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath (%@) with empty completion", filePath);
        return;
    }
    dispatch_queue_t queue = dispatchQueue ?: dispatch_get_main_queue();
    dispatch_async(queue, ^{
        NSError *error;
        NSURL *fileURL = [self urlOfDataWithFilePath:filePath error:&error];
        completion(error, self.packageContext.packageName, fileURL);
    });
}

#pragma mark - BDPPkgFileAsyncReadHandleProtocol
/// 此协议为保持与流式包一致的对外接口，尚还没有实际使用到

- (BDPPkgFileLoadStatus)loadStatus {
    return BDPPkgFileLoadStatusDownloaded;
}

- (BDPPkgFileLoadStatus)createLoadStatus {
    return self.createLoadStatus;
}

/// 取消所有加载文件(包括音频文件)的完成回调blk
- (void)cancelAllReadDataCompletionBlks {
    /// 非流式包，有fileHandle时代码包已经下载完成了，此方法不需要实现
}

/** 文件是否存在包内 */
- (void)checkExistedFileInPkg:(NSString *)filePath withCompletion:(void (^)(BOOL existed))completion {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath (%@) with empty completion", filePath);
        return;
    }
    BOOL exsits = [self fileExistsInPkgAtPath:filePath];
    completion(exsits);
}

/** 获取文件大小, 若不存在则会返回负数 */
- (void)getFileSizeInPkg:(NSString *)filePath withCompletion:(void (^)(int64_t size))completion {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath (%@) with empty completion", filePath);
        return;
    }
    int64_t size = [self fileSizeInPkgAtPath:filePath];
    completion(size);
}

/** 获取目录下的所有文件名 */
- (void)getContentsOfDirAtPath:(NSString *)dirPath withCompletion:(void (^)(NSArray<NSString *> *_Nullable filenames))completion {
    if (BDPIsEmptyString(dirPath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty dirPath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"dirPath (%@) with empty completion", dirPath);
        return;
    }
    NSArray<NSString *> *contents = [self contentsOfPkgDirAtPath:dirPath];
    completion(contents);
}

/// 读取数据内容
- (void)readDataInOrder:(BOOL)inOrder
           withFilePath:(NSString *)filePath
          dispatchQueue:(dispatch_queue_t)dispatchQueue
             completion:(BDPPkgFileReadDataBlock)completion {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath (%@) with empty completion", filePath);
        return;
    }
    dispatch_block_t executeBlock = ^{
        NSError *error;
        NSData *data = [self readDataWithFilePath:filePath error:&error];
        completion(error, self.packageContext.packageName, data);
    };
    if (dispatchQueue) {
        dispatch_async(dispatchQueue, executeBlock);
    } else {
        executeBlock();
    }
}

/// 读取音频资源URL
- (void)readDataURLInOrder:(BOOL)inOrder
              withFilePath:(NSString *)filePath
             dispatchQueue:(dispatch_queue_t)dispatchQueue
                completion:(BDPPkgFileReadURLBlock)completion {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath (%@) with empty completion", filePath);
        return;
    }
    dispatch_block_t executeBlock = ^{
        NSError *error;
        NSURL *fileURL = [self urlOfDataWithFilePath:filePath error:&error];
        completion(error, self.packageContext.packageName, fileURL);
    };
    if (dispatchQueue) {
        dispatch_async(dispatchQueue, executeBlock);
    } else {
        executeBlock();
    }
}

/// 异步读取文件内容
- (void)readDataWithFilePath:(NSString *)filePath
            syncIfDownloaded:(BOOL)syncIfDownloaded
               dispatchQueue:(dispatch_queue_t)dispatchQueue
                  completion:(BDPPkgFileReadDataBlock)completion {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"empty filePath");
        return;
    }
    if (!completion) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath (%@) with empty completion", filePath);
        return;
    }
    dispatch_block_t executeBlock = ^{
        NSError *error;
        NSData *data = [self readDataWithFilePath:filePath error:&error];
        completion(error, self.packageContext.packageName, data);
    };
    if (dispatchQueue && !syncIfDownloaded) {
        dispatch_async(dispatchQueue, executeBlock);
    } else {
        executeBlock();
    }
}

#pragma mark - Helper

/// 获取在代码包内的完整路径
- (NSString *)fullPathInPkgDirForPath:(NSString *)filePath {
    NSString *fullPath = [self.pkgDirPath stringByAppendingPathComponent:filePath];
    return fullPath;
}

/// 获取代码包路径
- (NSString *)pkgDirPath {
    BDPPackageContext *packageContext = self.packageContext;
    NSString *packagePath = [BDPPackageLocalManager localPackageDirectoryPathForContext:packageContext];
    return packagePath;
}

@end
