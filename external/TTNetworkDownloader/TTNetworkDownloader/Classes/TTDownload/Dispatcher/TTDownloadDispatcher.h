#import "TTDownloadMetaData.h"
#import "TTDispatcherTask.h"

NS_ASSUME_NONNULL_BEGIN
@interface TTDownloadDispatcher : NSObject

- (BOOL)enqueue:(TTDispatcherTask *)task;

- (void)dequeue;

- (void)cancelTask:(TTDispatcherTask *)task;

- (void)deleteTask:(TTDispatcherTask *)task;

- (void)queryTask:(TTDispatcherTask *)task;

- (BOOL)setDownlodingTaskCountMax:(int8_t)taskCount;

- (int8_t)getDownlodingTaskCountMax;

- (size_t)getAllTaskCount;

- (size_t)getQueueWaitTaskCount;

- (BOOL)isResourceDownloading:(NSString *)urlKey;

- (BOOL)setWifiOnlyWithUrlKey:(NSString *)urlKey isWifiOnly:(BOOL)isWifiOnly;

@end
NS_ASSUME_NONNULL_END
