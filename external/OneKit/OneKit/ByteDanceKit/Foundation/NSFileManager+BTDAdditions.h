//
//  NSFileManager+BTDAdditions.h
//  Aweme
//
//  Created by willorfang on 16/9/8.
//  Copyright © 2016 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (BTDAdditions)

/**

 @return Return paths of the sand box.返回沙盒的各种路径
 */
+ (nonnull NSString *)btd_cachePath;
+ (nonnull NSString *)btd_libraryPath;
+ (nonnull NSString *)btd_documentPath;
/**

 @return Return the path of the mainBundle.
 */
+ (nonnull NSString *)btd_mainBundlePath;

/**
 Calculate the file size.

 @param filePath The file path.
 @return The file size of the file in the filePath.
 */
+ (long long)btd_fileSizeAtPath:(nonnull NSString *)filePath;

/**
 Calculate the folder size.

 @param folderPath The folder path.
 @return The sum of the sizes of the files in folderPath.
 */
+ (long long)btd_folderSizeAtPath:(nonnull NSString *)folderPath;

/**
 Clear all files in the folder.

 @param folderPath The folder path.
 */
+ (void)btd_clearFolderAtPath:(nonnull NSString *)folderPath;

/**
 Print the folder detail size.

 @param folderPath The folder path.
 */
+ (void)btd_printFolderDetailSizeAtPath:(nonnull NSString *)folderPath;

/**
 Return all paths of the dirs under the path.

 @param path The path.
 @return All paths of the dirs under the path.
 */
+ (nullable NSArray<NSString *> *)btd_allDirsInPath:(nonnull NSString *)path;

@end

NS_ASSUME_NONNULL_END
