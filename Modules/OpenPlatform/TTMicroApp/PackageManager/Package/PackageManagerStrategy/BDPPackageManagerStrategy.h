//
//  BDPPackageManagerStrategy.h
//  Timor
//
//  Created by houjihu on 2020/5/21.
//

#import <Foundation/Foundation.h>
#import "BDPPackageContext.h"
#import "BDPPackageDownloadContext.h"
#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>

NS_ASSUME_NONNULL_BEGIN

/// 包管理策略
@interface BDPPackageManagerStrategy : NSObject

/// 校验安装包
/// @param context 包管理所需上下文
/// @param packagePath 包保存地址
+ (BOOL)verifyPackageWithContext:(BDPPackageContext *)context packagePath:(NSString *)packagePath error:(NSError **)error;

/// 安装本地包
/// @param context 包管理所需上下文
/// @param packagePath 包保存地址
/// @param installPath 包安装地址
+ (BOOL)installPackageWithContext:(BDPPackageContext *)context packagePath:(NSString *)packagePath installPath:(NSString *)installPath error:(NSError **)error;
+ (BOOL)installPackageWithContext:(BDPPackageContext *)context packagePath:(NSString *)packagePath installPath:(NSString *)installPath isApplePie:(BOOL)isApplePie error:(NSError **)error;

/// 用于包下载完成后，加载包里的内容。此时不再依赖于下载中的任何信息
+ (id<BDPPkgFileManagerHandleProtocol>)packageReaderAfterDownloadedForPackageContext:(BDPPackageContext *)packageContext;

/// 用于包下载完成后，加载包里的内容
+ (id<BDPPkgFileManagerHandleProtocol>)packageReaderAfterDownloadedForPackageContext:(BDPPackageContext *)packageContext createLoadStatus:(BDPPkgFileLoadStatus)createLoadStatus;

/// 用于流式包下载过程中，加载包里的内容。非流式包在下载完成前会返回为nil
+ (nullable id<BDPPkgFileManagerHandleProtocol>)packageReaderForDownloadContext:(BDPPackageDownloadContext *)downloadContext;

/// 判断特定应用类型下的代码包目录名称是否需要删除。
/// 由于H5小程序与小程序的文件系统是复用的，因此删除文件夹时需要判断应用类型以及文件夹命名规则
+ (BOOL)shouldDeleteLocalPackageForAppType:(BDPType)appType packageName:(NSString *)packageName;

@end

NS_ASSUME_NONNULL_END
