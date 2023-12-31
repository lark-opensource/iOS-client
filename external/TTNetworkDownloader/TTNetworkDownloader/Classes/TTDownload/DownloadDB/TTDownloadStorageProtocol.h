#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ DownloadTaskResultBlock)(id downloadTaskConfig);
typedef void (^ AllDownloadTaskResultBlock)(NSMutableDictionary *allDownloadTaskConfig);

typedef void (^ DownloadTrackResultBlock)(id downloadTrackModel);
typedef void (^ AllDownloadTrackResultBlock)(NSMutableDictionary *allDownloadTrackModel);

@protocol TTDownloadStorageProtocol <NSObject>

#pragma mark - TTDownloadTaskConfig
/**
 * Query DownloadTaskConfig by url.
 */
- (BOOL)queryDownloadTaskConfigWithUrlSync:(NSString *)url
                   downloadTaskResultBlock:(DownloadTaskResultBlock)downloadTaskResultBlock
                                     error:(NSError **)error1;

/**
 * Get all of DownloadTaskConfig
 */
- (BOOL)queryAllDownloadTaskConfigSync:(AllDownloadTaskResultBlock)allDownloadTaskResultBlock
                                 error:(NSError **)error1;

/**
 * Insert DownloadTaskConfig
 */
- (BOOL)insertDownloadTaskConfigSync:(id)downloadTaskConfig
                               error:(NSError **)error1;

/**
 * Update DownloadTaskConfig
 */
- (BOOL)updateDownloadTaskConfigSync:(id)downloadTaskConfig
                               error:(NSError **)error1;

/**
 * Delete DownloadTaskConfig
 */
- (BOOL)deleteDownloadTaskConfigSync:(id)downloadTaskConfig
                               error:(NSError **)error1;

#pragma mark - DownloadTaskParameters
- (BOOL)updateParametersTable:(id)downloadTaskConfig
                        error:(NSError **)error1;

- (BOOL)updateExtendConfigSync:(id)taskConfig
                         error:(NSError **)error1;
#pragma mark - subSliceInfo
/**
 * Insert or update subslice information.
 */
- (BOOL)insertOrUpdateSubSliceInfo:(id)subSlice
                             error:(NSError **)error1;
/**
 *Delete subslice information.
 */
- (BOOL)deleteSubSliceInfo:(id)downloadTaskConfig
                     error:(NSError **)error1;

#pragma mark - sliceConfig
- (BOOL)updateSliceConfig:(id)sliceConfig sliceConfig:(id)taskConfig
                    error:(NSError **)error1;

#pragma mark - TTDownloadTrackModel

- (BOOL)queryDownloadTrackModelWithUrlMd5Sync:(NSString *)urlMd5
                     downloadTrackResultBlock:(DownloadTrackResultBlock)downloadTrackResultBlk
                                        error:(NSError **)error1;


- (BOOL)queryAllDownloadTrackModelSync:(AllDownloadTrackResultBlock)allDownloadTrackResultBlk
                                 error:(NSError **)error1;

- (BOOL)insertDownloadTrackModelSync:(id)downloadTrackModel
                               error:(NSError **)error1;

- (BOOL)updateDownloadTrackModelSync:(id)downloadTrackModel
                               error:(NSError **)error1;

- (BOOL)deleteDownloadTrackModelSync:(id)downloadTrackModel
                               error:(NSError **)error1;

- (BOOL)deleteDownloadTrackModelWithUrlMd5Sync:(NSString *)urlMd5
                                         error:(NSError **)error1;

#pragma mark - ClearCache
- (BOOL)insertOrUpdateClearCacheRule:(id)rule
                               error:(NSError **)error1;

- (BOOL)deleteClearCacheRule:(id)rule
                       error:(NSError **)error1;

- (NSMutableDictionary *)getAllClearCacheRule:(NSError **)error1;
@end

NS_ASSUME_NONNULL_END
