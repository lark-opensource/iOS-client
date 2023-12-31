
#import "TTDownloadManager.h"
#import "TTDownloadTask.h"

NS_ASSUME_NONNULL_BEGIN

@class TTDownloadSubSliceInfo;

@interface TTDownloadSliceTaskConfig : NSObject

@property (atomic, copy) NSString *urlKey;

@property (atomic, copy) NSString *secondUrl;

@property (atomic, assign) int8_t sliceNumber;
/**
 *The name of temporary file for slice.
 */
@property (atomic, copy) NSString *sliceTempStorageName;
/**
 *Slice status.
 */
@property (atomic, assign) DownloadStatus sliceStatus;
/**
 *Slice start range.
 */
@property (atomic, assign) int64_t startByte;
/**
 *Slice end range.
 */
@property (atomic, assign) int64_t endByte;
/**
 *The length of downloaded slice file.
 */
@property (atomic, assign) int64_t hasDownloadedLength;
/**
 *The length of total slice file.
 */
@property (atomic, assign) int64_t sliceTotalLength;

@property (nonatomic, assign) int64_t throttleNetSpeed;

/**
 *Record the rest of retry times.
 */
@property (atomic, assign) int8_t retryTimes;

@property (nonatomic, assign) int8_t retryTimesMax;

@property (atomic, assign) BOOL isCancel;

@property (atomic, strong) NSMutableArray<TTDownloadSubSliceInfo *> *subSliceInfoArray;

- (StatusCode)mergeSubSlice:(NSString *)sliceFullPath
                 fileHandle:(NSFileHandle *)fileHandle
            mergeDataLength:(int64_t)mergeDataLength
     isSkipGetContentLength:(BOOL)isSkipGetContentLength;

- (BOOL)updateSliceConfig:(TTDownloadTask *)task
         isBackgroundTask:(BOOL)isBackgroundTask;

- (BOOL)checkLastSubSlice:(TTDownloadTask *)task;
#ifdef DOWNLOADER_DEBUG
- (void)printSubSliceInfo:(TTDownloadTask *)task;
#endif
@end

@interface TTDownloadSubSliceInfo : NSObject

@property (atomic, copy) NSString *fileStorageDir;

@property (atomic, assign) int8_t sliceNumber;

@property (atomic, assign) NSUInteger subSliceNumber;

@property (atomic, copy) NSString *subSliceName;

@property (atomic, copy) NSString *subSliceFullPath;

@property (atomic, assign) int64_t rangeStart;

@property (atomic, assign) int64_t rangeEnd;

@property (atomic, assign) DownloadStatus sliceStatus;

@property (atomic, assign) BOOL isImmutable;

@end

NS_ASSUME_NONNULL_END
