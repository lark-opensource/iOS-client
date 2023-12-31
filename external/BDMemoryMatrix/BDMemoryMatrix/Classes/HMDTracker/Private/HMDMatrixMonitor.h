//
//  HMDMatrixMonitor.h
//  BDMemoryMatrix
//
//  Created by zhouyang11 on 2022/5/18.
//

#import <Foundation/Foundation.h>
#import <Heimdallr/HeimdallrModule.h>
#import "MMMemoryAdapter.h"
#import <Heimdallr/HMDAPPExitReasonDetectorProtocol.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HMDMemoryMatrixSupported) {
    /* 设备相关支持 */
    HMDMemoryMatrixSupportedIOSVersion = 1<<1, // iOS系统版本 >= 10.0
    HMDMemoryMatrixSupportedLimitDisk = 1<<2, // 磁盘空间限制
    /* Matrix启动条件 */
    HMDMemoryMatrixSupportedEnabled = HMDMemoryMatrixSupportedIOSVersion | HMDMemoryMatrixSupportedLimitDisk,
};

@interface HMDMatrixMonitor : HeimdallrModule<HMDAPPExitReasonDetectorProtocol,MMMemoryAdapterDelegate>

@property (nonatomic, strong) dispatch_queue_t uploadQueue;
@property (nonatomic, strong) dispatch_semaphore_t uploadSemaphore;
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString*, id> *filters;
@property (nonatomic, strong, nullable) NSMutableDictionary *sessionData;

+ (instancetype)sharedMonitor;
+ (NSString *)removableFileDirectoryPath;
+ (void)hmdMatrixSessionParamsTracker:(NSString * _Nonnull)rootPath customFilters:(NSString * _Nullable)customData paramsWriteToFileName:(NSString * _Nonnull)fileName;
@end

NS_ASSUME_NONNULL_END
