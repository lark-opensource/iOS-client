//
//  BDPPackageUncompressedFileHandle.h
//  Timor
//
//  Created by houjihu on 2020/7/16.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>
#import "BDPPackageDownloadContext.h"

NS_ASSUME_NONNULL_BEGIN

/// 读取已经解压好的代码包内的文件。
/// 初始化对象时需要已下载完，读文件时直接从文件夹中读取
@interface BDPPackageUncompressedFileHandle : NSObject <BDPPkgFileManagerHandleProtocol>

/// 包管理上下文
@property (nonatomic, strong, readonly) BDPPackageContext *packageContext;

/// 初始化
/// @param packageContext 包管理上下文
- (instancetype)initWithPackageContext:(BDPPackageContext *)packageContext;
/// 初始化
/// @param packageContext 包管理上下文
/// @param createLoadStatus 开始下载代码包时的下载状态
- (instancetype)initWithPackageContext:(BDPPackageContext *)packageContext createLoadStatus:(BDPPkgFileLoadStatus)createLoadStatus;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 获取代码包路径
- (NSString *)pkgDirPath;

@end

NS_ASSUME_NONNULL_END
