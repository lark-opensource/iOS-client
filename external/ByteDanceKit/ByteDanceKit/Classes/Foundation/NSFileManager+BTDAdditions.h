//
//  NSFileManager+BTDAdditions.h
//  Aweme
//
//  Created by willorfang on 16/9/8.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (BTDAdditions)

/**

 @return 返回沙盒的各种路径
 */
+ (nonnull NSString *)btd_cachePath;
+ (nonnull NSString *)btd_libraryPath;
+ (nonnull NSString *)btd_documentPath;
/**

 @return 返回mainBundle路径
 */
+ (nonnull NSString *)btd_mainBundlePath;

/**
 计算文件大小

 @param filePath 文件路径
 @return 该路径下文件的大小
 */
+ (long long)btd_fileSizeAtPath:(nonnull NSString *)filePath;

/**
 计算文件夹里面文件的大小总和

 @param folderPath 文件夹路径
 @return 该文件夹下文件大小的总和
 */
+ (long long)btd_folderSizeAtPath:(nonnull NSString *)folderPath;

/**
 删除文件夹里面的所有文件

 @param folderPath 文件夹路径
 */
+ (void)btd_clearFolderAtPath:(nonnull NSString *)folderPath;

/**
 打印给定文件夹下文件总大小

 @param folderPath 文件夹路径
 */
+ (void)btd_printFolderDetailSizeAtPath:(nonnull NSString *)folderPath;

/**
 给定路径的所有文件夹的路径

 @param path 给定路径
 @return 返回所有文件夹的路径
 */
+ (nullable NSArray<NSString *> *)btd_allDirsInPath:(nonnull NSString *)path;

@end

NS_ASSUME_NONNULL_END
