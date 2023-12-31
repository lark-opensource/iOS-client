//
//  HMDLogUploader.h
//  Heimdallr
//
//  Created by joy on 2018/9/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    HMDAlogUploadSuccess = 0, // Alog主动上报成功
    HMDAlogUploadFailedAlogNotFount, // Alog主动上报失败，本地没有符合时间条件的alog
    HMDAlogUploadFailedRateLimit, // Alog主动上报失败，服务端限流
    HMDAlogUploadFailedServerUnavailable, // Alog主动上报失败，服务端容灾
    HMDAlogUploadFailedFileStopUploadByHost, // Alog主动上报失败，宿主禁止文件类型上报
    HMDAlogUploadFailedAlogStopUploadByHost, // Alog主动上报失败，宿主主动禁止alog上报
    HMDAlogUploadFailedCompressFailed, // Alog主动上报失败，压缩alog文件失败
    HMDAlogUploadFailedInstanceNameNil, // Alog主动上报失败，自定义实例名称为空
    HMDAlogUploadFailedOthers // Alog主动上报失败，其他原因，比如网络异常
} HMDAlogUploadStatus;

typedef void (^HMDReportALogCallback)(BOOL isSuccess, NSInteger fileCount);
typedef void (^HMDAlogUploadGlobalBlock)(NSTimeInterval fetchStartTime, NSTimeInterval fetchEndTime, NSString *scene, NSString *instanceName, NSInteger fileCount, HMDAlogUploadStatus status);

typedef BOOL (^HMDForbidAllowAlogUploadBlock)(NSString *scene);


@interface HMDLogUploader : NSObject

@property (nonatomic, assign) BOOL shouldUploadAlogIfCrashed;

@property (nonatomic, copy) HMDForbidAllowAlogUploadBlock _Nullable forbidAlogUploadBlock;
@property (nonatomic, copy) HMDAlogUploadGlobalBlock _Nullable uploadGlobalBlock;

+ (instancetype _Nonnull)sharedInstance;

#pragma mark - Report

/// 用户主动触发Alog上报专用接口，包含回调，⚠️只允许用户主动触发时使用
///
/// 此接口不受任何业务开关降级，但是仍然受Slardar服务端容灾降级影响
/// - Parameters:
///   - fetchStartTime: 上报Alog文件的起始时间
///   - fetchEndTime: 上报Alog文件的截止时间
///   - scene: 主动上报Alog的场景，直接在平台上展示
///   - reportALogBlock: Alog上报回调
- (void)reportALogByUsersWithFetchStartTime:(NSTimeInterval)fetchStartTime
                               fetchEndTime:(NSTimeInterval)fetchEndTime
                                      scene:(NSString * _Nonnull)scene
                         reportALogCallback:(HMDReportALogCallback _Nullable)reportALogBlock;

- (void)reportALogbyUsersWithFetchStartTime:(NSTimeInterval)fetchStartTime
                               fetchEndTime:(NSTimeInterval)fetchEndTime
                                      scene:(NSString * _Nonnull)scene
                         reportALogCallback:(nullable HMDReportALogCallback)reportALogBlock __attribute__((deprecated("please use reportALogByUsersWithFetchStartTime")));

/// 用户主动触发Alog上报专用接口，包含回调，⚠️只允许用户主动触发时使用
///
/// 此接口不受任何业务开关降级，但是仍然受Slardar服务端容灾降级影响
/// - Parameters:
///   - fetchStartTime: 上报Alog文件的起始时间
///   - fetchEndTime: 上报Alog文件的截止时间
///   - scene: 主动上报Alog的场景，直接在平台上展示
///   - param instanceName BDAlog实例名
///   - reportALogBlock: Alog上报回调
- (void)reportALogByUsersWithFetchStartTime:(NSTimeInterval)fetchStartTime
                               fetchEndTime:(NSTimeInterval)fetchEndTime
                                      scene:(NSString * _Nonnull)scene
                               instanceName:(NSString * _Nonnull)instanceName
                         reportALogCallback:(nullable HMDReportALogCallback)reportALogBlock;

/// 用户反馈Alog上报专用接口，包含回调，⚠️只允许用户反馈时上报alog使用
///
/// 此接口不受任何业务开关降级，但是仍然受Slardar服务端容灾降级影响
/// @param fetchStartTime 上报Alog文件的起始时间
/// @param fetchEndTime 上报Alog文件的截止时间
/// @param scene 主动上报Alog的场景，直接在平台上展示
/// @param reportALogBlock Alog上报回调
- (void)reportFeedbackALogWithFetchStartTime:(NSTimeInterval)fetchStartTime
                                fetchEndTime:(NSTimeInterval)fetchEndTime
                                       scene:(NSString * _Nonnull)scene
                          reportALogCallback:(HMDReportALogCallback _Nullable)reportALogBlock;

/// 用户反馈Alog上报专用接口，包含回调，⚠️只允许用户反馈时上报alog使用
///
/// 此接口不受任何业务开关降级，但是仍然受Slardar服务端容灾降级影响
/// @param fetchStartTime 上报Alog文件的起始时间
/// @param fetchEndTime 上报Alog文件的截止时间
/// @param scene 主动上报Alog的场景，直接在平台上展示
/// @param instanceName BDAlog实例名
/// @param reportALogBlock Alog上报回调
- (void)reportFeedbackALogWithFetchStartTime:(NSTimeInterval)fetchStartTime
                                fetchEndTime:(NSTimeInterval)fetchEndTime
                                       scene:(NSString * _Nonnull)scene
                                instanceName:(NSString * _Nonnull)instanceName
                          reportALogCallback:(nullable HMDReportALogCallback)reportALogBlock;

/// 客户端Alog主动上报接口，不包含回调
/// @param fetchStartTime 上报Alog文件的起始时间
/// @param fetchEndTime 上报Alog文件的截止时间
/// @param scene 主动上报Alog的场景，直接在平台上展示，如"崩溃"
- (void)reportALogWithFetchStartTime:(NSTimeInterval)fetchStartTime
                        fetchEndTime:(NSTimeInterval)fetchEndTime
                               scene:(NSString * _Nonnull)scene;

/// 客户端Alog主动上报接口，包含回调
/// @param fetchStartTime 上报Alog文件的起始时间
/// @param fetchEndTime 上报Alog文件的截止时间
/// @param scene 主动上报Alog的场景，直接在平台上展示，如"崩溃"
/// @param reportALogBlock Alog上报回调
- (void)reportALogWithFetchStartTime:(NSTimeInterval)fetchStartTime
                        fetchEndTime:(NSTimeInterval)fetchEndTime
                               scene:(NSString * _Nonnull)scene
                  reportALogCallback:(HMDReportALogCallback _Nullable)reportALogBlock;

/// 客户端Alog主动上报接口，包含回调
/// @param fetchStartTime 上报Alog文件的起始时间
/// @param fetchEndTime 上报Alog文件的截止时间
/// @param scene 主动上报Alog的场景，直接在平台上展示，如"崩溃"
/// @param instanceName BDAlog实例名
/// @param reportALogBlock Alog上报回调
- (void)reportALogWithFetchStartTime:(NSTimeInterval)fetchStartTime
                        fetchEndTime:(NSTimeInterval)fetchEndTime
                               scene:(NSString * _Nonnull)scene
                        instanceName:(NSString * _Nonnull)instanceName
                  reportALogCallback:(HMDReportALogCallback _Nullable)reportALogBlock;

#pragma mark - Upload

/// 用户反馈Alog上报专用接口, 上报指定的截止时间之前的最后一个Alog, ⚠️只允许用户反馈时上报alog使用
///
/// 此接口不受任何开关降级
/// @param endTime 指定的截止时间戳
- (void)uploadLastFeedbackAlogBeforeTime:(NSTimeInterval)endTime;

/// 用户反馈Alog上报专用接口, 上报指定的截止时间之前的最后一个Alog, ⚠️只允许用户反馈时上报alog使用
///
/// 此接口不受任何开关降级
/// @param endTime 指定的截止时间戳
/// @param instanceName BDAlog实例名
- (void)uploadLastFeedbackAlogBeforeTime:(NSTimeInterval)endTime instanceName:(NSString * _Nonnull)instanceName;

/// 仅上报指定的截止时间之前的最后一个Alog
/// @param endTime 指定的截止时间戳
- (void)uploadLastAlogBeforeTime:(NSTimeInterval)endTime;

/// 仅上报指定的截止时间之前的最后一个Alog
/// @param endTime 指定的截止时间戳
/// @param instanceName BDAlog实例名
- (void)uploadLastAlogBeforeTime:(NSTimeInterval)endTime instanceName:(NSString * _Nonnull)instanceName;

/// 当发生Crash的时候自动上报Alog
- (void)uploadAlogIfCrashed;

/**
 * 当发生Crash的时候自动上报Alog
 * @param second 可自定义上报crash发生前多长时间的alog文件，单位秒；
 */
- (void)uploadAlogIfCrashedWithTime:(NSUInteger)second;


@end

NS_ASSUME_NONNULL_END
