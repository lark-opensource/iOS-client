//
//  BDPPackageStreamingFileHandle+SyncRead.m
//  Timor
//
//  Created by houjihu on 2020/7/16.
//

#import "BDPPackageStreamingFileHandle+SyncRead.h"
#import "BDPPackageStreamingFileHandle+AsyncRead.h"
#import "BDPPackageStreamingFileHandle+WriteHandle.h"
#import "BDPPackageStreamingFileHandle+FileManagerHandle.h"
#import "BDPPackageStreamingFileHandle+Private.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/NSError+BDPExtension.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <ECOInfra/OPError.h>

@implementation BDPPackageStreamingFileHandle (SyncRead)

#pragma mark - BDPPkgFileSyncReadHandleProtocol

/** 同步加载Data */
- (nullable NSData *)readDataWithFilePath:(NSString *)filePath error:(NSError * *)error {
    __block NSError *bError = nil;
    __block NSData *bData = nil;
    // self.loadStatus不要上锁直接访问, 还有else同步兜底
    BOOL didDownload = self.loadStatus == BDPPkgFileLoadStatusDownloaded;
    if (didDownload) {
        NSRange range = {0, 0};
        BDPPkgFileIndexInfo *indexModel = [self indexInfoForFilePath:filePath];
        if (indexModel) {
            range = NSMakeRange(indexModel.offset, indexModel.size);
        } else {
            bError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_file_not_found, @"%@(%@): File Not Found(%@)", self.packageContext.uniqueID.identifier, self.packageContext.packageName, filePath);
        }
        if (!bError) {
            bData = [self getDataOfIndexModel:indexModel error:&bError];
        }
        [self recordRequestOfFile:filePath];
    } else {
        dispatch_semaphore_t syncLock = dispatch_semaphore_create(0);
        [self readDataInOrder:NO
                 withFilePath:filePath
                dispatchQueue:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
                   completion:^(NSError * _Nullable error, NSString * _Nonnull pkgName, NSData * _Nullable data) {
                       bError = error;
                       bData = data;
                       dispatch_semaphore_signal(syncLock);
                   }];
        // 一行代码, 不影响打断点, 同步锁 同时确保Set的lazyLoading的安全执行
        LOCK(self.syncApiLock, [self.syncApiSemaphores addObject:syncLock];);
        if (dispatch_semaphore_wait(syncLock, LOAD_TIMEOUT)) {
            bError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_read_timeout, @"%@(%@): read file timeout! (%@)", self.packageContext.uniqueID.identifier, self.packageContext.packageName, filePath);
        }
        LOCK(self.syncApiLock, [self.syncApiSemaphores removeObject:syncLock];);
    }
    if (error && bError) {
        *error = bError;
    }
    if (bError) {
        BDPLogError(@"readDataWithFilePath failed. %@ %@", filePath, bError.description);
    }
    return bData;
}

/** 同步批量加载Data，如果包未下载完成会直接返回nil */
- (NSArray<NSData *> *)readDatasWithFilePaths:(NSArray<NSString *> *)filePaths error:(NSError **)error {
    __block NSError *bError = nil;
    // self.loadStatus不要上锁直接访问, 还有else同步兜底
    BOOL didDownload = self.loadStatus == BDPPkgFileLoadStatusDownloaded;
    if (didDownload) {
        NSMutableArray* modles = NSMutableArray.array;
        for (NSString * filePath in filePaths) {
            NSRange range = {0, 0};
            BDPPkgFileIndexInfo *indexModel = [self indexInfoForFilePath:filePath];
            if (indexModel) {
                range = NSMakeRange(indexModel.offset, indexModel.size);
                [modles addObject:indexModel];
            } else {
                bError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_file_not_found, @"%@(%@): File Not Found(%@)", self.packageContext.uniqueID.identifier, self.packageContext.packageName, filePath);
                break;
            }
        }
        if (!bError && !BDPIsEmptyArray(modles)) {
            NSArray *bDatas = [self getDatasOfIndexModels:modles error:&bError];
            if (!bError && !BDPIsEmptyArray(bDatas)) {
                return bDatas;
            }
        } else {
            BDPLogError(@"readDataWithFilePath failed. %@ %@", filePaths, bError.description);
        }
    } else {
        // 没有下完就不支持批量读取了
        return nil;
    }
    if (error && bError) {
        *error = bError;
    }
    return nil;
}

/** 同步获取辅助文件的URL */
- (nullable NSURL *)urlOfDataWithFilePath:(NSString *)filePath error:(NSError * *)error {
    __block NSError *bError = nil;
    __block NSURL *bURL = nil;
    BOOL didDownload = self.loadStatus == BDPPkgFileLoadStatusDownloaded;
    if (didDownload) {
        // 查找文件索引信息
        NSRange range = {0, 0};
        BDPPkgFileIndexInfo *indexModel = [self indexInfoForFilePath:filePath];
        if (indexModel) {
            range = NSMakeRange(indexModel.offset, indexModel.size);
        } else {
            bError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_file_not_found, @"%@(%@): File Not Found(%@)", self.packageContext.uniqueID.identifier, self.packageContext.packageName, filePath);
        }
        // 根据文件索引信息，读取文件数据
        if (!bError) {
            NSString *urlPath = [self auxiliaryPathFrom:indexModel.filePath appType:self.packageContext.uniqueID.appType];
            if (![self syncCheckFileExists:urlPath]) {
                NSData *data = [self getDataOfIndexModel:indexModel error:&bError];
                // 将读取的文件信息，写入辅助目录，以对外提供URL形式的路径
                if (data && !bError) {
                    __block NSURL *blkURL = nil;
                    dispatch_sync(self.serialQueue, ^{
                        blkURL = [self writeAuxiliaryFileWithData:data      uniqueID:self.packageContext.uniqueID pkgName:self.packageContext.packageName appType:self.packageContext.uniqueID.appType filePath:indexModel.filePath];
                    });
                    bURL = blkURL;
                }
            } else {
                bURL = [NSURL fileURLWithPath:urlPath];
            }
        }
        [self recordRequestOfFile:filePath];
    } else {
        dispatch_semaphore_t syncLock = dispatch_semaphore_create(0);
        [self readDataURLInOrder:NO
                    withFilePath:filePath
                   dispatchQueue:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
                      completion:^(NSError * _Nullable error, NSString * _Nonnull pkgName, NSURL * _Nullable fileURL)
         {
             bError = error;
             bURL = fileURL;
             dispatch_semaphore_signal(syncLock);
         }];
        LOCK(self.syncApiLock, [self.syncApiSemaphores addObject:syncLock];);
        if (dispatch_semaphore_wait(syncLock, LOAD_TIMEOUT)) {
            bError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_read_timeout, @"%@(%@): read file timeout! (%@)", self.packageContext.uniqueID.identifier, self.packageContext.packageName, filePath);
        }
        LOCK(self.syncApiLock, [self.syncApiSemaphores removeObject:syncLock];);
    }
    if (error && bError) {
        *error = bError;
    }
    if (bError) {
        BDPLogError(@"urlOfDataWithFilePath failed. %@ %@", filePath, bError.description);
    }
    return bURL;
}

/** 文件是否存在包内 */
- (BOOL)fileExistsInPkgAtPath:(NSString *)filePath {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath is empty");
        return NO;
    }
    BDPPkgHeaderInfo *fileInfo = self.fileInfo; // 强持有, 防止异步线程忽然释放了self.fileInfo, 比如md5校验未过
    if (fileInfo) {
        return [self __fileExistsInPkgAtPath:filePath withFileInfo:fileInfo];
    } else {
        __block BOOL bExists = NO;
        dispatch_semaphore_t syncLock = dispatch_semaphore_create(0);
        LOCK(self.syncApiLock, [self.syncApiSemaphores addObject:syncLock];);
        [self checkExistedFileInPkg:filePath withCompletion:^(BOOL existed) {
            bExists = existed;
            dispatch_semaphore_signal(syncLock);
        }];
        dispatch_semaphore_wait(syncLock, LOAD_TIMEOUT);
        LOCK(self.syncApiLock, [self.syncApiSemaphores removeObject:syncLock];);
        return bExists;
    }
}

/** 获取文件大小, 若不存在则会返回负数 */
- (int64_t)fileSizeInPkgAtPath:(NSString *)filePath {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath is empty");
        return 0;
    }
    BDPPkgHeaderInfo *fileInfo = self.fileInfo;
    if (fileInfo) {
        return fileInfo.fileIndexesDic[filePath].size;
    } else {
        __block int64_t bSize = NO;
        dispatch_semaphore_t syncLock = dispatch_semaphore_create(0);
        LOCK(self.syncApiLock, [self.syncApiSemaphores addObject:syncLock];);
        [self getFileSizeInPkg:filePath withCompletion:^(int64_t size) {
            bSize = size;
            dispatch_semaphore_signal(syncLock);
        }];
        dispatch_semaphore_wait(syncLock, LOAD_TIMEOUT);
        LOCK(self.syncApiLock, [self.syncApiSemaphores removeObject:syncLock];);
        return bSize;
    }
}

/** 获取目录下的所有文件名 */
- (nullable NSArray<NSString *> *)contentsOfPkgDirAtPath:(NSString *)dirPath {
    if (BDPIsEmptyString(dirPath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"dirPath is empty");
        return nil;
    }
    BDPPkgHeaderInfo *fileInfo = self.fileInfo;
    if (fileInfo) {
        NSMutableArray *filenames = nil;
        for (BDPPkgFileIndexInfo *index in fileInfo.fileIndexes) {
            if ([index.filePath hasPrefix:dirPath]) {
                if (!filenames) {
                    filenames = [NSMutableArray array];
                }
                [filenames addObject:index.filePath];
            }
        }
        return [filenames copy];
    } else {
        __block NSArray *bContents = nil;
        dispatch_semaphore_t syncLock = dispatch_semaphore_create(0);
        LOCK(self.syncApiLock, [self.syncApiSemaphores addObject:syncLock];);
        [self getContentsOfDirAtPath:dirPath
                      withCompletion:^(NSArray<NSString *> * _Nullable filenames) {
                          bContents = filenames;
                          dispatch_semaphore_signal(syncLock);
                      }];
        dispatch_semaphore_wait(syncLock, LOAD_TIMEOUT);
        LOCK(self.syncApiLock, [self.syncApiSemaphores removeObject:syncLock];);
        return bContents;
    }
}

#pragma mark - Helper

- (BOOL)__fileExistsInPkgAtPath:(NSString *)filePath withFileInfo:(BDPPkgHeaderInfo *)fileInfo {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath is empty");
        return NO;
    }
    return fileInfo.fileIndexesDic[filePath] != nil || ^{
        for (BDPPkgFileIndexInfo *index in fileInfo.fileIndexes) {
            if ([index.filePath hasPrefix:filePath]) {
                return YES;
            }
        }
        return NO;
    }();
}

- (BOOL)syncCheckFileExists:(NSString *)filePath {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath is empty");
        return NO;
    }
    __block BOOL bExists = NO;
    dispatch_sync(BDPPackageStreamingFileHandleSerialQueue, ^{
        bExists = [LSFileSystem fileExistsWithFilePath:filePath isDirectory:nil];
    });
    return bExists;
}

- (BDPPkgFileIndexInfo *)indexInfoForFilePath:(NSString *)filePath {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath is empty");
        return nil;
    }
    BDPPkgFileIndexInfo *info = self.fileInfo.fileIndexesDic[filePath];
    if (!info) { // 兜底, 万一开发者不使用规范路径
        NSString *correctedPath = nil;
        if ([filePath hasPrefix:@"./"]) {
            correctedPath = [filePath substringFromIndex:2];
        } else if ([filePath hasPrefix:@"/"]) {
            correctedPath = [filePath substringFromIndex:1];
        }
        if (correctedPath) {
            info = self.fileInfo.fileIndexesDic[correctedPath];
        }
    }
    return info;
}

- (void)recordRequestOfFile:(NSString *)filePath {
    if (BDPIsEmptyString(filePath)) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"filePath is empty");
        return;
    }
    WeakSelf;
    [self executeSync:NO inSelfQueueOfBlk:^{
        StrongSelfIfNilReturn;
        if (![self.loadedFileNames containsObject:filePath]) {
            if (self.fileInfo && ![self indexInfoForFilePath:filePath]) {
                return; // 如果文件描述信息已解析出来, 则检测是否包含在目录中
            }
            [self.loadedFileNames addObject:filePath];
            [self.fileRecords addObject:@{
                                          @"index": @(self.index++),
                                          @"name": filePath
                                          }];
            if (self.fileRecords.count >= MAX_FILE_RECORD_COUNT) {
                NSArray<NSDictionary *> *records = [self.fileRecords copy];
                [self.fileRecords removeAllObjects];
                NSString *filesJsonStr = [records JSONRepresentation];
                BDPLogInfo(@"mp_stream_load_files_index with uniqueID(%@), packageName(%@), files:(%@)", self.packageContext.uniqueID, self.packageContext.packageName, filesJsonStr);
            }
        }
    }];
}

/// 将辅助数据（mp3音频等数据）保存到存放pkg包的目录。
/// app包辅助文件目录路径: xxx/tma/app/tt00a0000bc0000def/name/__auxiliary__
- (NSURL *)writeAuxiliaryFileWithData:(NSData *)data
                 uniqueID:(BDPUniqueID *)uniqueID
                              pkgName:(NSString *)pkgName
                              appType:(BDPType)appType
                             filePath:(NSString *)filePath {
    if (!data.length) {
        OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, @"data is empty");
        return nil;
    }
    NSString *auxiliaryPath = [self auxiliaryPathFrom:filePath appType:appType];
    BOOL success = YES;
    if (![LSFileSystem fileExistsWithFilePath:auxiliaryPath isDirectory:nil]) {
        NSError *error = nil;
        NSString *auxiliaryDirPath = [[BDPGetResolvedModule(BDPStorageModuleProtocol, appType) sharedLocalFileManager] appPkgAuxiliaryDirWithUniqueID:uniqueID name:pkgName];
        if (![LSFileSystem fileExistsWithFilePath:auxiliaryDirPath isDirectory:nil]) {
            [[LSFileSystem main] createDirectoryAtPath:auxiliaryDirPath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!error) {
            NSError *error = nil;
            if ([OPSDKFeatureGating enableUnifiedStorage]) {
                [[LSFileSystem main] writeWithData:data to:auxiliaryPath error:&error];
                success = (error == nil);
            } else {
                success = [data writeToFile:auxiliaryPath atomically:YES];
            }
            if (!success) {
                NSString *errorMessage = [NSString stringWithFormat:@"%@(%@): pkg write auxiliary file failed", uniqueID, pkgName];
                OPErrorWithMsg(CommonMonitorCodePackage.pkg_write_file_failed, errorMessage);
            }
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"%@(%@): pkg write auxiliary file failed: %@", uniqueID, pkgName, error];
            OPErrorWithMsg(CommonMonitorCodePackage.pkg_create_file_failed, errorMessage);
        }
    }
    return success ? [NSURL fileURLWithPath:auxiliaryPath] : nil;
}

- (NSString *)auxiliaryPathFrom:(NSString *)path appType:(BDPType)appType {
    path = [path stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    // TODO: yinyuan 这里用了 identifier 来当做 appID 使用，需要确认
    return [[BDPGetResolvedModule(BDPStorageModuleProtocol, appType) sharedLocalFileManager] appPkgAuxiliaryPathWithUniqueID:self.packageContext.uniqueID pkgName:self.packageContext.packageName fileName:path];
}

- (NSData *)getDataOfIndexModel:(BDPPkgFileIndexInfo *)model error:(NSError **)error {
    return [self getDataWithFilePath:model.filePath offset:model.offset size:model.size error:error];
}

- (NSData *)getDataWithFilePath:(NSString *)filePath
                         offset:(uint64_t)offset
                           size:(uint64_t)size
                          error:(NSError **)error {
    NSData *data = nil;
    NSError *innerError = nil;
    BOOL isSerialQueue = dispatch_get_specific((__bridge void *)self) != NULL;
    BDPLogTagInfo(BDPTag.packageManager, @"getDataWithFilePath fileHandle with isSerialQueue: %@", @(isSerialQueue));
    NSFileHandle *handle = [[LSFileSystem main] fileReadingHandleWithFilePath:self.pkgPath error:nil];
    if (handle) {
        [handle seekToFileOffset:offset];
        @try {
            data = [handle readDataOfLength:(NSUInteger)size];
        } @catch (NSException *exception) {
            innerError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_read_data_failed, @"%@(%@-%@): %@", self.pkgPath.lastPathComponent, @(offset), @(size), exception.reason);
        }
        [handle closeFile];
    } else {
        if ([LSFileSystem fileExistsWithFilePath:self.pkgPath isDirectory:nil]) {
            innerError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_read_data_failed, @"%@: create fileHandle failed", self.pkgPath.lastPathComponent);
        } else {
            innerError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_not_found, @"%@: file not exits", self.pkgPath);
        }
    }

    if (!innerError) {
        NSAssert(data.length == size, @"读取数据失败!");
        if (data.length != size) {
            innerError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_file_not_found, @"%@(%@): Reader Get Content Data Failed(%@)", self.packageContext.uniqueID.identifier, self.packageContext.packageName, filePath);
        }
    }
    if (error && innerError) {
        *error = innerError;
    }

    return data;
}

- (NSArray<NSData *> *)getDatasOfIndexModels:(NSArray<BDPPkgFileIndexInfo *> *)models error:(NSError **)error {
    NSMutableArray *datas = NSMutableArray.array;
    NSError *innerError = nil;
    BOOL isSerialQueue = dispatch_get_specific((__bridge void *)self) != NULL;
    NSFileHandle *handle = [[LSFileSystem main] fileReadingHandleWithFilePath:self.pkgPath error:nil];
    BDPLogTagInfo(BDPTag.packageManager, @"getDatasOfIndexModels fileHandle with isSerialQueue(%@)", @(isSerialQueue));
    if (handle) {
        // 批量读取数据
        for (BDPPkgFileIndexInfo *modle in models) {
            NSData *data = nil;
            NSString *filePath = modle.filePath;
            uint64_t offset = modle.offset;
            uint64_t size = modle.size;
            [handle seekToFileOffset:offset];
            @try {
                data = [handle readDataOfLength:(NSUInteger)size];
                if (data) {
                    // 数据收集
                    [datas addObject:data];
                }
            } @catch (NSException *exception) {
                innerError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_read_data_failed, @"%@(%@-%@): %@", self.pkgPath.lastPathComponent, @(offset), @(size), exception.reason);
                break;
            }

            if (!innerError) {
                NSAssert(data.length == size, @"读取数据失败!");
                if (data.length != size) {
                    innerError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_file_not_found, @"%@(%@): Reader Get Content Data Failed(%@)", self.packageContext.uniqueID.identifier, self.packageContext.packageName, filePath);
                    break;
                }
            }
        }

        [handle closeFile];
    } else {
        if ([LSFileSystem fileExistsWithFilePath:self.pkgPath isDirectory:nil]) {
            innerError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_read_data_failed, @"%@: create fileHandle failed", self.pkgPath.lastPathComponent);
        } else {
            innerError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_not_found, @"%@: file not exits", self.pkgPath);
        }
    }

    if (error && innerError) {
        *error = innerError;
    }
    if (innerError) {
        return nil;
    }
    return datas;
}

@end
