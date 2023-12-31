#import "TTDispatcherTask.h"
#import "TTDownloadCommonTools.h"
#import "TTDownloadLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTDispatcherTask()

@property (atomic, strong) NSMutableArray<TTDispatcherTask *> *sameTaskResultBlockArray;

@end

@implementation TTDispatcherTask

- (id)init {
    self = [super init];
    if (self) {
        self.sameTaskResultBlockArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)replaceFilePath:(DownloadResultNotification *)notification task:(TTDispatcherTask*)task {
    NSString *fileName = [notification.downloadedFilePath lastPathComponent];
    if (task.userParameters.userCachePath) {
        NSString *realPath = [TTDownloadCommonTools getUserRealFullPath:task.userParameters.userCachePath];
        NSError *error = nil;
        if ([TTDownloadCommonTools copyFile:notification.downloadedFilePath toPath:realPath isOverwrite:NO error:&error]) {
            notification.downloadedFilePath = realPath;
        } else {
            [notification addLog:error.description];
            notification.code = ERROR_COPY_MERGE_FILE_FAILED;
            notification.downloadedFilePath = nil;
        }
        return;
    }
    /**
     * We can't copy files largger than 50M
     */
    int64_t fileLength = [TTDownloadCommonTools getFileSize:notification.downloadedFilePath];
    if (fileLength <= 0 || fileLength > 50 * 1024 * 1024) {
        return;
    }
    /**
     * If TTMergeTaskDownloadedFileBackupDir directory doesn't exist,we must create it.
     */
    NSString *backupDir = [[TTDownloadCommonTools shareInstance].systemTempDir stringByAppendingPathComponent:kMergeTaskDownloadedFileBackupDir];
    
    if (![TTDownloadCommonTools isDirectoryExist:backupDir]) {
        NSError *error = nil;
        if (![TTDownloadCommonTools createDir:backupDir error:&error]) {
            if (error) {
                DLLOGD(@"error info=%@", error.description);
                [notification addLog:error.description];
            }
            /**
             * If create directory failed,we do nothing.
             */
            return;
        }
    }
    /**
     * Key's md5 value is name of download directory.
     */
    NSString *downloadDir = [NSString stringWithFormat:@"%@_%u", [TTDownloadCommonTools calculateUrlMd5:notification.urlKey], arc4random()];
    
    NSString *searchPath = [backupDir stringByAppendingPathComponent:downloadDir];
    
    NSString *backupFilePath = [searchPath stringByAppendingPathComponent:fileName];
    
    if (![TTDownloadCommonTools isDirectoryExist:searchPath]) {
        NSError *error = nil;
        if (![TTDownloadCommonTools createDir:searchPath error:&error]) {
            if (error) {
                DLLOGD(@"error info=%@", error.description);
                [notification addLog:error.description];
            }
            /**
             * If create directory failed,we do nothing.
             */
            return;
        }
        
        if (![TTDownloadCommonTools copyFile:notification.downloadedFilePath
                                      toPath:backupFilePath
                                 isOverwrite:YES
                                       error:&error]) {
            [notification addLog:error.description];
            return;
        }
    }
    
    notification.downloadedFilePath = backupFilePath;
}

- (void)addResultBlock:(TTDispatcherTask *)task {
    if (!task) {
        return;
    }
    [self.sameTaskResultBlockArray addObject:task];
}

- (void)executeAllResultBlock:(DownloadResultNotification *)notification {
    if (!notification) {
        return;
    }
    
    for (TTDispatcherTask *mergeTask in self.sameTaskResultBlockArray) {
        DownloadResultNotification *copyNotification = [notification copy];
        /**
         * We must backup downloaded file in backup dir,because first block maybe delete original file.
         * So we will return backup dir path for later block.
         */
        if ((DOWNLOAD_SUCCESS == copyNotification.code) || (ERROR_FILE_DOWNLOADED == copyNotification.code)) {
            [self replaceFilePath:copyNotification task:mergeTask];
        }
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            if (mergeTask.resultBlock) {
                mergeTask.resultBlock(copyNotification);
            }
        });
    }
}

- (void)dealloc {
    DLLOGD(@"dlLog:dealloc:file=%s ,function=%s", __FILE__, __FUNCTION__);
}

@end

NS_ASSUME_NONNULL_END
