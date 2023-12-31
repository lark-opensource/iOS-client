//
//  BDPPackageCardInstaller.h
//  Timor
//
//  Created by houjihu on 2020/5/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 卡片安装
@interface BDPPackageCardInstaller : NSObject

/// 安装卡片
/// @param packageDirectoryPath 代码包存放目录
/// @param error 记录安装过程中的错误信息
+ (BOOL)installWithPackageDirectoryPath:(NSString *)packageDirectoryPath error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
