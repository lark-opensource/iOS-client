#import "TTDownloadTaskConfig.h"
#import "TTDownloadSliceTaskConfig.h"

NS_ASSUME_NONNULL_BEGIN
@implementation TTDownloadTaskConfig

- (id)init {
    self = [super init];
    if (self) {
        self.downloadSliceTaskConfigArray = [[NSMutableArray alloc] init];
        self.isAutoRestore                = NO;
        self.userParam                    = nil;
        self.restoreTimesAuto             = 0;
        self.versionType                  = ADD_PARAMETERS_TABLE_VERSION;
    }
    return self;
}

- (void)clearUserBlock {
    self.resultBlock = nil;
    self.progressBlock = nil;
}

- (void)dealloc {
    DLLOGD(@"dlLog89:dealloc:file=%s ,function=%s", __FILE__, __FUNCTION__);
}

/**
 *Please call following function in non multithreaded environment
 */
- (int64_t)getTotalLength {
    int64_t totalLength = 0;

    for (TTDownloadSliceTaskConfig *sliceConfig in self.downloadSliceTaskConfigArray) {
        totalLength += sliceConfig.sliceTotalLength;
    }
    return totalLength;
}

@end

@implementation TTDownloadTaskExtendConfig

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (void)dealloc {
    DLLOGD(@"dlLog89:dealloc:file=%s ,function=%s", __FILE__, __FUNCTION__);
}

- (void)updateConfig:(NSString *)maxAge
        lastModified:(NSString *)lastModified
                etag:(NSString *)etag
   startDownloadTime:(NSString *)startDownloadTime
         componentId:(NSString *)componentId {
    self.maxAgeTime = maxAge;
    self.lastModifiedTime = lastModified;
    self.etag = etag;
    self.startDownloadTime = startDownloadTime;
    self.componentId = componentId;
}

@end
NS_ASSUME_NONNULL_END
