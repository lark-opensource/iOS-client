
#import <TTNetworkManager/TTNetworkDefine.h>
#import <TTNetworkManager/TTNetworkUtil.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import "TTDownloadMetaData.h"
#import "TTDownloadTaskConfig.h"
#import "TTDownloadManager.h"
#import "TTDownloadLog.h"
#import "TTDownloadLogLite.h"

NS_ASSUME_NONNULL_BEGIN

#define GET_LENGTH_RETRY_MAX 3
#define ALLOW_DIVISION_SIZE_MIN 10 * 1024 * 1024
#define UNIT_1_M 1024 * 1024
#define ALLOW_SLICE_TOTAL_MAX 4
#define MERGE_DATA_LENGTH 20971520
#define WAIT_TIME_MAX 10 * NSEC_PER_SEC            //10s
#define RETRY_INTERVAL 10 * NSEC_PER_SEC           //10s
#define SLICE_MAX_RETRY_TIMES 3
#define NOT_RETRY 0
#define CONTENT_LENGTH_WAIT_TIME 65 * NSEC_PER_SEC //65s
#define BACKGROUND_CANCEL_WAIT_TIME 2 * NSEC_PER_SEC //2s
#define CONTENT_LENGTH_RETRY_WAIT_TIME 5           //5s
#define FREE_DISK_GAP 0
#define MD5_VALUE_VALID_LENGTH_MIN 0
#define CREATE_SEM_RETRY_TIMES 5
#define URL_RETRY_TIMES 0
#define URL_SCHEME_HTTPS @"https"
#define URL_SCHEME_HTTP @"http"
#define RESTORE_MODE_FLAG_NAME @"tt_downloader_restore_flag"
#define SLICE_DIR @"sliceDir"

#define TT_DOWNLOAD_DYNAMIC_THROTTLE

static const int64_t kDynamicThrottleBalanceEnable = -1;
static const int64_t kCloseThrottle = 0;
static const int kDateCompareError = -100;
static NSString * const kDateFormat = @"EEE, dd MMM yyyy HH:mm:ss zzz";
static NSString * const kUrgentModeTempDir = @"UrgentModeTTDownloaderTempDir";
static NSString * const kTTDownloaderCheckCacheBackupDir = @"TTDownloaderCheckCacheBackupDir";

typedef BOOL(^HeaderCallback)(TTHttpResponse *response);

typedef NS_ENUM(NSInteger, versionType) {
    //original
    ORIGINAL_VERSION = 0,
    ADD_PARAMETERS_TABLE_VERSION,
    ADD_SUB_SLICE_TABLE_VERSION,
};

@class DownloadResultNotification;
@class DownloadProgressInfo;
@class TTDownloadTaskConfig;
@class TTDownloadTrackModel;
@class TTDownloadSliceTaskConfig;
@class TTDownloadTaskExtendConfig;

@interface TTDownloadTask : NSObject
/**
 *The key uniquely identify a task,which is used in multithreading environment
 */
@property (atomic, copy) NSString *urlKey;
/**
 *Second url,which is used in multithreading environment
 */
@property (atomic, copy) NSString *secondUrl;

@property (nonatomic, assign) int64_t firstSliceNeedDownloadLength;
/**
 *Task's parameters,which is used in multithreading environment.
 */
@property (atomic, strong) DownloadGlobalParameters *userParameters;
/**
 *Use it in multithreading environment.
 */
@property (atomic, strong) TTDownloadTaskConfig *taskConfig;
/**
 *Use it in multithreading environment.
 */
@property (atomic, strong) TTDownloadTrackModel *trackModel;

/**
 *Use it in multithreading environment.
 */
@property (atomic, copy) NSString *downloadTaskFullPath;
@property (atomic, copy) NSString *downloadTaskSliceFullPath;

@property (atomic, assign) BOOL isAppAtBackground;

@property (atomic, strong) dispatch_semaphore_t backgroundTaskCancelSem;

@property (atomic, assign) int8_t backgroundDownloadedCounter;

@property (atomic, assign) int8_t backgroundFailedCounter;

@property (atomic, assign) BOOL isRestartTask;

@property (atomic, assign) BOOL isMobileSwitchToWifiCancel;

@property (atomic, assign) BOOL isWifiOnlyCancel;

@property (atomic, assign) BOOL isCancelTask;

@property (atomic, assign) BOOL isSkipGetContentLength;

@property (atomic, assign) BOOL isBackgroundMerging;

@property (atomic, assign) BOOL isStopWhileLoop;

@property (atomic, assign) BOOL isServerSupportAcceptRange;

@property (nonatomic, assign) int64_t needDownloadLengthTotal;

@property (atomic, assign) int64_t contentTotalLength;

@property (nonatomic, assign) int realSliceCount;

@property (atomic, copy) TTDownloadProgressBlock progressBlock;
@property (atomic, copy) TTDownloadResultBlock  resultBlock;
@property (nonatomic, copy) HeaderCallback onHeaderCallback;

@property (atomic, strong) TTDownloadTaskExtendConfig *originExtendConfig;

/**
 *Semaphore which is used in mutilthreading environment.
 */
@property (atomic, strong) dispatch_semaphore_t sem;

@property (atomic, strong) TTDownloadLogLite *dllog;

- (id)initWithObjectDownloadTaskConfig:(TTDownloadTaskConfig *)downloadTaskConfig;

- (void)startTask:(NSString *)url
         urlLists:(NSArray *)urlLists
         fileName:(NSString *)fileName
         md5Value:(NSString *)md5Value
         isResume:(BOOL)isResume
         isUseKey:(BOOL)isUseKey
    progressBlock:(TTDownloadProgressBlock)progressBlock
      resultBlock:(TTDownloadResultBlock)resultBlock;

- (void)deleteTask:(TTDownloadResultBlock)deleteResultBlock;

- (void)cancelTask;

- (void)sliceCountHasDownloadedIncrease;

- (void)sliceCancelCountIncrease;

- (void)sliceDownloadFailedCountIncrease;

- (void)addBackgroundDownloadedBytes:(int64_t)increaseBytes;

- (void)backgroundDownloadedCounterIncrease;

- (void)backgroundFailedCounterIncrease;

- (void)setThrottleSpeed:(int64_t)speed;

- (StatusCode)mergeAllSlice;

- (void)updateDownloadTaskStatus:(DownloadStatus)status;

- (BOOL)getIsBackgroundDownloadWifiOnlyDisable;

- (void)setBlock:(TTDownloadResultBlock)block;
- (void)addHttpResponse:(TTHttpResponse *)response;

- (BOOL)getIsCheckCacheValid;

#ifdef DOWNLOADER_DEBUG
+ (NSString *)netQualityTypeToString:(TTNetEffectiveConnectionType)type;
#endif

- (int16_t)getTTNetRequestTimeout;

- (int16_t)getTTNetReadDataTimeout;

- (int16_t)getTTNetRcvHeaderTimeout;

- (int16_t)getTTNetProtectTimeout;

- (BOOL)checkBackgroundDownloadFinished;

- (BOOL)isRangeDownloadEnable;

- (int64_t)getStartOffset;

- (BOOL)getIsCommonParamEnable;
@end

NS_ASSUME_NONNULL_END
