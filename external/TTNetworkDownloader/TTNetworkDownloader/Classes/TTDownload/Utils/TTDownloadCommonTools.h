//
//  CommonTools.h
//  Pods
//
//  Created by diweiguang on 2021/10/22.
//

#ifndef TTDownloadCommonTools_h
#define TTDownloadCommonTools_h

#import "TTDownloadMetaData.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kMergeTaskDownloadedFileBackupDir;

@interface TTDownloadCommonTools : NSObject

@property(nonatomic, copy, readonly)NSString *systemCacheDir;
@property(nonatomic, copy, readonly)NSString *systemTempDir;
@property(nonatomic, copy, readonly)NSString *systemLibraryDir;
@property(nonatomic, copy, readonly)NSString *systemDocumentsDir;
@property(nonatomic, copy, readonly)NSString *systemSysDataDir;

+ (instancetype)shareInstance;

+ (NSString *)calculateUrlMd5:(NSString *)url;

+ (BOOL)createDir:(NSString *)dirPath error:(NSError **)error;

+ (BOOL)isDirectoryExist:(NSString *)directoryPath;

+ (int64_t)getFileSize:(NSString *)filePath;

+ (BOOL)deleteFile:(NSString *)filePath;

+ (BOOL)copyFile:(NSString *)srcPath
          toPath:(NSString *)toPath
     isOverwrite:(BOOL)isOverwrite
           error:(NSError **)error;

+ (BOOL)isFileExist:(NSString *)filePath;

+ (StatusCode)checkDownloadPathValid:(NSString *)path;

+ (NSString *)getUserRealFullPath:(NSString *)path;
@end
NS_ASSUME_NONNULL_END
#endif /* TTDownloadCommonTools_h */
