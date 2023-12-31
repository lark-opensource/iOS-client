//
//  IESGurdBaseDownloadOperation.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/10.
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"
//model
#import "IESGeckoResourceModel.h"
#import "IESGurdDownloadInfoModel.h"
//manager
#import "IESGeckoResourceManager.h"
#import "IESGurdUpdateStatisticModel.h"

NS_ASSUME_NONNULL_BEGIN

@class IESGurdBaseDownloadOperation;
typedef void(^IESGurdDownloadOperationCompletion)(IESGurdBaseDownloadOperation *operation, BOOL isSuccessful, NSError * _Nullable error);

@interface IESGurdBaseDownloadOperation : NSOperation

@property (nonatomic, readonly, copy) NSString *accessKey;

@property (nonatomic, readonly, strong) IESGurdResourceModel *config;

@property (nonatomic, readonly, copy) IESGurdDownloadOperationCompletion downloadCompletion;

@property (atomic, readonly, assign) IESGurdDownloadPriority downloadPriority;

@property (nonatomic, readonly, strong) IESGurdDownloadInfoModel *downloadInfoModel;

@property (nonatomic, assign) BOOL retryDownload;


+ (instancetype)operationWithConfig:(IESGurdResourceModel *)config
                            logInfo:(NSDictionary *)logInfo
                 downloadCompletion:(IESGurdDownloadOperationCompletion)downloadCompletion;

- (void)updateDownloadPriority:(IESGurdDownloadPriority)downloadPriority;

#pragma mark - Subclass call

/**
 子类下载完成后调用
 */
- (void)handleDownloadResultWithDownloadInfo:(NSDictionary *)downloadInfo
                                     succeed:(BOOL)succeed
                                       error:(NSError * _Nullable)error;

/**
 子类下载成功后，处理md5检验、patch包合并等操作成功后调用
 */
- (void)handleBusinessSuccessWithPackagePath:(NSString *)packagePath
                                downloadSize:(uint64_t)downloadSize
                                downloadInfo:(NSDictionary *)downloadInfo;

/**
 子类下载成功后，处理逻辑失败后调用
 */
- (void)handleBusinessFailedWithType:(NSError *)error;

/**
 子类检查包md5
 */
- (BOOL)checkFileMd5WithPackagePath:(NSString *)packagePath
                                md5:(NSString *)md5
                  packageTypeString:(NSString *)packageTypeString
                  downloadURLString:(NSString *)downloadURLString
                       errorMessage:(NSString *_Nonnull *_Nonnull)errorMessage;

/**
 子类记录日志
 */
- (void)traceEventWithMessage:(NSString *)message hasError:(BOOL)hasError shouldLog:(BOOL)shouldLog;

#pragma mark - Subclass Override

/**
 子类重写自定义任务
 */
- (void)operationDidStart;

/**
 子类返回是否patch包
 */
- (BOOL)isPatch;

@end

NS_ASSUME_NONNULL_END
