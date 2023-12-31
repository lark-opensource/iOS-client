//
//  BDPFileSystemHelper.h
//  Timor
//
//  Created by houjihu on 2020/3/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPFileSystemHelper : NSObject

#pragma mark - Utilities


+ (BOOL)removeFolderIfNeed:(NSString *)folderPath __attribute__((deprecated("Use API in FileSystem+LarkStorage.swift instead. This API will be removed in future releases.")));
+ (BOOL)createFolderIfNeed:(NSString *)folderPath __attribute__((deprecated("Use API in FileSystem+LarkStorage.swift instead. This API will be removed in future releases.")));

+ (long long)sizeWithPath:(NSString *)filePath __attribute__((deprecated("Use API in FileSystem+LarkStorage.swift instead. This API will be removed in future releases.")));

+ (void)clearFolderInBackground:(NSString *)folderPath __attribute__((deprecated("Use API in FileSystem+LarkStorage.swift instead. This API will be removed in future releases.")));

@end

NS_ASSUME_NONNULL_END
