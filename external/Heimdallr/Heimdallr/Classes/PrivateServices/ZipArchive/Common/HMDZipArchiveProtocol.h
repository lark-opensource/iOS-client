//
//  HMDZipArchiveProtocol.h
//  Heimdallr
//
//  Created by Nickyo on 2023/3/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HMDZipArchiveProtocol <NSObject>

/// 对指定的一组文件进行文件压缩
/// - Parameters:
///   - path: 压缩文件生成目标路径
///   - paths: 待压缩文件路径
+ (BOOL)createZipFileAtPath:(NSString *)path withFilesAtPaths:(NSArray<NSString *> *)paths;

/// 对指定的文件目录进行文件压缩
/// - Parameters:
///   - path: 压缩文件生成目标路径
///   - directoryPath: 待压缩文件目录
+ (BOOL)createZipFileAtPath:(NSString *)path withContentsOfDirectory:(NSString *)directoryPath;

@end

NS_ASSUME_NONNULL_END
