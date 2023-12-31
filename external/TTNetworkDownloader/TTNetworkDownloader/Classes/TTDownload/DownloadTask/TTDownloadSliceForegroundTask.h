#import "TTDownloadTask.h"
#import "TTDownloadSliceTask.h"

//@class TTDownloadSliceTask;
NS_ASSUME_NONNULL_BEGIN

typedef void(^PDDelayedBlockHandle)(BOOL cancel);

@interface TTDownloadSliceForegroundTask : TTDownloadSliceTask

@property (atomic, copy) TTDelayedBlockHandle startTaskDelayHandle;

- (id)initWhithSliceConfig:(TTDownloadSliceTaskConfig*)downloadSliceTaskConfig downloadTask:(TTDownloadTask*)downloadTask;

- (bool)setThrottleNetSpeed:(int64_t)bytesPerSecond;

- (void)clearReferenceCount;

- (void)setRestartImmediately;
@end

NS_ASSUME_NONNULL_END
