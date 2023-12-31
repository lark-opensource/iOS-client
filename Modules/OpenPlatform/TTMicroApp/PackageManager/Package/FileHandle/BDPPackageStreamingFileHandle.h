//
//  BDPPackageStreamingFileHandle.h
//  Timor
//
//  Created by houjihu on 2020/7/16.
//

#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>
#import "BDPPkgHeaderInfo.h"
#import "BDPPackageDownloadContext.h"

NS_ASSUME_NONNULL_BEGIN

/// 读取流式代码包文件。
/// 初始化对象时文件可能还没下载完，读文件时，先从包文件内读取文件索引
@interface BDPPackageStreamingFileHandle : NSObject <BDPPkgFileReadHandleProtocol>

/// 包管理所需上下文信息
@property (nonatomic, strong, readonly) BDPPackageContext *packageContext;

/** 是否为使用缓存meta下载的ttpkg */
@property(nonatomic, assign) BOOL usedCacheMeta;

/// 初始化，用于下载中
- (instancetype)initWithDownloadContext:(BDPPackageDownloadContext *)downloadContext;
/// 初始化，用于下载完成时
- (instancetype)initAfterDownloadedWithPackageContext:(BDPPackageContext *)packageContext;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 取消所有加载文件(包括音频文件)的完成回调blk
- (void)cancelAllReadDataCompletionBlks;

@end

NS_ASSUME_NONNULL_END
