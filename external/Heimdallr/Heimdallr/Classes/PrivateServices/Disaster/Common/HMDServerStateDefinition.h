//
//  HMDServerStateDefinition.h
//  Pods
//
//  Created by Nickyo on 2023/7/24.
//

#ifndef HMDServerStateDefinition_h
#define HMDServerStateDefinition_h

#import <Foundation/Foundation.h>

/// 上报类型
typedef NS_ENUM(NSUInteger, HMDReporter) {
    HMDReporterNone = 0,
    HMDReporterPerformance,
    HMDReporterOpenTrace,
    HMDReporterCloudCommandDebugReal,           /* 史前遗留接口, 现在没作用 */
    HMDReporterCloudCommandUpload,              /* 云控上传 */
    HMDReporterCloudCommandFetchCommand,        /* 云控拉下发的云控信息 */
    HMDReporterException,
    HMDReporterCrash,
    HMDReporterCrashEvent,
    HMDReporterUserException,
    HMDReporterALog,
    HMDReporterClassCoverage,
    HMDReporterMemoryGraph,
    HMDReporterEvilMethod
};

/// 容灾策略
typedef NS_ENUM(NSUInteger, HMDServerState) {
    /// 没有灾难，上报成功与否未知
    HMDServerStateUnknown     = 0,
    /// 没有灾难，上报成功
    HMDServerStateSuccess     = 1 << 0,
    /// 停止接收数据
    HMDServerStateDropData    = 1 << 1,
    /// 停止接收数据，且删除以前所有数据
    HMDServerStateDropAllData = 1 << 2,
    /// 重定向上报域名
    HMDServerStateRedirect    = 1 << 3,
    /// 触发避退策略
    HMDServerStateDelay       = 1 << 4,
    /// 服务端不接收数据；本地数据正常产生及保持；长避退策略
    HMDServerStateLongEscape  = 1 << 5,
};

#endif /* HMDServerStateDefinition_h */
