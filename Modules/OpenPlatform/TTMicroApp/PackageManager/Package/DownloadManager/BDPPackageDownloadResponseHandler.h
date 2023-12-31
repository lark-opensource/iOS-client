//
//  BDPPackageDownloadResponseHandler.h
//  Timor
//
//  Created by houjihu on 2020/7/7.
//

#import <Foundation/Foundation.h>
#import "BDPPackageModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 单个代码包下载任务的回调
@interface BDPPackageDownloadResponseHandler : NSObject

/// 下载标识
@property (nonatomic, copy, readonly) NSString *identifier;
/// 开始下载回调
@property (nonatomic, copy, nullable, readonly) BDPPackageDownloaderBegunBlock begunBlock;
/// 下载进度回调
@property (nonatomic, copy, nullable, readonly) BDPPackageDownloaderProgressBlock progressBlock;
/// 下载完成回调
@property (nonatomic, copy, nullable, readonly) BDPPackageDownloaderCompletedBlock completedBlock;

/// 初始化方法
- (instancetype)initWithID:(NSString *)identifier
                begunBlock:(nullable BDPPackageDownloaderBegunBlock)begunBlock
             progressBlock:(nullable BDPPackageDownloaderProgressBlock)progressBlock
            completedBlock:(nullable BDPPackageDownloaderCompletedBlock)completedBlock;

@end

NS_ASSUME_NONNULL_END
