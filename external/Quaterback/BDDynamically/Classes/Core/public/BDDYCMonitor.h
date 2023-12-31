//
//  BDDYCMonitor.h
//  BDDynamically
//
//  Created by jason on 2019/3/1.
//

#ifndef BDDYCMonitor_h
#define BDDYCMonitor_h

//

typedef NS_ENUM(NSInteger, kBDQuaterbackListDowmLoadStatus) {
    kBDDQuaterbackListDowmLoadStatusUnKnow = 0,
    kBDQuaterbackListDowmLoadStatusError = 1, //下载失败
    kBDQuaterbackListDowmLoadStatusSuccessAndPatchListNotEmpty,//下载成功且patch列表不为空
    kBDDQuaterbackListDowmLoadStatusSuccessButPatchListIsEmpty, //下载成功但是patch列表为空
};

typedef NS_ENUM(NSInteger, kBDQuaterbackWillClearPatchsStatus) {
    kBDQuaterbackWillClearPatchsStatusUpgradeAppVersion = 1,//升级版本清空本地patch
    kBDQuaterbackWillClearPatchsStatusPatchListIsEmpty,//下载patch列表为空时清空本地patch
    kBDQuaterbackWillClearPatchsStatusByCustomer,//业务方主动清空patch
};
/**
 Patch监控默认logType @"bitcode_patch_monitor"
 */
extern NSString *const kBDDYCQuaterbackMonitorLogType;

/**
 patch列表下载失败监控，默认ServiceName @"bitcode_patch_list_download_error_monitor"
 */
extern NSString *const kBDDYQuaterbackListDownloadStatusMonitorServiceName;

/**
  清空老版本本地ppatch列表
 */
extern NSString *const kBDDYCQuaterbackDidClearOldVersionQuaterbacksMonitorServiceName;

@protocol BDBDMonitorClass <NSObject>

+ (void)trackData:(NSDictionary *)data
       logTypeStr:(NSString *)logType;

+ (void)trackData:(NSDictionary *)data;

+ (void)trackService:(NSString *)serviceName
              status:(NSInteger)status
               extra:(NSDictionary *)extraValue;

+ (void)event:(NSString *)type
        label:(NSString *)label
    durations:(float)durations
needAggregate:(BOOL)needAggr;

+ (void)trackService:(nonnull NSString *)serviceName metric:(nullable NSDictionary <NSString *, NSNumber *> *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extraValue;

+ (void)setCustomFilterValue:(id)value forKey:(NSString *)key;
+ (void)setCustomContextValue:(id)value forKey:(NSString *)key;

+ (void)removeCustomFilterKey:(NSString *)key;

@end

////////////////////////////////////////////////////////////////////////////////

#ifdef __cplusplus
extern "C" {
#endif
    
    id<BDBDMonitorClass> BDDYCMonitorGet(void);
    
#ifdef __cplusplus
}
#endif

#endif /* BDDYCMonitor_h */
