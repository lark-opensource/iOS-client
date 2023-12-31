//
//  TTVideoEnginePlaySource.h
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/11.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineModelDef.h"
#import "TTVideoEngineNetClient.h"
#import "TTVideoEngineUtil.h"

#ifndef __DEBUG_ASSERT___
#define __DEBUG_ASSERT___
#define CODE_ERROR(condition) NSAssert(!(condition), @"Code execution path error");
#endif

NS_ASSUME_NONNULL_BEGIN

@class TTVideoEngineModel;
@class TTAVPreloaderItem;
@class TTVideoEngineURLInfo;
typedef NSString *(^ReturnStringBlock)(NSString *vid);
typedef NSInteger (^ReturnIntBlock)(NSString *vid);
typedef NSDictionary *(^ReturnDictonaryBlock)(NSString *vid);
typedef void(^FetchResult)(BOOL canFetch, TTVideoEngineModel *_Nullable videoModel, NSError *_Nullable error);

FOUNDATION_EXTERN NSString *const TTVideoEnginePlaySourceErrorUserCancelKey;
FOUNDATION_EXTERN NSString *const TTVideoEnginePlaySourceErrorStatusKey;
FOUNDATION_EXTERN NSString *const TTVideoEnginePlaySourceErrorRetryKey;
FOUNDATION_EXTERN NSString *const TTVideoEnginePlaySourceErrorDNSKey;

@protocol TTVideoEnginePlaySource <NSObject>

/// All method required
@required

/// Resolution map.
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> *resolutionMap;

/// Support all resolutions,  maybe nil.
- (nullable NSArray<NSNumber *> *)supportResolutions;
- (nullable NSArray<NSString *> *)supportQualityDesc;

/// The current resolution, maybe unknow.
- (TTVideoEngineResolutionType)currentResolution;

/// Auto resolution, switch resolution need. maybe unknow.
- (TTVideoEngineResolutionType)autoResolution;

/// The source id.
- (nullable NSString *)videoId;

/// Preload item.
- (nullable TTAVPreloaderItem *)preloadItem;

/// The url being used.
@property (nonatomic,   copy, readonly) NSString *_Nullable currentUrl;

/// Enable ssl, if YES try use ssl.
@property (nonatomic, assign, readonly) BOOL supportSSL;

/// Whether to support dash.
@property (nonatomic, assign, readonly) BOOL supportDash;

@property(nonatomic, assign, readonly) BOOL supportMP4;

@property(nonatomic, assign, readonly) BOOL supportHLS;

@property(nonatomic, assign, readonly) BOOL supportHLSSeamlessSwitch;

///  whether to support bash
@property(nonatomic, assign) BOOL supportBash;

/// Is it single url.
@property (nonatomic, assign, readonly) BOOL isSingleUrl;

/// Whether it is main url.
@property (nonatomic, assign, readonly) BOOL isMainUrl;

/// Whether it is live.
@property (nonatomic, assign, readonly) BOOL isLivePlayback;

/// Whether it is a local file.
@property (nonatomic, assign, readonly) BOOL isLocalFile;

/*video adaptive*/
@property(nonatomic, assign, readonly) BOOL enableAdaptive;


/// Get a url, resolution maybe unknow. Will auto change resolution when result is none.
- (nullable NSString *)urlForResolution:(TTVideoEngineResolutionType)resolution;

/// Get all urls, resolution must explicit. Will auto change resolution when result is none.
- (nullable NSArray<NSString *> *)allUrlsForResolution:(TTVideoEngineResolutionType *)resolution;

/// Using info data.
- (nullable TTVideoEngineURLInfo *)usingUrlInfo;

/// Urlinfo data.
- (nullable TTVideoEngineURLInfo *)urlInfoForResolution:(TTVideoEngineResolutionType)resolution mediaType:(NSString *)mediatype;

/* switch url info with data */
- (nullable TTVideoEngineURLInfo *)urlInfoForResolution:(TTVideoEngineResolutionType)resolution
                                              mediaType:(NSString *)mediatype
                                                 params:(NSDictionary *)params;

/// get videolist.
- (nullable NSArray<TTVideoEngineURLInfo *> *)getVideoList;

/// Extra info for proxy server.
- (nullable NSString *)proxyUrlExtraInfo;

- (nullable NSString *)getDynamicType;
/// Is it possible to get next url ?
- (BOOL)skipToNext;

/// Retry strategy
- (TTVideoEngineRetryStrategy)retryStrategyForRetryCount:(NSInteger)retryCount;

/// Cache media data need the key.
- (nullable NSString *)mediaFileKey;

/// The key of decryption.
- (nullable NSString *)decryptionKey;

- (nullable NSString *)spade_a;

//all source is have spadea
- (BOOL)isHaveSpadea;

/// Get the size of media.
- (NSInteger)videoSizeOfType:(TTVideoEngineResolutionType)resolution;

- (NSInteger)videoModelVersion;

- (BOOL)preloadDataIsExpire;

- (BOOL)validate;

- (BOOL)hasVideo;

- (CGFloat)getValueFloat:(int)key;

- (NSInteger)getValueInt:(NSInteger)key;

-(nullable NSString *)getValueStr:(int)key;

- (NSInteger)bitrateForDashSourceOfType:(TTVideoEngineResolutionType)resolution;

- (nullable NSString *)mediaFileHashOfType:(TTVideoEngineResolutionType)resolution;

- (nullable NSString *)checkInfo:(TTVideoEngineResolutionType)resolution;

- (NSInteger)currentUrlIndex;

- (nullable NSString *)refString;

- (nullable NSString *)decodingMode;

- (nullable NSString *)barrageMaskUrl;

- (nullable NSString *)aiBarrageUrl;

- (nullable NSArray *)subtitleInfos;

- (BOOL)hasEmbeddedSubtitle;

- (void)setParamMap:(NSDictionary *)params;
/// Need overwrite.
- (BOOL)isEqual:(id)object;

- (instancetype)deepCopy;

- (NSInteger)getDefaultAudioInfo;

/// MARK: - Need fetch video info

/// Is it can fetch data by video-id.
@property (nonatomic, assign, readonly) BOOL canFetch;

@property (nonatomic, strong) id<TTVideoEngineNetClient> netClient;

@property (nonatomic, assign) BOOL cacheVideoModelEnable;

@property (nonatomic, assign) BOOL useFallbackApi;

@property (nonatomic, assign) BOOL useEphemeralSession;

- (void)fetchUrlWithApiString:(ReturnStringBlock)apiString  /** api string */
                         auth:(ReturnStringBlock)authString /** auth string */
                       params:(ReturnDictonaryBlock)params  /** params */
                   apiVersion:(ReturnIntBlock)apiVersion
                       result:(FetchResult)result;

- (void)cancelFetch;

// the string needed by mem
- (NSString *)videoMemString;

@end

NS_ASSUME_NONNULL_END
