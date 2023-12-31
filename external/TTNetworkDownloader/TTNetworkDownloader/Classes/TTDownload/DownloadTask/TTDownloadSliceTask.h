
#import "TTDownloadSliceTask.h"
#import "TTDownloadSliceTaskConfig.h"
#import "TTDownloadTask.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SubTaskProtocol <NSObject>

- (void)start;

- (void)cancel;

- (void)clearReferenceCount;

@end

@interface TTDownloadSliceTask : NSObject<SubTaskProtocol>

@property (readonly, atomic, copy) NSString *urlKey;

@property (readonly, atomic, copy) NSString *secondUrl;

@property (readonly, atomic, copy) NSString *sliceStorageDir;

@property (atomic, assign) BOOL isTaskValid;


@property (atomic, weak) TTDownloadTask *downloadTask;

@property (atomic, strong) TTDownloadSubSliceInfo *currSubSliceInfo;

@property (atomic, strong) DownloadGlobalParameters *userParameters;

@property (atomic, strong) TTDownloadSliceTaskConfig *downloadSliceTaskConfig;

@end

NS_ASSUME_NONNULL_END
