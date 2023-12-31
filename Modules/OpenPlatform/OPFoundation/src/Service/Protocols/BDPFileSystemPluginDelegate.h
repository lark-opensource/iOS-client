//
//  BDPFileSystemPluginDelegate.h
//  Pods
//
//  Created by houjihu on 2019/3/15.
//

#ifndef BDPFileSystemPluginDelegate_h
#define BDPFileSystemPluginDelegate_h

#import "BDPBasePluginDelegate.h"

/**
 * 跟文件系统相关的接口
 */
@protocol BDPFileSystemPluginDelegate <BDPBasePluginDelegate>

/// 存储小程序相关文件的顶级目录
- (NSString *)bdp_documentRootDirectoryWithCustomAccountToken:(NSString * _Nullable)accountToken;
/// 存储小程序相关文件的次级目录名
- (NSString *)accountTokenDirecrotyName;
@end


#endif /* BDPFileSystemPluginDelegate_h */
