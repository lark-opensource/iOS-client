
#import <Foundation/Foundation.h>
#import <TTReachability/TTReachability.h>

#import "TTClearCacheRule.h"
#import "TTDownloadTask.h"
#import "TTDownloadTracker.h"
#import "TTDownloadLog.h"
#import "TTDownloadTncConfigManager.h"

@class TTDownloadTaskConfig;
@class TTDownloadTask;
@class TTDownloadSubSliceInfo;
@class TTDownloadSliceTaskConfig;

NS_ASSUME_NONNULL_BEGIN

typedef void (^BGCompletedHandler)(void);

typedef void (^TimeoutCallBack)(void);

typedef void (^TTDispatcherTaskCompletionHandler)(DownloadResultNotification *notification);

#define GET_FREE_DISK_SPACE_ERROR -1

#define DOWNLOADER_AUTO_RELEASE_POOL_BEGIN @autoreleasepool{
#define DOWNLOADER_AUTO_RELEASE_POOL_END }

@interface TTDownloadManager : NSObject

@property (atomic, assign) BOOL isHadLoadConfigFromStorage;

@property (nonatomic, copy) NSString * cachePath;

@property (nonatomic, copy) NSString * appSupportPath;

@property (atomic, copy) BGCompletedHandler bgCompletedHandler;

@property (atomic, copy) TTDispatcherTaskCompletionHandler onCompletionHandler;

/**
 * log report block
 */
@property (nonatomic, copy) TTDownloadEventBlock eventBlock;

@property (atomic, copy) NSString *urgentModeTempRootDir;

@property (atomic, assign, readonly) BOOL isAppBackground;

@property (atomic, assign, readwrite) BOOL isForceCacheLifeTimeMaxEnable;

+ (instancetype)shareInstance;

- (bool)setGlobalDownloadParameters:(DownloadGlobalParameters *)globalParameters;

- (DownloadGlobalParameters *)getGlobalDownloadParameters;

- (BOOL)loadConfigFromStorage:(NSMutableArray<NSError *> *)errorArray;

- (BOOL)addDownloadTaskConfig:(TTDownloadTaskConfig *)downloadTaskConfig error:(NSError **)error;

- (BOOL)removeDownloadTaskConfig:(TTDownloadTaskConfig *)config error:(NSError **)error;

- (BOOL)updateDownloadTaskConfig:(NSString *)url status:(DownloadStatus)status error:(NSError **)error;


- (int)startDownloadWithURL:(NSString *)urlKey
                   isUseKey:(BOOL)isUseKey
                   fileName:(NSString *)fileName
                   md5Value:(NSString *)md5Value
                   urlLists:(NSArray *)urlLists
                   progress:(TTDownloadProgressBlock)progress
                     status:(TTDownloadResultBlock)status
             userParameters:(DownloadGlobalParameters *)userParameters;

- (int)resumeDownloadWithURL:(NSString *)urlKey
                    isUseKey:(BOOL)isUseKey
                    urlLists:(NSArray *)urlLists
                    progress:(TTDownloadProgressBlock)progress
                      status:(TTDownloadResultBlock)status
              userParameters:(DownloadGlobalParameters *)userParameters;

- (void)cancelDownloadWithURL:(NSString *)url block:(TTDownloadResultBlock)block;

- (void)deleteDownloadWithURL:(NSString *)url
                  resultBlock:(TTDownloadResultBlock)resultBlock;

- (void)queryDownloadInfoWithURL:(NSString *)url
               downloadInfoBlock:(TTDownloadInfoBlock)downloadInfoBlock
                          status:(DownloadStatus)status;

- (BOOL)deleteDownloadFile:(TTDownloadTaskConfig *)ttDownloadTaskConfig
                isDeleteDB:(BOOL)isDeleteDB
         isDeleteMergeFile:(BOOL)isDeleteMergeFile
         isDeleteSliceFile:(BOOL)isDeleteSliceFile;

- (BOOL)deleteFile:(NSString *)filePath;

- (void)setWifiOnlyWithUrlKey:(NSString *)urlKey isWifiOnly:(BOOL)isWifiOnly;

//interface for downloadTaskConfigDic
- (TTDownloadTask*)findDownloadingTaskInDicLock:(NSString *)url;

- (BOOL)addDownloadingTaskToDicLock:(TTDownloadTask*)task;

- (BOOL)deleteDownloadingTaskInDicLock:(NSString *)url;

- (BOOL)updateDownloadingTaskInDicLock:(TTDownloadTask*)task;

//interface for bgIdentifierDic
- (BOOL)findBgIdentifierDicLock:(NSString *)identifier;

- (BOOL)addBgIdentifierDicLock:(NSString *)identifier value:(NSString *)urlKey;

- (BOOL)deleteBgIdentifierDicLock:(NSString *)identifier;

- (BOOL)deleteBgIdentifierWithValueLock:(NSString *)value;

- (void)clearBgIdentifierDicLock;

- (void)runBgCompletedHandler;

//interface for downloadTaskConfigDic
- (TTDownloadTaskConfig *)findTaskConfigInDicLock:(NSString *)url;

- (BOOL)addTaskConfigToDicLock:(TTDownloadTaskConfig *)downloadTaskConfig;

- (BOOL)updateTaskConfigInDicLock:(TTDownloadTaskConfig *)downloadTaskConfig;

- (bool)setThrottleNetSpeedWithURL:(NSString *)url bytesPerSecond:(int64_t)bytesPerSecond;

- (BOOL)insertOrUpdateSubSliceInfo:(TTDownloadSubSliceInfo *)subslice error:(NSError **)error;

- (BOOL)updateSliceConfig:(TTDownloadSliceTaskConfig *)sliceConfig
               taskConfig:(TTDownloadTaskConfig *)taskConfig
                    error:(NSError **)error;

- (BOOL)deleteSubSliceInfo:(TTDownloadTaskConfig *)taskConfig error:(NSError **)error;

- (BOOL)addTrackModelToDB:(TTDownloadTrackModel *)ttDTM;

- (BOOL)getTrackModelFromDBForTask:(TTDownloadTask *)task;

- (TTDownloadTncConfigManager *)getTncConfig;

- (BOOL)updateParametersTable:(TTDownloadTaskConfig *)taskConfig error:(NSError **)error;

- (BOOL)updateExtendConfigSync:(TTDownloadTaskConfig *)taskConfig error:(NSError **)error;

- (BOOL)clearAllCache:(const ClearCacheType)type clearCacheKey:(const NSArray<NSString *> *)list error:(NSError **)error;

- (void)stopClearNoExpireCache;

- (int64_t)getAllCacheCount;

- (int64_t)getAllNoExpireTimeCacheCount;

- (NSMutableDictionary *)getAllRuleFromDB:(NSError **)error;

- (BOOL)insertOrUpdateClearCacheRule:(TTClearCacheRule *)rule error:(NSError **)error;

- (BOOL)deleteClearCacheRule:(TTClearCacheRule *)rule error:(NSError **)error;

- (BOOL)getIsForceCacheLifeTimeMaxEnable;

+ (int64_t)freeDiskSpace;

+ (BOOL)moveItemAtPath:(NSString *)path
                toPath:(NSString *)toPath
             overwrite:(BOOL)overwrite
                 error:(NSError **)error;

+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString;

+ (BOOL)isWifi;

+ (BOOL)isNetworkUnreachable;

+ (BOOL)isMobileNet;

+ (void)load;

+ (NetworkStatus)getCurrentNetType;

+ (BOOL)isArrayValid:(NSArray * )array;

+ (BOOL)createDir:(NSString *)dirPath error:(NSError **)error;

+ (NSMutableDictionary *)parseResumeData:(NSData *)resumeData;

+ (BOOL)isTaskConfigValid:(TTDownloadTaskConfig *)obj;

+ (int64_t)getHadDownloadedLength:(TTDownloadSliceTaskConfig *)sliceTaskConfig isReadLastSubSlice:(BOOL)isReadLastSubSlice;

+ (NSString *)calculateUrlMd5:(NSString *)url;

+ (BOOL)createNewFileAtPath:(NSString *)path error:(NSError **)error;

+ (dispatch_source_t)createAndStartTimer:(TimeoutCallBack)onTimeoutCallBack;

+ (void)stopTimer:(dispatch_source_t)timer;

+ (NSString *)getSubStringAfterKey:(NSString *)str key:(NSString *)key;

+ (int)compareDate:(NSString *)startDate withDate:(NSString *)endDate;

+ (NSString *)getFormatTime:(int64_t)tick;

+ (BOOL)isDirectoryExist:(NSString *)directoryPath;

+ (BOOL)isFileExist:(NSString *)filePath;

+ (NSString *)getFullFilePath:(TTDownloadTaskConfig *)taskConfig;

+ (NSString *)arrayToNSString:(NSArray<NSError *> *)array;
@end

NS_ASSUME_NONNULL_END
