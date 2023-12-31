/*
 * MediaLoader
 *
 * Author:huangqing(huangqing.yangtze@bytedance.com)
 * Date:2018-10-25
 * Copyright (c) 2018 bytedance
 
 * This file is part of MediaLoader.
 *
 */
// version "1.1.108.101" 
#import <Foundation/Foundation.h>
#import "AVMDLCustomHttpDNSParser.h"

#if !defined(TARGET_OS_OSX)
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void (*mdl_alog_write_var_func_ptr) (const char *_filename, const char *_func_name, const char *_tag, int _level, int _line, const char * _format, ...);

@protocol AVMDLiOSURLFetcherListener <NSObject>
@required
- (void) onCompletion:(NSInteger)code
               rawkey:(NSString *)rawkey
              fileKey:(NSString *)fileKey
              newURLs:(NSArray<NSString *> *)newURLs;
@end

@protocol AVMDLiOSURLFetcherInterface <NSObject>
@required

- (NSInteger) start:(NSString *)rawKey
            fileKey:(NSString *)fileKey
             oldUrl:(NSString *)oldUrl
           listener:(id<AVMDLiOSURLFetcherListener>)listener;

- (NSArray<NSString *> *) getURLs;

- (void) close;
@end

@protocol AVMDLiOSFetcherMakerInterface <NSObject>

@required
- (id<AVMDLiOSURLFetcherInterface>) getFetcher:(NSString *)rawKey
                                       fileKey:(NSString *)fileKey
                                        oldURL:(NSString *)oldURL
                                      engineId:(NSString *)engineId;
@end

@interface AVMDLiOSURLFetcherBridge : NSObject <AVMDLiOSURLFetcherListener>
+ (id<AVMDLiOSFetcherMakerInterface>) getFetcherMaker;
+ (void)setFetcherMaker:(id<AVMDLiOSFetcherMakerInterface>)maker;
@end


@class AVMDLDataLoader;



@protocol AVMDLDataLoaderProtocol <NSObject>

- (void)didFinishTask:(NSString *)rawKey error:(NSError *)error;
- (void)logUpdate:(NSDictionary *)logDict;
- (void)testSpeedInfo:(long)timeInternalMs size:(long)sizeByte;
/// flag: 1,This time. ; 2,Has been cached completely before.
- (void)taskProgress:(NSString *)taskInfo taskType:(NSInteger)taskType flag:(NSInteger)flag;
- (void)preloadTaskCanceled:(NSString *)key;
- (void)taskOpened:(NSString *)key taskType:(NSInteger) taskType info:(NSDictionary *)info;
- (void)taskFailed:(NSString *)key taskType:(NSInteger)taskType error:(NSError *)error;
- (void)preloadEnd:(NSString *)taskInfo;
- (void)onCDNLog:(NSString *)log;
- (NSString*)getStringBykey:(NSString *)key code:(NSInteger)code type:(NSInteger)type;
- (void)testSpeedInfoByTime:(int64_t)timeInternalMs sizeByte:(int64_t)sizeByte type:(NSString *)type key:(NSString *)key extraInfoDic:(NSDictionary *)extraInfo info:(NSString *)info;
- (void)taskStateChange:(NSString *)taskKey taskType:(NSInteger)taskType state:(NSInteger)state;
- (NSString*)getCustomHttpHeader:(NSString *)url taskType:(NSInteger)taskType;
- (void)dataloader:(AVMDLDataLoader *)loader downloadProgress:(NSString *)info;
- (void)dataloader:(AVMDLDataLoader *)loader downloadSuspend:(NSString *)key;
- (void)onMultiNetworkSwitch:(NSString*) targetNetwork currentNetwork:(NSString *)currentNetwork;
@optional
- (void)taskCacheEnd:(NSString *)info;


@end

@class AVMDLDataLoaderConfigure;

@interface AVMDLDataLoader : NSObject
@property (nonatomic, weak) id<AVMDLDataLoaderProtocol> delegate;

///////////////////////////////////////////////////////////
///                        Module                      ////
///////////////////////////////////////////////////////////

/// Quick initialization
+ (instancetype)dataLoaderWithConfigure:(AVMDLDataLoaderConfigure *)configure;

/// Get AVMDLDataLoader SDK version
+ (NSString*)version DEPRECATED_MSG_ATTRIBUTE("Please use getVersion");

@property (nonatomic, assign) NSInteger preloadStrategy;
/**
 Designated initializer

 @return AVMDLDataLoader instance, Next you should call start:.
 */
+ (instancetype)shareInstance;

- (void)setConfigure:(AVMDLDataLoaderConfigure *)configure;

/**
 Configure object you set. It is valid to modify its properties before calling the start: method.
 */
@property(nonatomic, strong, readonly) AVMDLDataLoaderConfigure *configure;

/// NS_UNAVAILABLE
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Call first. start data loader.
 Synchronous execution.
 The environment needs to be initialized internally, and an error may occur in this process.

 @param error Maybe error.
 */
- (void)start:(NSError * _Nullable __autoreleasing *)error;

/**
 Stop data loader.
 */
- (void)stop;

/**
 Close data loader.
 Need to call this method when you are no longer using it.
 */
- (void)close;

/**
  Get string value by key
 */
- (NSString *)getStringValue:(int)key;

/**
 Get native medialoader protocol handle
 */
- (void*)getMdlProtocolHandle;


/// Get IOManager handle.
- (void *)getIOManagerHandle;

- (int) onNetworkIndex:(uint32_t)index;

- (int64_t)getUrlGenerator;

/**
 Set alog write callback
 */
- (void)setAlogWriteCallback:(mdl_alog_write_var_func_ptr)alog_ptr;

- (void)updateDNSInfo:(NSString* )host ipList:(NSString* )ipList expiredTime:(int64_t)expiredTime dnsType:(int)dnsType;

+ (NSString*) makeTsFileKey:(NSString*) masterKey Uri:(NSString*) tsAbsoluteUri;

-(void)setInt64ValueByKey:(NSInteger)key StrKey:(NSString*)strKey Value:(int64_t)value;

@end

///////////////////////////////////////////////////////////
///                      Task                          ////
///////////////////////////////////////////////////////////

@interface AVMDLTaskSpec : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *rawKey;
@property (nonatomic, copy) NSArray<NSString *> *urls;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *customHeader;
@property (nonatomic, assign) NSInteger taskType;
@property (nonatomic, copy) NSString *extrInfo;
@property (nonatomic, assign) NSInteger urlExpiredTime;

/**
 @param key Unique key.
 @param rawKey VideoId or extera info
 @param urls Input urls.
 */
- (instancetype)initWithKey:(NSString *)key
                     rawKey:(nullable NSString *)rawKey
                       urls:(NSArray<NSString *> *)urls;

@end

@interface AVMDLPlayTaskSpec : AVMDLTaskSpec

@property (nonatomic, assign) NSInteger fileType;
@property (nonatomic, assign) NSUInteger limitSize;
@property (nonatomic, assign) BOOL isNative;

@end

@interface AVMDLPreloadTaskSpec : AVMDLTaskSpec

@property (nonatomic, assign) NSInteger priorityLevel;
@property (nonatomic, assign) NSUInteger preloadOffset;
@property (nonatomic, assign) NSUInteger preloadSize;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *subtag;

@end

@interface AVMDLDataLoader (TaskAdditions)

- (nullable NSString*)generateUrlByTaskSpec:(AVMDLTaskSpec *)taskSpec;

- (nullable NSString*)preloadProxyUrlByKey:(NSString *)key
                                    rawKey:(nullable NSString *)rawKey
                               preloadSize:(NSUInteger)preloadSize
                                      urls:(NSArray<NSString *> *)urls
                                  filePath:(nullable NSString *)filePath
                                  priority:(NSInteger)priorityLevel
                                    header:(nullable NSString *)customHeader DEPRECATED_MSG_ATTRIBUTE("Please use generateUrlByTaskSpec:");

- (nullable NSString*)preloadProxyUrlByKey:(NSString *)key
                                    rawKey:(nullable NSString *)rawKey
                               preloadOffset:(NSUInteger)preloadOffset
                               preloadSize:(NSUInteger)preloadSize
                                      urls:(NSArray<NSString *> *)urls
                                  filePath:(nullable NSString *)filePath
                                  priority:(NSInteger)priorityLevel
                                    header:(nullable NSString *)customHeader DEPRECATED_MSG_ATTRIBUTE("Please use generateUrlByTaskSpec:");

/**
 Proxy url,The input source is some urls.
 Only when the key, urls is a valid value, and the module has called the start:, the returned value is valid.
 Here created a task, you need to use the same key call startTaskByKey:, start this task.
 If size == 0, will proload all data of the origin url.
 
 @param key Unique key.
 @param rawKey VideoId or extera info
 @param limitSize The size of cache file.
 @param urls Input urls.
 @return Proxy url.
 */
- (nullable NSString *)proxyUrlByKey:(NSString *)key
                              rawKey:(nullable NSString *)rawKey
                           limitSize:(NSUInteger)limitSize
                                urls:(NSArray<NSString *> *)urls
                            filePath:(nullable NSString *)filePath DEPRECATED_MSG_ATTRIBUTE("Please use generateUrlByTaskSpec:");

- (nullable NSString *)proxyUrlByKey:(NSString *)key
                              rawKey:(nullable NSString *)rawKey
                           limitSize:(NSUInteger)limitSize
                                urls:(NSArray<NSString *> *)urls
                            filePath:(nullable NSString *)filePath
                            fileType:(NSInteger)type DEPRECATED_MSG_ATTRIBUTE("Please use generateUrlByTaskSpec:");


- (nullable NSString *)downloadUrl:(NSString *)key
                            rawKey:(nullable NSString *)rawKey
                              urls:(NSArray<NSString *> *)urls DEPRECATED_MSG_ATTRIBUTE("Please use generateUrlByTaskSpec:");


- (void)startDownload:(NSString *)downloadUrl;

- (void)suspendDownloadByKey:(NSString *)key;

/**
 Proxy url,The input source is a single url.
 Only when the key, originUrl is a valid value, and the module has called the start:, the returned value is valid.
 Here created a task, you need to use the same key call startTaskByKey:, start this task.
 If size == 0, will proload all data of the origin url.
 
 @param key Unique key.
 @param rawKey VideoId or extera info
 @param size The size of proload.
 @param originUrl Origin url
 @param type video type,like hls, dash etc.
 @return Proxy url.
 */
- (nullable NSString*)proxyUrlByKey:(NSString *)key rawKey:(nullable NSString *)rawKey size:(NSUInteger)size url:(NSString *)originUrl type:(NSUInteger)type DEPRECATED_MSG_ATTRIBUTE("Please use generateUrlByTaskSpec:");


/**
    Proxy url
    @param key Unique key
    @param rawKey VideoId or extra info
    @param size The size of preload
    @param urls input urls
    @param type video type,like hls, dash etc.
    @return Proxy url
 */
- (nullable NSString*)proxyUrlByKey:(NSString *)key rawKey:(nullable NSString *)rawKey size:(NSUInteger)size urls:(NSArray<NSString *> *)urls type:(NSUInteger)type DEPRECATED_MSG_ATTRIBUTE("Please use generateUrlByTaskSpec:");


/**
 Start one task by key.

 @param key The unique key for the task.
 */
- (void)startTaskByKey:(NSString *)key;

/**
 Cancel one task by key.
 
 @param key The unique key for the task.
 */
- (void)cancelTaskByKey:(NSString *)key;

/**
 Cancel all tasks.
 */
- (void)cancelAll;

/**
 Cancel all idle preload task
 */
- (void)cancelAllIdle;

/**
 get cdnlog by filekey
 */
- (NSString*)getCDNLog:(NSString *)key;

/**
 get playlog by traceid
 */
- (NSString*)getPlayLog:(NSString *)traceId;

/**
 get preload traceid by rawkey(videoid)
 */
- (NSString*)getPreloadTraceId:(NSString *)rawKey;

/**
 reset preload traceid by rawkey(videoid)
 */
- (void)resetPreloadTraceId:(NSString *)rawKey;

@end

@interface AVMDLCopyOperation : NSObject

/**
 * destPath, absolute path with file name
 */
@property (nonnull, nonatomic, copy) NSString* destPath;

/**
 * filekey
 */
@property (nonnull, nonatomic, copy) NSString* fileKey;

/**
 * 如果正在下载过程如播放，是否等待下载完
 */
@property (nonatomic, assign) BOOL waitIfCaching;
@property (nonatomic, copy) void (^completionBlock)(BOOL isSuccess, NSError* _Nullable  err);

/**
 *
 */
@property (nonatomic, assign) BOOL forceCopy;
@property (nonatomic, copy) void (^infoBlock)(NSDictionary<NSString*, id>* info);

- (instancetype)initWithKey:(NSString *)key
                   destPath:(NSString *)path
            completionBlock:(void (^)(BOOL isSuccess, NSError* err))completionBlock;

- (instancetype)initWithKey:(NSString *)key
                   destPath:(NSString *)path
               waitIfCaching:(BOOL)waitIfCaching
            completionBlock:(void (^)(BOOL isSuccess, NSError* err))completionBlock;

@end

@interface AVMDLDataLoader (CacheManager)
/**
 Clear all cache data.
 */
- (void)clearAllCaches;

/**
 Force clear all cache data.
 */
- (void)forceClearAllCaches;

/**
 Remove the file disk cache by key.

 @param key the file hash.
 */
- (void)removeFileCacheByKey:(NSString *)key;

- (void)forceRemoveFileCacheByKey:(NSString *)key;

/**
 Get all cache data size.
 */
- (int64_t)getAllCacheSize;

/**
 get mdl version
 */
- (NSString *)getVersion;

/**
 Get cache size by a valid key.
 */
- (int64_t)getCacheSizeByKey:(NSString *)key;
- (void)cacheSizeByKey:(NSString *)key result:(void(^)(int64_t size))result;
- (int64_t)getCacheSize:(NSString *)key filePath:(NSString *)filePath;
- (void)getCacheSize:(NSString *)key filePath:(NSString *)filePath result:(void (^)(int64_t))result;
- (int64_t)tryQuickGetCacheSizeByKey:(NSString *)key;

- (void)asyncCopy:(AVMDLCopyOperation *)operation;

-(void)preConnectByHost:(NSString *)host port:(int) port;

/// cacheSize,originSize,key,localFileUrl
- (nullable NSString *)getCacheFileInfo:(NSString *)key;
- (nullable NSString *)getCacheFileInfo:(NSString *)key filePath:(NSString *)filePath;

/** Mark whether the file is automatically deleted. */
- (void)setFileAutoDeleteFlag:(NSString *)key flag:(NSInteger)flag;

/// Clear dns data.
- (void)clearAllDNSCache;
/// Clear dns and socket cache
- (void)clearDNSAndSocketCache;
- (BOOL)switchToDefaultNetwork;

- (BOOL)switchToCellularNetwork;

@end

@interface AVMDLDataLoader (HTTPNDS)

+ (void)setUpDNSTTL:(NSInteger)ttl;

+ (void)setUpFirstDNSParseType:(NSInteger)type;

+ (void)setUpFirstDNSParseType:(NSInteger)firstType backup:(NSInteger)backupType;

+ (void)setUpDNSEnableParallel:(NSInteger)enableParallel;

+ (void)setUpDNSEnableRefresh:(NSInteger)enableRefresh;

+ (void)setUpBackupDNSParserWaitTime:(double)second;

+ (void)setCustomHttpDNS:(id<AVMDLCustomHttpDNSParser>)customHttpDNS;

@property (nonatomic, copy, class, null_resettable) NSString *dnsTTHostString;
@property (nonatomic, copy, class, null_resettable) NSString *dnsGoogleHostString;
@property (nonatomic, copy, class, null_resettable) NSString *dnsServerHostString;
@property (nonatomic, copy, class, null_resettable) NSString *testReachabilityHostString;

@end

@interface AVMDLDataLoader (Options)

- (void)setPreloadParallelNum:(NSInteger)preloadParallelNum;
- (void)suspendPreconnect;
- (void)resumePreconnect;
- (void)setSocketTrainingCenterConfigStr:(NSString*) config;
- (void)setNetSchedulerConfigStr:(NSString*) config;

@end

@interface AVMDLDataLoader (Experiment)
// Experiment API not stable

+ (void)setNetUnReachableStopRetry:(BOOL) retry;

@end

/// MARK: - Configure

@interface AVMDLDataLoaderConfigure : NSObject

/**
 Default configure object
 
    maxCacheSize    : 100M
    openTimeOut     : 5s
    rwTimeOut       : 5s
    tryCount        : 3 times
    cachDirectory   : ../Cache/md5(@"avmdl_default_file_dir")

 @return Default instance.
 */
+ (instancetype)defaultConfigure;

/// The max cache data size.
@property(nonatomic, assign) NSInteger maxCacheSize;
/// TCP establishment time.
@property(nonatomic, assign) NSInteger openTimeOut;
/// TCP read write time.
@property(nonatomic, assign) NSInteger rwTimeOut;
/// Error occurred, number of retries.
@property(nonatomic, assign) NSInteger tryCount;
/// Error occurred, number of retries.
@property(nonatomic, assign) NSInteger preloadParallelNum;
/// enable extern dns.
@property(nonatomic, assign) NSInteger isEnableExternDNS;
/// is enable socket reuse.
@property(nonatomic, assign) NSInteger isEnableSoccketReuse;
/// socket idle timeout.
@property(nonatomic, assign) NSInteger socketIdleTimeout;
/// checksumlevel.
@property(nonatomic, assign) NSInteger checksumLevel;
/// The longest time that cached data exists. unit is second.
@property(nonatomic, assign) NSInteger maxCacheAge;
/// The Cache data folder.
@property(nonatomic,   copy) NSString *cachDirectory;
// enable lazy buffer pool
@property(nonatomic, assign) NSInteger isEnableLazyBufferpool;
// ringbuffer
@property(nonatomic, assign) NSInteger ringBufferSize;
///auth player request
@property(nonatomic, assign) NSInteger isEnableAuth;
@property(nonatomic,   copy) NSString *downloadDir;
@property(nonatomic,   copy) NSString *mdlExtensionOpts;
@property(nonatomic, assign) NSInteger writeFileNotifyIntervalMS;
@property(nonatomic, assign) NSInteger forbidByPassCookie;
@property(nonatomic, assign) NSInteger enablePreconnect;
@property(nonatomic, assign) NSInteger preconnectNum;
@property(nonatomic, assign) NSInteger testSpeedVersion;
@property(nonatomic, assign) NSInteger isEnableLoaderPreempt;
@property(nonatomic, assign) NSInteger nextDownloadThreshold;
@property(nonatomic, assign) NSInteger accessCheckLevel;
@property(nonatomic, assign) NSInteger isEnableSessionReuse;
@property(nonatomic, assign) NSInteger maxTlsVersion;
@property(nonatomic, assign) NSInteger sessionTimeout;
@property(nonatomic, assign) NSInteger maxIPV4Count;
@property(nonatomic, assign) NSInteger maxIPV6Count;

@property(nonatomic, assign) NSInteger isEnableNewBufferpool;
@property(nonatomic, assign) NSInteger newBufferpoolBlockSize;
@property(nonatomic, assign) NSInteger newBufferpoolResidentSize;
@property(nonatomic, assign) NSInteger newBufferpoolGrowBlockCount;

@property(nonatomic, assign) NSInteger isEnableAlog;
@property(nonatomic, assign) NSInteger isEnableCacheReqRange;
@property(nonatomic, assign) NSInteger isEnablePlayLog;
@property(nonatomic, assign) NSInteger isAllowTryTheLastUrl;
@property(nonatomic, assign) NSInteger isEnableFileExtendBuffer;
@property(nonatomic, assign) NSInteger isEnableIOManager;

@property(nonatomic, assign) NSInteger isEnableNetScheduler;
@property(nonatomic, assign) NSInteger isNetSchedulerBlockAllNetErr;
@property(nonatomic, assign) NSInteger netSchedulerBlockErrCount;
@property(nonatomic, assign) NSInteger netSchedulerBlockDuration;
@property(nonatomic, assign) NSInteger netSchedulerBlockHostErrIpCount;
@property(nonatomic, assign) BOOL isEnableLocalDNSThreadOptimize;
@property(nonatomic, assign) NSInteger connectPoolStragetyValue;
@property(nonatomic, assign) NSInteger maxAliveHostNum;
@property(nonatomic, assign) NSInteger maxSocketReuseCount;
@property(nonatomic, assign) NSInteger fileExtendSizeKB;
@property(nonatomic, assign) NSInteger isEnableFixCancelPreload;
@property(nonatomic, assign) BOOL isEnableDNSNoLockNotify;
@property(nonatomic, assign) NSInteger isEnableEarlyData;
@property(nonatomic, copy) NSString *socketTrainingCenterConfigStr;
@property(nonatomic, copy) NSString *netSchedulerConfigStr;
@property(nonatomic, copy) NSString *dynamicPreconnectConfigStr;
@property(nonatomic, copy) NSString *temporaryOptStr;
@property(nonatomic, copy) NSString *fileBufferOptStr;
@property(nonatomic, copy) NSString *customUA;
@property(nonatomic, copy) NSString *vendorTestId;
@property(nonatomic, copy) NSString *vendorGroupId;
//cache dir:limit_size_in_byte
@property(nonatomic, copy) NSDictionary<NSString*, NSNumber*>* cacheDirMaxCacheSize;
@property(nonatomic, assign) NSInteger mUseNewSpeedTestForSingle;
@property(nonatomic, assign) NSInteger socketRecvBufferSize;
@property (nonatomic, assign) BOOL isEnableReqWaitNetReachable;
@property (nonatomic, assign) BOOL isEnableNetworkChangeNotify;
@property(nonatomic, assign) BOOL isEnableMaxCacheAgeForAllDir;
@property(nonatomic, assign) NSInteger maxFileMemCacheSize;
@property(nonatomic, assign) NSInteger maxFileMemCacheNum;
@property(nonatomic, assign) BOOL isEnableCellularUp;
@property(nonatomic, assign) NSInteger loadMonitorTimeInternal;
@property(nonatomic, assign) NSInteger loadMonitorMinAllowLoadSize;
@property(nonatomic, assign) NSInteger loaderType;
@property(nonatomic, copy) NSString* appInfo;
@property(nonatomic, assign) NSInteger isEnableUseOriginalUrl;
@property(nonatomic, assign) BOOL isEnableLoaderLogExtractUrls;
@property(nonatomic, assign) NSInteger maxLoaderLogNum;
@property(nonatomic, assign) NSInteger threadStackSizeLevel;
@property(nonatomic, assign) BOOL isEnableUnLimitHttpHeader;
@property(nonatomic, assign) NSInteger enableThreadPoolCheckIdle;
@property(nonatomic, assign) NSInteger threadPoolIdleTTLSecond;
@property(nonatomic, assign) NSInteger threadPoolMinCount;
@property(nonatomic, assign) BOOL isEnableHls;
@property(nonatomic, assign) BOOL nonBlockRangeMode;
@property(nonatomic, assign) NSInteger nonBlockRnageMaxSizeKB;
@property(nonatomic, assign) NSInteger enableFileMutexOptimize;
@property(nonatomic, assign) BOOL isEnableMDL2;
@property(nonatomic, assign) NSInteger skipCdnUrlBeforeExpireSec;
@property(nonatomic, assign) NSInteger preloadTraceIdRecordMaxCnt;
@property(nonatomic, assign) BOOL ignoreTextSpeedTest;
@property(nonatomic, assign) BOOL isEnableOptimizeRange;



-(NSString *)cacheDirListStr;

@end
NS_ASSUME_NONNULL_END
