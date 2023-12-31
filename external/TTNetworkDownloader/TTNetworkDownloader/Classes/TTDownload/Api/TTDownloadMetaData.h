#ifndef TT_DOWNLOAD_META_DATA_H_
#define TT_DOWNLOAD_META_DATA_H_

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kTTDownloaderRestoreResultNotification;
extern NSString *const kTTDownloaderRestoreResultNotificationParamKey;

static const NSTimeInterval kByPassCheckCacheLifeTime = -9999;

typedef NSUInteger (^TTMd5Callback)(NSString *md5, NSString *filePath);

typedef NS_ENUM(NSInteger, QueueType) {
    QUEUE_PRIORITY_LOW,
    QUEUE_PRIORITY_MID,
    QUEUE_PRIORITY_HIGH,
};

typedef NS_ENUM(NSUInteger, TTDownloadTTMd5Code) {
    TT_DOWNLOAD_TTMD5_CHECK_PASS = 0,
    TT_DOWNLOAD_TTMD5_NOT_SUPPORT = 999,
    TT_DOWNLOAD_TTMD5_MAX,
};

typedef NS_ENUM(NSInteger, InsertType) {
    QUEUE_TAIL,
    QUEUE_HEAD,
};

typedef NS_ENUM(NSInteger, ClearCacheType) {
    DO_NOT_CLEAR = 0,
    CLEAR_ALL_CACHE = 1,
    CLEAR_CACHE_BY_KEY = 2,
    CLEAR_CACHE_BY_COMPONENT_ID = 3,
    CLEAR_NO_EXPIRE_TIME_CACHE = 4,
};

typedef NS_ENUM(NSInteger, ClearRuleStatus) {
    CLEAR_INIT = 0,
    CLEAR_DONE = 1,
};

/**
 *Downloader's error code.
 */
typedef NS_ENUM(NSInteger, StatusCode) {
    ERROR_INIT = 0,
    /**
     *File download completely. 1
     */
    DOWNLOAD_SUCCESS = 1,
    /**
     *Start download. 2
     */
    ERROR_START_DOWNLOAD = 2,
    /**
     *File download failed. 3
     */
    ERROR_DOWNLOAD_FAILED = 3,
    /**
     *File name error. 4
     */
    ERROR_FILE_NAME_ERROR = 4,
    /**
     *File is downloading. 5
     */
    ERROR_FILE_DOWNLOADING = 5,
    /**
     *File Had Downloaded. 6
     */
    ERROR_FILE_DOWNLOADED = 6,
    /**
     *URL invalid. 7
     */
    ERROR_URL_INVALID = 7,
    /**
     *Callback is nil. 8
     */
    ERROR_CALLBACK_NULL = 8,
    /**
     *No task's historical records. 9
     */
    ERROR_DOWNLOAD_RECORD_NOT_EXIST = 9,
    /**
     *No task can be resumed. 10
     */
    ERROR_NO_TASK_CAN_RESUME = 10,
    /**
     *get content length failed. 11
     */
    ERROR_GET_CONTENT_LENGTH_FAILED = 11,
    /**
     *Create download directory failed. 12
     */
    ERROR_CREATE_DOWNLOAD_TASK_DIR = 12,
    /**
     *Slice size error. Real size > Normal size. 13
     */
    ERROR_SLICE_SIZE_ERROR = 13,
    /**
     *Slice size is error when merge. 14
     */
    ERROR_MERGE_SLICE_SIZE_ERROR = 14,
    /**
     *Cancel successfully. 15
     */
    ERROR_CANCEL_SUCCESS = 15,
    /**
     *Delete successfully. 16
     */
    ERROR_DELETE_SUCCESS = 16,
    /**
     *Delete failed. 17
     */
    ERROR_DELETE_FAIL = 17,
    /**
     *Read config from DB failed. 18
     */
    ERROR_LOAD_CONFIG_FROM_DB_FAILED = 18,
    /**
     *Frequent operation. 19
     */
    ERROR_REPEAT_URL = 19,
    /**
     *Task's count is overflow. 20
     */
    ERROR_DOWNLOAD_TASK_COUNT_OVERFLOW = 20,
    /**
     *Free disk space is not enough. 21
     */
    ERROR_FREE_SPACE_NOT_ENOUGH = 21,
    /**
     *If use Key interface, please put valid url to urlList.Otherwise return this error code. 22
     */
    ERROR_KEY_NEED_VALID_URL_IN_URLLISTS = 22,
    /**
     *Delete merge file failed. 23
     */
    ERROR_DELETE_MERGE_FILE_FAILED = 23,
    /**
     *Free disk space is not enough while merging slice. 24
     */
    ERROR_FREE_SPACE_NOT_ENOUGH_WHILE_MERGE = 24,
    /**
     *Md5 check failed. 25
     */
    ERROR_MD5_CHECK_FAILED_WHILE_MERGE = 25,
    /**
     *Merge slice successfully. 26
     */
    ERROR_MERGE_SUCCESS = 26,
    /**
     *Rename merge file failed. 27
     */
    ERROR_RENAME_FILE_FAIL = 27,
    /**
     *Create semaphore 28
     */
    ERROR_CREATE_SEM_FAILED = 28,
    /**
     *parameter error in DownloadGlobalParameters  29
     */
    ERROR_GLOBAL_PARAMETERS_INVALID = 29,
    /**
     *Write disk failed。30
     */
    ERROR_WRITE_DISK_FAILED = 30,
    /**
     *Downloaded file miss. 31
     */
    ERROR_DOWNLOADED_FILE_MISS = 31,
    /**
     * Network unavailable 32
     */
    ERROR_CANNOT_ACCESS_NETWORK = 32,
    /**
     *Retry times reach max. 33
     */
    ERROR_RETRY_COUNT_ALL_USED = 33,
    /**
     *Enable wifi only mode.If no wifi can be used,will return this error code. 34
     */
    ERROR_WIFI_ONLY_BUT_NO_WIFI = 34,
    /**
     *If no net can be used, will return this error code 35
     */
    ERROR_NET_UNAVAILABLE = 35,
    /**
     *Add new configuration to DB failed. 36
     */
    ERROR_CREATE_DOWNLOAD_CONFIG_FAILED = 36,
    /**
     *Create restore file flags failed. 37
     */
    ERROR_CREATE_RESTORE_FLAG_FAILED = 37,
    /**
     *Array check failed. 38
     */
    ERROR_ARRAY_INVALID = 38,
    /**
     *Create downloadSliceTask object failed. 39
     */
    ERROR_CRATE_SLICE_DOWNLOAD_TASK_FAILED = 39,
    /**
     *Move and rename file failed. 40
     */
    ERROR_MOVE_DOWNLOAD_FILE_FAILED = 40,
    /**
     *If switch to foreground failed from background,will return this error code. 41
     */
    ERROR_FOREGROUND_CONTINUE_TASK_FAILED = 41,
    /**
     *After enable wifi only mode,if task switch to cellular network,it will be canceled.And return this error code. 42
     */
    ERROR_WIFI_ONLY_CANCEL = 42,
    /**
     *Parameter about merging is error.  43
     */
    ERROR_MERGE_PARAMETERS_ERROR = 43,
    /**
     *Create merge file failed. 44
     */
    ERROR_CREATE_MERGE_FILE_FAILED = 44,
    /**
     *If url doesn't support range,the valid slice count is just one.If not,will return this error code. 45
     */
    ERROR_NO_RANGE_SLICE_NO_ONE = 45,
    /**
     *When enable isSkipGetContentLength, will check last slice's status after download completely.
     *If last slice's status isn't DOWNLOADED,will return this error code. 46
     */
    ERROR_SKIP_GET_CONTENT_LEN_LAST_STATUS_ERROR = 46,
    /**
     *Sometimes,we found last sub slice size error after download completely.
     *To avoid this case,we always check last sub slice size.If size is error,will return this error code. 47
     */
    ERROR_CHECK_LAST_SUB_SLICE_SIZE_FAILED = 47,
    ERROR_CHECK_CACHE_FAILED = 48,
    ERROR_CHECK_CACHE_COMPLETED = 49,
    //precheck content length fail
    ERROR_FORE_CHECK_CONTENT_LENGTH_FAIL = 50,
    
    ERROR_KEY_INVALID = 51,
    ERROR_URGENT_MODE_FAILED = 52,
    ERROR_CREATE_CACHE_BACKUP_DIR_FAILED = 53,
    ERROR_MD5_CHECK_OK = 54,
    ERROR_TTMD5_CHECK_OK = 55,
    ERROR_TTMD5_CHECK_FAILED = 56,
    ERROR_MD5_CHECK_IGNORE = 57,
    ERROR_NO_NET_CANCEL = 58,
    ERROR_RANGE_CHECK_FAILED = 59,
    ERROR_RANGE_TASK_NOT_SUPPORT_RANGE = 60,
    ERROR_MOVE_TO_USER_DIR_FAILED = 61,
    ERROR_COPY_MERGE_FILE_FAILED = 62,
    ERROR_USER_NO_VALID_FILE_PATH = 63,
    ERROR_USER_FILE_EXIST = 64,
    ERROR_USER_CHECK_PATH_SUCCESS = 65,
    ERROR_USER_DIRECTORY_NOT_EXIST = 66,
    ERROR_MUST_SET_CACHE_LIFE_TIME = 67,
    ERROR_MAX,
};

/**
 *  task's status
 */
typedef NS_ENUM(NSInteger, DownloadStatus) {
    INIT = 0,
    DOWNLOADING = 1,
    DOWNLOADED = 2,
    FAILED = 3,
    SUSPENDED = 4,
    DELETED = 5,
    CANCELLED = 6,
    RETRY = 7,
    WAIT_RETRY = 8,
    RESTART = 9,
    BACKGROUND = 10,
    QUEUE_WAIT = 11,
    MAX
};

typedef NS_ENUM(NSInteger, TrackStatus) {

    TRACK_NONE = 0,
    TRACK_UNCOMPLETED,
    TRACK_FAIL,
    TRACK_FINISH,
    TRACK_CANCEL
};

/**
 *Task's parameters.
 */
@interface DownloadGlobalParameters : JSONModel
/**
 *Url's maximum retry times while getting content length. Valid value 0 ~ 10
 */
@property (atomic, assign) NSInteger urlRetryTimes;
/**
 *Slice retry interval. Valid value 0 ~ 100
 */
@property (atomic, assign) NSTimeInterval retryTimeoutInterval;
/**
 *Slice retry interval increment. Valid value 0 ~ 100.
 */
@property (atomic, assign) NSTimeInterval retryTimeoutIntervalIncrement;

@property (atomic, assign) BOOL isSliced;
/**
 *Slice count max. Valid value 1 ~ 4
 */
@property (atomic, assign) NSInteger sliceMaxNumber;
/**
 *Slice threshold.File will be cut apart if it's size greater than minDevisionSize. The unit is byte.
 */
@property (atomic, assign) int64_t minDevisionSize;
/**
 *While merging slice, read specific length of data from disk to memory.You can set the length by this parameter.
 */
@property (atomic, assign) int64_t mergeDataLength;
/**
 *Slice max retry times.The default value is 3. Valid value 1 ~ 10.
 */
@property (atomic, assign) NSInteger sliceMaxRetryTimes;
/**
 *Url retry interval in get content length.The default value is 5s. Valid value 0 ~ 60.
 */
@property (atomic, assign) NSTimeInterval contentLengthWaitMaxInterval;
/**
 *Throttle of network speed for downloading.
 *throttleNetSpeed > 0  ----->will start throttle net speed.
 *throttleNetSpeed = 0  ----->won't throttle net speed or stop throttling net speed.
 */
@property (atomic, assign) int64_t throttleNetSpeed;
/**
 *Enable this function,if all of https request failed, will retry using http request.Default value is NO.
 */
@property (atomic, assign) BOOL isHttps2HttpFallback;
/**
 *Enable/disable wifi only mode. Default is NO.
 */
@property (atomic, assign) BOOL isDownloadWifiOnly;
/**
 *Enable/disable automatic restore function.Max Valid value is 100.
 */
@property (atomic, assign) int8_t restoreTimesAutomatic;
/**
 *Enable/disable tracker.Default is NO.
 */
@property (atomic, assign) BOOL isUseTracker;

@property (atomic, assign) BOOL isBackgroundDownloadEnable;

@property (atomic, strong, nullable) NSArray *disableBackgroundDownloadIOSVersionList;

@property (atomic, assign) BOOL isBackgroundDownloadWifiOnlyDisable;

@property (atomic, strong, nullable) NSArray *backgroundDownloadDisableWifiOnlyVersionList;

@property (atomic, strong, nullable) NSMutableDictionary *httpHeaders;

/**
 *Enable/disable the function of skiping get content length.Default value is NO. If you want to
 *enable this function,please contact diweiguang@bytedance.com.
 */
@property (atomic, assign) BOOL isSkipGetContentLength;
/**
 *If skip get content length,we don't know whether url support range or not.
 *So this parameter can set value about range.Default value is NO.If you want to set YES,it means
 *if url doesn't support range, maybe will download failed.So please ensure server support range before
 *you set this value to YES.
 */
@property (atomic, assign) BOOL isServerSupportRangeDefault;

@property (atomic, assign) BOOL isCheckCacheValid;

@property (atomic, assign) BOOL isRetainCacheIfCheckFailed;

@property (atomic, assign) BOOL isIgnoreMaxAgeCheck;

@property (atomic, assign) BOOL isUrgentModeEnable;

@property (atomic, assign) BOOL isClearCacheIfNoMaxAge;

@property (atomic, assign) BOOL isTTNetUrgentModeEnable;
/**
 *TTNet timeout parameters.
 */
@property (atomic, assign) int16_t ttnetRequestTimeout;
@property (atomic, assign) int16_t ttnetReadDataTimeout;
@property (atomic, assign) int16_t ttnetRcvHeaderTimeout;
@property (atomic, assign) int16_t ttnetProtectTimeout;


/**
 *Task priority.
 */
@property (atomic, assign) QueueType queuePriority;

@property (atomic, assign) InsertType insertType;

/**
 *Dynamic throttle
 */
@property (atomic, assign) uint8_t observationBufferLength;

@property (atomic, assign) uint8_t checkObservationBufferLength;

@property (atomic, assign) uint8_t measureSpeedTimes;

@property (atomic, assign) int64_t startThrottleBandWidthMin;

@property (atomic, assign) uint8_t rttGap;

@property (atomic, assign) int64_t speedGap;

@property (atomic, assign) float_t matchConditionPercent;

@property (atomic, assign) int64_t dynamicBalanceDivisionThreshold;

@property (atomic, assign) float_t bandwidthDeltaCoefficient;

@property (atomic, assign) int64_t bandwidthDeltaConstant;

#pragma mark - check file length at getting content length state if value > 0
@property (atomic, assign) int64_t expectFileLength;

@property (atomic, assign) BOOL preCheckFileLength;
/**
 *Cache's maximum life time.If expire,will clear it when app start.Unit is second.
 */
@property (atomic, assign) NSTimeInterval cacheLifeTimeMax;
/**
 *Identify a component's download task.Caller can clear cache by componet id.
 */
@property (atomic, copy, nullable) NSString* componentId;

#pragma mark - restart immediately when network change from WiFi to cellular
@property (atomic, assign) BOOL isRestartImmediatelyWhenNetworkChange;

@property (atomic, assign) BOOL isStopIfNoNet;

@property (atomic, assign) int64_t startOffset;
@property (atomic, assign) int64_t endOffset;

@property (atomic, copy) NSString *backgroundBOEDomain;

@property (atomic, assign) BOOL isClearDownloadedTaskCacheAuto;
/**
 * Note:The path must begin with the following string.
 * @"SystemData" , @"Library", @"tmp" , @"Documents"
 * For example if the full path is @"/Users/diweiguang/Library/Developer/CoreSimulator/Devices/07E667A1-2DE3-4174-BCBA-C5BF15ADED88/data/Containers/Data/Application/17E59AF9-90F4-4315-A04F-FEE28A304FD2/Documents/test.config",
 * you need input @'Documents/test.config" which just ignore sandbox HOME path.
 */
@property (atomic, copy) NSString *userCachePath;

@property (atomic, assign) BOOL isCommonParamEnable;

@property (nonatomic, copy) TTMd5Callback TTMd5Callback;
@end

/**
 *Download progress report struct.it will report per second.
 */
@interface DownloadProgressInfo : NSObject
/**
 *The key uniquely identify a task.
 */
@property (atomic, copy, nonnull) NSString *urlKey;
/**
 *Second url.
 */
@property (atomic, copy, nonnull) NSString *secondUrl;
/**
 *Record progress.
 */
@property (atomic, assign) float progress;
/**
 *Network speed.
 */
@property (atomic, assign) int64_t netDownloadSpeed;
/**
 *Length of downloaded file.
 */
@property (atomic, assign) int64_t downloadedSize;
/**
 *Length of total file.
 */
@property (atomic, assign) int64_t totalSize;
@end

/**
 *Report the download result.
 */
@class TTDownloadTrackModel;
@interface DownloadResultNotification : NSObject
/**
 *The key uniquely identify a task.
 */
@property (atomic, copy, nonnull) NSString *urlKey;
/**
 *Second url.
 */
@property (atomic, copy, nonnull) NSString *secondUrl;
/**
 *Error code.
 */
@property (atomic, assign) StatusCode code;
/**
 *If file had downloaded,it will record file path.Otherwise it's nil.
 */
@property (atomic, copy, nullable) NSString *downloadedFilePath;
/**
 *Trancker information.
 */
@property (atomic, strong, nullable) TTDownloadTrackModel *trackModel;
/**
 *If download failed,will record error response  in this array.
 */
@property (atomic, strong, nullable) NSMutableArray *httpResponseArray;
/**
 *Downloader's error log.
 */
@property (atomic, copy, nullable) NSString *downloaderLog;

- (void)addLog:(NSString *)log;

@end

/**
 *Report download information.
 */
@interface DownloadInfo : NSObject
/**
 *The key uniquely identify a task.
 */
@property (nonatomic, copy, nonnull) NSString *urlKey;
/**
 *Second url.
 */
@property (nonatomic, strong, nonnull) NSString *secondUrl;
/**
 *Download status.
 */
@property (nonatomic, assign) DownloadStatus status;
/**
 *Input file name.
 */
@property (nonatomic, copy, nonnull) NSString *inputFileName;
/**
 *Length of downloaded file.
 */
@property (nonatomic, assign) int64_t downloadedSize;
/**
 *Length of total file.
 */
@property (nonatomic, assign) int64_t totalSize;
/**
 *If file doenload completely,this parameter will record file full path.
 */
@property (nonatomic, copy, nullable) NSString *fileFullPath;
@end

/**
 *The callback that report progress.
 */
typedef void (^TTDownloadProgressBlock)(DownloadProgressInfo *progress);
/**
 *The callback that report the download result.
 */
typedef void (^TTDownloadResultBlock)(DownloadResultNotification *resultNotification);
/**
 *The callback report download information.
 */
typedef void (^TTDownloadInfoBlock)(DownloadInfo *downloadInfo);
/**
 *The callback report tracker information.
 */
typedef void (^TTDownloadEventBlock)(NSString *event, NSDictionary *params);

#endif

NS_ASSUME_NONNULL_END
