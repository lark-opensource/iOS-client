
#import "TTDownloadTask.h"

NS_ASSUME_NONNULL_BEGIN
@interface TTDownloadTaskExtendConfig : JSONModel

@property (atomic, copy) NSString *etag;
@property (atomic, copy) NSString *lastModifiedTime;
@property (atomic, copy) NSString *maxAgeTime;
@property (atomic, copy) NSString *startDownloadTime;
@property (atomic, copy) NSString *componentId;

- (void)updateConfig:(NSString *)maxAge
        lastModified:(NSString *)lastModified
                etag:(NSString *)etag
   startDownloadTime:(NSString *)startDownloadTime
         componentId:(NSString *)componentId;
@end

@class TTDownloadSliceTaskConfig;

@interface TTDownloadTaskConfig : NSObject

@property (atomic, copy) NSString *urlKey;

@property (atomic, copy) NSString *secondUrl;

@property (atomic, copy) NSString *fileStorageName;

@property (atomic, copy) NSString *fileStorageDir;

@property (atomic, assign) DownloadStatus downloadStatus;


@property (nonatomic, assign, nullable) NSDictionary *extraEventParams;


@property (atomic, strong) NSMutableArray<TTDownloadSliceTaskConfig *> * _Nonnull downloadSliceTaskConfigArray;

@property (nonatomic, copy) NSString *md5Value;
@property (nonatomic, assign) int8_t sliceTotalNeedDownload;

@property (nonatomic, assign) int8_t isSupportRange;

@property (atomic, assign) int8_t restoreTimesAuto;
@property (atomic, assign) BOOL isAutoRestore;

@property (atomic, assign) int16_t versionType;

@property (nonatomic, copy) TTDownloadProgressBlock progressBlock;
@property (nonatomic, copy) TTDownloadResultBlock  resultBlock;

@property (atomic, strong, nullable) DownloadGlobalParameters *userParam;

@property (atomic, strong) TTDownloadTaskExtendConfig *extendConfig;

- (void)clearUserBlock;

- (int64_t)getTotalLength;
@end
NS_ASSUME_NONNULL_END
