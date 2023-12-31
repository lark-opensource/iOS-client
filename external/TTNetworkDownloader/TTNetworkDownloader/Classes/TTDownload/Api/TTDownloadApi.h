#import "TTDownloadMetaData.h"

@interface TTDownloadApi : NSObject
/**
 *  Get singleton interface.
 */
+ (instancetype _Nonnull )shareInstance;

/**
 *  Set the parameters for all of tasks.
 */
- (void)setGlobalDownloadParameters:(nonnull DownloadGlobalParameters *)globalParameters;

/**
 *  Set callback which report task's log when task end.
 */
- (void)setDownloadEventBlock:(TTDownloadEventBlock _Nonnull )eventBlock;

/**
 *  Start a downloaded task.
 *
 *  @param urlKey                The url you want to download.It's also the key that download task's unique identification.
 *
 *  @param fileName              Specify downloaded file's name. Note:It's just name,not fullpath!
 *
 *  @param md5Value              Downloaded file's md5 value.If this value is nil,won't do md5 check.
 *
 *  @param urlLists              Spare url.You can add url to urlLists.If urlKey request failed,will retry using them.
 *
 *  @param progress              The callback which report download progress.It can't be nil.
 *
 *  @param status                The callback which report download result.It can't be nil.
 *
 *  @param userParameters        Task's parameters.If it's nil,will use default value.
 */
- (int)startDownloadWithURL:(NSString * _Nonnull)urlKey
                   fileName:(NSString * _Nonnull)fileName
                   md5Value:(NSString * _Nullable)md5Value
                   urlLists:(NSArray<NSString *> * _Nullable)urlLists
                   progress:(TTDownloadProgressBlock _Nonnull )progress
                     status:(TTDownloadResultBlock _Nonnull )status
             userParameters:(DownloadGlobalParameters * _Nonnull)userParameters;

/**
 *  Start a downloaded task.
 *
 *  @param key                   The key that download task's unique identification.Won't use key to request,
 *                               so caller must put real urls to urlLists.
 *
 *  @param fileName              Specify downloaded file's name. Note:It's just name,not fullpath!
 *
 *  @param md5Value              Downloaded file's md5 value.If this value is nil,won't do md5 check.
 *
 *  @param urlLists              The practical url.When task start,will use first url to download.
 *                               If first request failed,will retry using others.This array can't be
 *                               nil.
 *
 *  @param progress              The callback which report download progress.It can't be nil.
 *
 *  @param status                The callback which report download result.It can't be nil.
 *
 *  @param userParameters        Task's parameters.If it's nil,will use default value.
 */
- (int)startDownloadWithKey:(NSString * _Nonnull)key
                   fileName:(NSString * _Nonnull)fileName
                   md5Value:(NSString * _Nullable)md5Value
                   urlLists:(NSArray<NSString *> * _Nonnull)urlLists
                   progress:(TTDownloadProgressBlock _Nonnull)progress
                     status:(TTDownloadResultBlock _Nonnull)status
             userParameters:(DownloadGlobalParameters * _Nullable)userParameters;

/**
 *  resume interface with url.
 *
 *  @param urlKey                The url you want to download.It's also the key that download task's unique identification.
 *
 *  @param progress              The callback which report download progress.It can't be nil.
 *
 *  @param status                The callback which report download result.It can't be nil.
 *
 *  @param userParameters        Task's parameters.If it's nil,will use default value.
 */

- (int)resumeDownloadWithURL:(NSString * _Nonnull)urlKey
                    progress:(TTDownloadProgressBlock _Nonnull )progress
                      status:(TTDownloadResultBlock _Nonnull )status
              userParameters:(DownloadGlobalParameters * _Nullable)userParameters;

/**
 *  resume interface with key.
 *
 *  @param key                   The key that download task's unique identification.Won't use key to request,
 *                               so caller must put real urls to urlLists.
 *
 *  @param urlLists              The practical url.When task start,will use first url to download.
 *                               If first request failed,will retry using others.This array can't be
 *                               nil.
 *
 *  @param progress              The callback which report download progress.It can't be nil.
 *
 *  @param status                The callback which report download result.It can't be nil.
 *
 *  @param userParameters        Task's parameters.If it's nil,will use default value.
 */
- (int)resumeDownloadWithKey:(NSString * _Nonnull)key
                    urlLists:(NSArray<NSString *> * _Nonnull)urlLists
                    progress:(TTDownloadProgressBlock _Nonnull )progress
                      status:(TTDownloadResultBlock _Nonnull )status
              userParameters:(DownloadGlobalParameters * _Nonnull)userParameters;

/**
 *  Cancel a task Asynchronously.Abandoned interface.Please use cancelTaskAsyn instead.
 *
 *  @param urlKey               The key that download task's unique identification.
 */
- (void)cancelDownloadWithURL:(NSString * _Nonnull)urlKey;

/**
 *  Cancel a task asynchronously.
 *
 *  @param urlKey               The key that download task's unique identification.
 *
 *  @param block                The callback which report cancel result.It can be nil.
 */
- (void)cancelTaskAsync:(NSString * _Nonnull)urlKey block:(TTDownloadResultBlock _Nonnull )block;

/**
 *  Cancel a task synchronously.You must careful,if call it on main thread.
 *
 *  @param urlKey               The key that download task's unique identification.
 */
- (void)cancelTaskSync:(NSString * _Nonnull)urlKey;

/**
 *  Delete a task synchronously.You must careful,if call it on main thread.
 *
 *  @param urlKey               The key that download task's unique identification.
 */
- (BOOL)deleteTaskSync:(NSString * _Nonnull)urlKey;
/**
 *  Delete a task asynchronously.
 *
 *  @param urlKey               The key that download task's unique identification.
 */
- (void)deleteDownloadWithURL:(NSString * _Nonnull)urlKey
                  resultBlock:(TTDownloadResultBlock _Nonnull )resultBlock;

/**
 *  Query a task synchronously.
 *
 *  @param urlKey               The key that download task's unique identification.
 *
 *  @return                     DownloadInfo object with downloaded information.
 */
- (DownloadInfo *_Nullable)queryTaskInfoSync:(NSString * _Nonnull)urlKey;
/**
 *  Query a task asynchronously.
 *
 *  @param urlKey               The key that download task's unique identification.
 *  @param downloadInfoBlock    The callback which report query result.
 *
 */
- (void)queryDownloadInfoWithURL:(NSString * _Nonnull)urlKey
               downloadInfoBlock:(TTDownloadInfoBlock _Nonnull )downloadInfoBlock;
/**
 *  Set maximum concurrency.
 *
 *  @param taskCount             maximum concurrency.
 *
 */
- (BOOL)setDownlodingTaskCountMax:(int16_t)taskCount;
/**
 *  Get maximum concurrency.
 */
- (int16_t)getDownlodingTaskCountMax;
/**
 * Set throttle of net speed.
 *
 * @param urlKey            The key that download task's unique identification.
 *
 * @param bytesPerSecond    The net speed you want to set.
 *                          if bytesPerSecond <= 0,will stop throttle.
 *                          if bytesPerSecond > 0,will start throttle.
 *                          Default value is 0.
 */
- (bool)setThrottleNetSpeedWithURL:(NSString * _Nonnull)urlKey bytesPerSecond:(int64_t)bytesPerSecond;
/**
 * Get the count of all of tasks.Including downloading and wait tasks.
 */
- (NSInteger)getAllTaskCount;
/**
 * Get the count of wait task.
 */
- (NSInteger)getQueueWaitTaskCount;
/**
 * This function maybe take more time.So please don't call it on main thread.
 */
- (BOOL)clearAllCache:(const ClearCacheType)type clearCacheKey:(const NSArray<NSString *> * _Nullable)list;

- (void)stopClearNoExpireCache;

- (int64_t)getAllCacheCount;

- (int64_t)getAllNoExpireTimeCacheCount;
/**
 * set whether wifiOnly for a specific task
 * if task is running under cellular net but isWifiOnly is set to YES, task will cancel
 */
- (void)setWifiOnlyWithUrlKey:(NSString * _Nonnull)urlKey isWifiOnly:(BOOL)isWifiOnly;

- (void)setIsForceCacheLifeTimeMaxEnable:(BOOL)enable;

@end
