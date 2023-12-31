
#import "TTDownloadSliceTaskConfig.h"
#import "TTDownloadManager.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TTDownloadSliceTaskConfig

- (id)init {
    self = [super init];
    if (self) {
        self.subSliceInfoArray = [[NSMutableArray alloc] init];
        self.sliceStatus       = INIT;
        self.retryTimes        = SLICE_MAX_RETRY_TIMES;
        self.retryTimesMax     = self.retryTimes;
    }
    return self;
}

- (void)dealloc {
    DLLOGD(@"dlLog:dealloc:file=%s ,function=%s", __FILE__, __FUNCTION__);
}

- (StatusCode)mergeSubSlice:(NSString *)sliceFullPath
                 fileHandle:(NSFileHandle *)fileHandle
            mergeDataLength:(int64_t)mergeDataLength
     isSkipGetContentLength:(BOOL)isSkipGetContentLength {
    if (!sliceFullPath || !fileHandle || mergeDataLength < 1024) {
        return ERROR_MERGE_PARAMETERS_ERROR;
    }
    
    if (isSkipGetContentLength) {
        TTDownloadSubSliceInfo *lastSubSlice = [self.subSliceInfoArray lastObject];
        if (lastSubSlice.sliceStatus != DOWNLOADED) {
            return ERROR_SKIP_GET_CONTENT_LEN_LAST_STATUS_ERROR;
        }
    }
    
    for (TTDownloadSubSliceInfo *subSlice in self.subSliceInfoArray) {
        DLLOGD(@"dlLog:++++++++++++++++++1++++++++++++++++++++++");

        NSString *subSlicePath = [sliceFullPath stringByAppendingPathComponent:subSlice.subSliceName];
        DLLOGD(@"dlLog:slicePath=%@", subSlicePath);
        NSFileHandle *subFileHandle = [NSFileHandle fileHandleForReadingAtPath:subSlicePath];
        
        NSUInteger offset = 0;
        NSInteger exactDivision = (subSlice.rangeEnd - subSlice.rangeStart) / mergeDataLength;
        @try {
            for (NSInteger i = 0; i < exactDivision; ++i) {
                @autoreleasepool {
                    [subFileHandle seekToFileOffset:offset];
                    NSData *sliceData = [subFileHandle readDataOfLength:mergeDataLength];
                    offset += mergeDataLength;
                    [fileHandle seekToEndOfFile];
                    [fileHandle writeData:sliceData];
                }
            }
            NSUInteger remainLength = (subSlice.rangeEnd - subSlice.rangeStart) - exactDivision * mergeDataLength;
            if (remainLength > 0) {
                @autoreleasepool {
                    [subFileHandle seekToFileOffset:offset];
                    NSData *sliceData = [subFileHandle readDataOfLength:remainLength];
                    [fileHandle seekToEndOfFile];
                    [fileHandle writeData:sliceData];
                }
            }
        } @catch (NSException *exception) {
            DLLOGE(@"error reason:%@", exception.reason);
            [subFileHandle closeFile];
            return ERROR_WRITE_DISK_FAILED;
        }
        [subFileHandle closeFile];

        DLLOGD(@"dlLog:++++++++++++++++++2++++++++++++++++++++++");
    }
    return ERROR_MERGE_SUCCESS;
}

- (BOOL)updateSliceConfig:(TTDownloadTask *)task isBackgroundTask:(BOOL)isBackgroundTask {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([self.subSliceInfoArray count] > 0) {
        
        TTDownloadSubSliceInfo *subSlice = [self.subSliceInfoArray lastObject];
        
        if (task.isSkipGetContentLength && DOWNLOADED == subSlice.sliceStatus) {
            self.sliceStatus = DOWNLOADED;
            [task sliceCountHasDownloadedIncrease];
            [task backgroundDownloadedCounterIncrease];
            self.hasDownloadedLength = [[TTDownloadManager class] getHadDownloadedLength:self isReadLastSubSlice:YES];
            DLLOGD(@"debug hasDownloadedLength 22 = %lld", self.hasDownloadedLength);
            if (!subSlice.isImmutable) {
                subSlice.rangeEnd = self.hasDownloadedLength;
            }
            return YES;
        }

        subSlice.subSliceFullPath = [task.downloadTaskSliceFullPath stringByAppendingPathComponent:subSlice.subSliceName];
        if (!task.isServerSupportAcceptRange) {
            if ([fileManager fileExistsAtPath:subSlice.subSliceFullPath]) {
                if ([[TTDownloadManager shareInstance] deleteFile:subSlice.subSliceFullPath]) {
                    self.hasDownloadedLength = 0;
                    DLLOGD(@"dlLog:debug hasDownloadedLength 66 = %lld", self.hasDownloadedLength);
                    if ([task isRangeDownloadEnable]) {
                        subSlice.rangeStart = [task getStartOffset];
                    } else {
                        subSlice.rangeStart = 0;
                    }
                    
                    if (!subSlice.isImmutable) {
                        subSlice.rangeEnd = 0;
                    }
                } else {
                    self.sliceStatus = FAILED;
                    DLLOGD(@"dlLog:delete failed");
                    return NO;
                }
            } else {
                if (!subSlice.isImmutable) {
                    subSlice.rangeEnd = -1;
                }
            }
        } else {
            if ([fileManager fileExistsAtPath:subSlice.subSliceFullPath]) {
                NSError *error;
                NSDictionary *fileAttributeDic = [fileManager attributesOfItemAtPath:subSlice.subSliceFullPath error:&error];
                if (error) {
                    return NO;
                } else if (fileAttributeDic.fileSize > 0) {
                    DLLOGD(@"sliceNo=%d,subSliceNo=%lu,fileAttributeDic.fileSize=%lld", self.sliceNumber, (unsigned long)subSlice.subSliceNumber, fileAttributeDic.fileSize);
                    if (![self updateSubSliceRange:task subSlice:subSlice fileRealSize:fileAttributeDic.fileSize]) {
                        DLLOGD(@"dlLog:updateSubSliceRange failed");
                        return NO;
                    }
                } else {
                    DLLOGD(@"size_0:sliceNo=%d,subSliceNo=%lu,fileAttributeDic.fileSize=%lld", self.sliceNumber, (unsigned long)subSlice.subSliceNumber, fileAttributeDic.fileSize);
                    if (![[TTDownloadManager shareInstance] deleteFile:subSlice.subSliceFullPath]) {
                        DLLOGD(@"dlLog:delete merge file error");
                        return NO;
                    }
                    if (!subSlice.isImmutable) {
                        subSlice.rangeEnd = -1;
                    }
                }
            } else {
                DLLOGD(@"subSlice.subSliceFullPath not exist,range=-1,sliceNo=%d,subSliceNo=%lu subSlice.subSliceFullPath=%@", self.sliceNumber, (unsigned long)subSlice.subSliceNumber, subSlice.subSliceFullPath);
                if (!subSlice.isImmutable) {
                    subSlice.rangeEnd = -1;
                }
            }
        }
        self.hasDownloadedLength = [[TTDownloadManager class] getHadDownloadedLength:self isReadLastSubSlice:YES];
        DLLOGD(@"dlLog:debug hasDownloadedLength 222 = %lld", self.hasDownloadedLength);
    } else {
        return NO;
    }
    
    if (![self updateSliceStatus:task isBackgroundTask:isBackgroundTask]) {
        DLLOGD(@"dlLog:updateSliceStatus failed");
        return NO;
    }
    
    [self updateRange:task];
    return YES;
}



- (BOOL)updateSliceStatus:(TTDownloadTask *)task
         isBackgroundTask:(BOOL)isBackgroundTask {
    DLLOGD(@"fillSliceInfoByRealFileSize:slice.hasDownloadedLength=%lld,slice.sliceTotalLength=%lld", self.hasDownloadedLength, self.sliceTotalLength);
    if (task.isSkipGetContentLength) {
        if (isBackgroundTask) {
            self.sliceStatus = BACKGROUND;
        } else {
            self.sliceStatus = INIT;
            task.realSliceCount++;
        }
        return YES;
    }
    
    if (self.hasDownloadedLength == self.sliceTotalLength) {
        self.sliceStatus = DOWNLOADED;
        [task sliceCountHasDownloadedIncrease];
        [task backgroundDownloadedCounterIncrease];
    } else if (self.hasDownloadedLength > self.sliceTotalLength) {
        DLLOGD(@"dlLog:failed:slice number=%d,hasdownloadLength=%lld,sliceTotalLength=%lld", self.sliceNumber, self.hasDownloadedLength, self.sliceTotalLength);
        /**
         *Delete task if slice size error.
         */
        [[TTDownloadManager shareInstance] deleteDownloadFile:task.taskConfig isDeleteDB:YES isDeleteMergeFile:YES isDeleteSliceFile:YES];
        [task updateDownloadTaskStatus:DELETED];
        return NO;
    } else {
        if (isBackgroundTask) {
            self.sliceStatus = BACKGROUND;
        } else {
            self.sliceStatus = INIT;
            task.realSliceCount++;
        }
    }
    return YES;
}

- (void)updateRange:(TTDownloadTask *)task {
    int64_t baseLength = task.firstSliceNeedDownloadLength * (self.sliceNumber - 1);

    self.startByte = baseLength + self.hasDownloadedLength;
    self.endByte   = baseLength + self.sliceTotalLength;
    if ([task isRangeDownloadEnable]) {
        self.startByte = [task getStartOffset] + self.startByte;
        self.endByte   = [task getStartOffset] + self.endByte;
    }
    
    task.needDownloadLengthTotal += (self.sliceTotalLength - self.hasDownloadedLength);
    task.contentTotalLength      += self.sliceTotalLength;
    DLLOGD(@"updateRange:sliceNumber=%d,hasdownlaodLength=%lld,needDownloadLengthTotal=%lld,status=%ld,startByte=%lld,endByte=%lld", self.sliceNumber, self.hasDownloadedLength, task.needDownloadLengthTotal, (long)self.sliceStatus, self.startByte, self.endByte);
}

- (BOOL)updateSubSliceRange:(TTDownloadTask *)task subSlice:(TTDownloadSubSliceInfo *)subSlice fileRealSize:(int64_t)fileRealSize {
    if (!subSlice.isImmutable) {
        subSlice.rangeEnd = subSlice.rangeStart + fileRealSize;
    }

    int64_t sliceRangeEnd = (task.firstSliceNeedDownloadLength * (self.sliceNumber - 1)) + self.sliceTotalLength;
    if ([task isRangeDownloadEnable]) {
        sliceRangeEnd = [task getStartOffset] + sliceRangeEnd;
    }

    /**
     *If task is uncomplete, will create sub slice.
     */
    DLLOGD(@"fillSliceInfoByRealFileSize:subSlice.rangeEnd=%lld,sliceRangeEnd=%lld", subSlice.rangeEnd, sliceRangeEnd);
    if ((task.isSkipGetContentLength && subSlice.sliceStatus != DOWNLOADED) || subSlice.rangeEnd < sliceRangeEnd) {
        if (![self createSubSlice:task preSubSlice:subSlice]) {
            return NO;
        }
    } else if (!task.isSkipGetContentLength && subSlice.rangeEnd > sliceRangeEnd) {
        DLLOGE(@"@fillSliceInfoByRealFileSize:ERROR!!subSlice.rangeEnd > sliceRangeEnd,subSlice.rangeEnd=%lld,sliceRangeEnd=%lld", subSlice.rangeEnd, sliceRangeEnd);
        if (![[TTDownloadManager shareInstance] deleteFile:subSlice.subSliceFullPath]) {
            return NO;
        }
        if (!subSlice.isImmutable) {
            subSlice.rangeEnd = -1;
        }
    }
    return YES;
}

- (BOOL)createSubSlice:(TTDownloadTask *)task  preSubSlice:(TTDownloadSubSliceInfo *)subSlice {
    TTDownloadSubSliceInfo *newSubSlice = [[TTDownloadSubSliceInfo alloc] init];
    newSubSlice.sliceNumber = self.sliceNumber;
    newSubSlice.fileStorageDir = task.taskConfig.fileStorageDir;
    newSubSlice.subSliceNumber = [self.subSliceInfoArray count];
    
    newSubSlice.subSliceName = [NSString stringWithFormat:@"%d-%lu", newSubSlice.sliceNumber, (unsigned long)newSubSlice.subSliceNumber];
    newSubSlice.subSliceFullPath = [task.downloadTaskSliceFullPath stringByAppendingPathComponent:newSubSlice.subSliceName];
    newSubSlice.rangeStart = subSlice.rangeEnd;
    //We need update rangeEnd by real file size.
    newSubSlice.rangeEnd = -1;
    
    subSlice.isImmutable = YES;
    [self.subSliceInfoArray addObject:newSubSlice];
    //Add the new sub slice information to DB.
    DLLOGD(@"old last subSlice:sliceNum=%d,subNum=%lu,subName=%@,startRange=%lld,endRange=%lld", subSlice.sliceNumber, (unsigned long)subSlice.subSliceNumber, subSlice.subSliceName, subSlice.rangeStart, subSlice.rangeEnd);

    NSError *error = nil;
    if (![[TTDownloadManager shareInstance] insertOrUpdateSubSliceInfo:subSlice error:&error]) {
        [task.dllog addDownloadLog:@"insertOrUpdateSubSliceInfo:subSlice" error:error];
        return NO;
    }
    DLLOGD(@"newest last subSlice:sliceNum=%d,subNum=%lu,subName=%@,startRange=%lld,endRange=%lld", newSubSlice.sliceNumber, (unsigned long)newSubSlice.subSliceNumber, newSubSlice.subSliceName, newSubSlice.rangeStart, newSubSlice.rangeEnd);

    error = nil;
    if (![[TTDownloadManager shareInstance] insertOrUpdateSubSliceInfo:newSubSlice error:&error]) {
        [task.dllog addDownloadLog:@"insertOrUpdateSubSliceInfo:newSubSlice" error:error];
        return NO;
    }
    return YES;
}

- (BOOL)checkLastSubSlice:(TTDownloadTask *)task {
    TTDownloadSubSliceInfo *subSlice = [self.subSliceInfoArray lastObject];
    if (!subSlice) {
        return NO;
    }
    NSString *subSliceFullPath = [task.downloadTaskSliceFullPath stringByAppendingPathComponent:subSlice.subSliceName];
    BOOL isDir = YES;
    if ([[NSFileManager defaultManager] fileExistsAtPath:subSliceFullPath isDirectory:&isDir] && !isDir) {
        NSError *error = nil;
        NSDictionary *fileAttributeDic = [[NSFileManager defaultManager] attributesOfItemAtPath:subSliceFullPath error:&error];
        if (error) {
            DLLOGD(@"fileAttributeDic get failed");
            return NO;
        }

        int64_t sliceRangeEnd = (task.firstSliceNeedDownloadLength * (self.sliceNumber - 1)) + self.sliceTotalLength;
        if ([task isRangeDownloadEnable]) {
            sliceRangeEnd = [task getStartOffset] + sliceRangeEnd;
        }

        DLLOGD(@"checkLastSubSlice:sliceRangeEnd=%lld,subSlice.rangeStart + fileAttributeDic.fileSize=%lld,subSlice.rangeEnd=%lld", sliceRangeEnd, subSlice.rangeStart + fileAttributeDic.fileSize, subSlice.rangeEnd);
        
        if (((subSlice.rangeStart + fileAttributeDic.fileSize) != subSlice.rangeEnd) || subSlice.rangeEnd != sliceRangeEnd) {
            if (subSlice.rangeStart + fileAttributeDic.fileSize > sliceRangeEnd) {
                [[TTDownloadManager shareInstance] deleteFile:subSliceFullPath];
                if (!subSlice.isImmutable) {
                    subSlice.rangeEnd = -1;
                }
            }
            DLLOGD(@"size check failed");
            return NO;
        }
    } else {
        return NO;
    }
    return YES;
}

#ifdef DOWNLOADER_DEBUG
- (void)printSubSliceInfo:(TTDownloadTask *)task {
    for (TTDownloadSubSliceInfo *info in self.subSliceInfoArray) {
        DLLOGD(@"debugRange:printSubSliceInfo:sliceNo=%d,subNo=%lu,subName=%@,subRangeStart=%lld,subRangeEnd=%lld", info.sliceNumber, (unsigned long)info.subSliceNumber, info.subSliceName, info.rangeStart, info.rangeEnd);
        NSString *subSliceFullPath = [task.downloadTaskSliceFullPath stringByAppendingPathComponent:info.subSliceName];
        NSError *error = nil;
        NSDictionary *fileAttributeDic = [[NSFileManager defaultManager] attributesOfItemAtPath:subSliceFullPath error:&error];
        int64_t realRangeEnd = info.rangeStart + fileAttributeDic.fileSize;
        DLLOGD(@"debugRange:printSubSliceInfo:real endRange=%lld", realRangeEnd);
    }
}
#endif

@end

@implementation TTDownloadSubSliceInfo

@end

NS_ASSUME_NONNULL_END
