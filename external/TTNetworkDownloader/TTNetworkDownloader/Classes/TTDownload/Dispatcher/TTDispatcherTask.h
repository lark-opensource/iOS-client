#import "TTDownloadMetaData.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^DoWork)(DownloadGlobalParameters *);
typedef void (^QueryWork)(DownloadStatus status);

@interface TTDispatcherTask : NSObject

@property (atomic, copy) NSString *urlKey;

@property (atomic, assign) BOOL isDeleted;

@property (atomic, strong) DownloadGlobalParameters *userParameters;

@property (atomic, copy) DoWork onRealTask;

@property (atomic, copy) QueryWork onRealQueryTask;

@property (atomic, copy) TTDownloadResultBlock resultBlock;

- (void)executeAllResultBlock:(DownloadResultNotification *)notification;

- (void)addResultBlock:(TTDispatcherTask *)task;

@end

NS_ASSUME_NONNULL_END
