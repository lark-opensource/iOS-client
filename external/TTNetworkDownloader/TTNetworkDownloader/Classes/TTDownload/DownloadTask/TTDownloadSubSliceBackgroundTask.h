#import "TTDownloadSliceTask.h"
#import "TTDownloadManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTDownloadSubSliceBackgroundTask : TTDownloadSliceTask
- (id)initWhithSliceConfig:(TTDownloadSliceTaskConfig*)sliceConfig downloadTask:(TTDownloadTask *)downloadTask;

- (void)setInvaildForBgTask;
@end

NS_ASSUME_NONNULL_END
