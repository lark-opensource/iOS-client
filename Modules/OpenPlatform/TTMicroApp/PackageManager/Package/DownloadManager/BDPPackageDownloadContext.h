//
//  BDPPackageDownloadContext.h
//  Timor
//
//  Created by houjihu on 2020/7/7.
//

#import <Foundation/Foundation.h>
#import "BDPPackageDownloadResponseHandler.h"
#import "BDPPackageInfoManagerProtocol.h"
#import "BDPPackageContext.h"

NS_ASSUME_NONNULL_BEGIN

/// 代码包下载任务上下文
@interface BDPPackageDownloadContext : NSObject

/// 下载标识
@property (nonatomic, copy) NSString *taskID;
/// 包管理上下文
@property (nonatomic, strong) BDPPackageContext *packageContext;
/// 下载回调集合，用于合并重复下载请求
@property (nonatomic, strong, nullable, readonly) NSMutableArray<BDPPackageDownloadResponseHandler *> *responseHandlers;
/// download file handle
@property (nonatomic, strong) NSFileHandle *fileHandle;
/// offset of download file handle
@property (nonatomic, assign) uint64_t originalFileOffset;
/// last written offset of download file handle
@property (nonatomic, assign) uint64_t lastFileOffset;
/// 加载状态
@property (nonatomic, assign) BDPPkgFileLoadStatus loadStatus;
/// 记录创建时的加载状态，用于外部判断是否统计时间
@property (nonatomic, assign) BDPPkgFileLoadStatus createLoadStatus;
/// 是否断点续传的下载
@property (nonatomic, assign) BOOL isDownloadRange;
/// 复用预下载任务
@property (nonatomic, assign) BOOL isReusePreload;

/// 初始化，用于下载完成时。未下载完成的场景，直接使用init进行初始化
- (instancetype)initAfterDownloadedWithPackageContext:(BDPPackageContext *)packageContext;

/// Add download responseHandler
- (void)addResponseHandler:(BDPPackageDownloadResponseHandler *)handler;

/// Remove download responseHandler
- (void)removeResponseHandler:(BDPPackageDownloadResponseHandler *)handler;

/// 计算标识下载任务的ID
+ (NSString *)taskIDWithUniqueID:(BDPUniqueID *)uniqueID packageName:(NSString *)packageName error:(OPError **)error;

@end

NS_ASSUME_NONNULL_END
