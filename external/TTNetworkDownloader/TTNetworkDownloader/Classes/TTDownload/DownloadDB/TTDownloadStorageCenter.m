#import "TTClearCacheRule.h"
#import "TTDownloadStorageCenter.h"
#import "TTDownloadSqliteStorage.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TTDownloadStorageCenter {
    NSObject <TTDownloadStorageProtocol> *ttDTO;
}

- (id)initWithDownloadStorageImplType:(TTDownloadStorageImplType)impl {
    self = [super init];
    if (self) {
        switch (impl) {
            case TTDownloadStorageImplTypeSqlite:
                ttDTO = [[TTDownloadSqliteStorage alloc] init];
                break;
            default:
                ttDTO = [[TTDownloadSqliteStorage alloc] init];
                break;
        }
    }
    return self;
}

#pragma mark - TTDownloadTaskConfig

- (BOOL)queryDownloadTaskConfigWithUrlSync:(NSString *)url
                   downloadTaskResultBlock:(DownloadTaskResultBlock)downloadTaskResultBlock
                                     error:(NSError *__autoreleasing *)error1 {
    return [ttDTO queryDownloadTaskConfigWithUrlSync:url
                             downloadTaskResultBlock:downloadTaskResultBlock
                                               error:error1];
}

- (BOOL)queryAllDownloadTaskConfigSync:(AllDownloadTaskResultBlock)allDownloadTaskResultBlock
                                 error:(NSError *__autoreleasing *)error1 {
    return [ttDTO queryAllDownloadTaskConfigSync:allDownloadTaskResultBlock
                                           error:error1];
}

- (BOOL)insertDownloadTaskConfigSync:(id)downloadTaskConfig error:(NSError *__autoreleasing *)error1 {
    return [ttDTO insertDownloadTaskConfigSync:downloadTaskConfig error:error1];
}

- (BOOL)updateDownloadTaskConfigSync:(id)downloadTaskConfig error:(NSError *__autoreleasing *)error1 {
    return [ttDTO updateDownloadTaskConfigSync:downloadTaskConfig error:error1];
}

- (BOOL)deleteDownloadTaskConfigSync:(id)downloadTaskConfig error:(NSError *__autoreleasing *)error1 {
    return [ttDTO deleteDownloadTaskConfigSync:downloadTaskConfig error:error1];
}

#pragma mark - DownloadTaskParameters
- (BOOL)updateParametersTable:(id)downloadTaskConfig error:(NSError *__autoreleasing *)error1 {
    return [ttDTO updateParametersTable:downloadTaskConfig error:error1];
}

- (BOOL)updateExtendConfigSync:(id)taskConfig error:(NSError *__autoreleasing *)error1 {
    return [ttDTO updateExtendConfigSync:taskConfig error:error1];
}
#pragma mark - subSliceInfo
- (BOOL)insertOrUpdateSubSliceInfo:(id)subSlice error:(NSError *__autoreleasing *)error1 {
    return [ttDTO insertOrUpdateSubSliceInfo:subSlice error:error1];
}

- (BOOL)deleteSubSliceInfo:(id)downloadTaskConfig error:(NSError *__autoreleasing *)error1 {
    return [ttDTO deleteSubSliceInfo:downloadTaskConfig error:error1];
}
#pragma mark - sliceConfig
- (BOOL)updateSliceConfig:(id)sliceConfig sliceConfig:(id)taskConfig error:(NSError *__autoreleasing *)error1 {
    return [ttDTO updateSliceConfig:sliceConfig sliceConfig:taskConfig error:error1];
}

#pragma mark - TTDownloadTrackModel

- (BOOL)queryDownloadTrackModelWithUrlMd5Sync:(NSString *)urlMd5
                     downloadTrackResultBlock:(DownloadTrackResultBlock)downloadTrackResultBlk
                                        error:(NSError *__autoreleasing *)error1 {
    return [ttDTO queryDownloadTrackModelWithUrlMd5Sync:urlMd5
                               downloadTrackResultBlock:downloadTrackResultBlk
                                                  error:error1];
}

- (BOOL)queryAllDownloadTrackModelSync:(AllDownloadTrackResultBlock)allDownloadTrackResultBlk
                                 error:(NSError *__autoreleasing *)error1 {
    return [ttDTO queryAllDownloadTrackModelSync:allDownloadTrackResultBlk error:error1];
}

- (BOOL)insertDownloadTrackModelSync:(id)downloadTrackModel error:(NSError *__autoreleasing *)error1 {
    return [ttDTO insertDownloadTrackModelSync:downloadTrackModel error:error1];
}

- (BOOL)updateDownloadTrackModelSync:(id)downloadTrackModel error:(NSError *__autoreleasing *)error1 {
    return [ttDTO updateDownloadTrackModelSync:downloadTrackModel error:error1];
}

- (BOOL)deleteDownloadTrackModelSync:(id)downloadTrackModel error:(NSError *__autoreleasing *)error1 {
    return [ttDTO deleteDownloadTrackModelSync:downloadTrackModel error:error1];
}

- (BOOL)deleteDownloadTrackModelWithUrlMd5Sync:(NSString *)urlMd5 error:(NSError *__autoreleasing *)error1 {
    return [ttDTO deleteDownloadTrackModelWithUrlMd5Sync:urlMd5 error:error1];
}

#pragma mark - ClearCache
- (BOOL)insertOrUpdateClearCacheRule:(TTClearCacheRule *)rule error:(NSError *__autoreleasing *)error1 {
    return [ttDTO insertOrUpdateClearCacheRule:rule error:error1];
}

- (BOOL)deleteClearCacheRule:(TTClearCacheRule *)rule error:(NSError *__autoreleasing *)error1 {
    return [ttDTO deleteClearCacheRule:rule error:error1];
}

- (NSMutableDictionary<NSString *, TTClearCacheRule *> *)getAllClearCacheRule:(NSError *__autoreleasing *)error1 {
    return [ttDTO getAllClearCacheRule:error1];
}
@end

NS_ASSUME_NONNULL_END
