//
//  TTDownloadCommonTools.m
//  TTNetworkDownloader
//
//  Created by diweiguang on 2021/10/22.
//

#import <Foundation/Foundation.h>
#import <TTNetworkManager/TTNetworkUtil.h>
#import "TTDownloadCommonTools.h"
#import "TTDownloadLog.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kMergeTaskDownloadedFileBackupDir = @"TTMergeTaskDownloadedFileBackupDir";
static NSString * const kTTDownloadSystemDataDir = @"SystemData";
static NSString * const kTTDownloadLibraryDir = @"Library";
static NSString * const kTTDownloadSystemTmpDir = @"tmp";
static NSString * const kTTDownloadDocumentsDir = @"Documents";

@interface TTDownloadCommonTools()

@property(nonatomic, copy, readwrite)NSString *systemCacheDir;
@property(nonatomic, copy, readwrite)NSString *systemTempDir;
@property(nonatomic, copy, readwrite)NSString *systemLibraryDir;
@property(nonatomic, copy, readwrite)NSString *systemDocumentsDir;
@property(nonatomic, copy, readwrite)NSString *systemHomeDir;
@property(nonatomic, copy, readwrite)NSString *systemSysDataDir;

@end

@implementation TTDownloadCommonTools

+ (instancetype)shareInstance {
    static id singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (id)init {
    self = [super init];
    if (self) {
        _systemCacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        _systemTempDir = NSTemporaryDirectory();
        _systemLibraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
        _systemDocumentsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        _systemHomeDir = NSHomeDirectory();
    }
    return self;
}

+ (NSString *)calculateUrlMd5:(NSString *)url {
    if (nil == url) {
        return nil;
    }
    NSData* urlData = [url dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *urlMd5 = [[TTNetworkUtil md5Hex:urlData] lowercaseString];
    DLLOGD(@"dlLog:calculateUrlMd5:urlMd5=%@", urlMd5);
    return urlMd5;
}

+ (BOOL)createDir:(NSString *)dirPath error:(NSError **)error {
    if (!dirPath) {
        return NO;
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if (![manager fileExistsAtPath:dirPath]) {
        [manager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:error];
        if (*error) {
            DLLOGD(@"CreateDirectory Error：%@ %@ %@ path: %@", [*error localizedDescription], [*error localizedFailureReason], [*error localizedRecoverySuggestion], dirPath);
            return NO;
        }
    }
    return YES;
}

+ (BOOL)isDirectoryExist:(NSString *)directoryPath {
    BOOL isDir = NO;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir];
    return isExist && isDir;
}

+ (int64_t)getFileSize:(NSString *)filePath {
    NSError *error = nil;
    NSDictionary *fileAttributeDic = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if (error) {
        return -1;
    }
    return fileAttributeDic.fileSize;
}

+ (BOOL)deleteFile:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExits = [fileManager fileExistsAtPath:filePath];
    
    if (isExits) {
        NSError *error = nil;
        if (![fileManager removeItemAtPath:filePath error:&error]) {
            if (error) {
                DLLOGD(@"Delete File Error：%@ %@ %@", [error localizedDescription], [error localizedFailureReason], [error localizedRecoverySuggestion]);
                return NO;
            }
        }
    }
    return YES;
}

+ (BOOL)copyFile:(NSString *)srcPath
          toPath:(NSString *)toPath
     isOverwrite:(BOOL)isOverwrite
           error:(NSError **)error {
    
    if (!srcPath || !toPath) {
        return NO;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:srcPath]) {
        return NO;
    }

    if ([fileManager fileExistsAtPath:toPath]) {
        if (isOverwrite) {
            if (![fileManager removeItemAtPath:toPath error:error]) {
                return NO;
            }
        } else {
            return YES;
        }
    }

    if (![fileManager copyItemAtPath:srcPath toPath:toPath error:error]) {
        [fileManager removeItemAtPath:toPath error:nil];
        DLLOGD(@"copy failed,error=%@", (*error).description);
        return NO;
    }
    return YES;
}

+ (BOOL)isFileExist:(NSString *)filePath {
    BOOL isDir = YES;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
    return isExist && !isDir;
}

+ (StatusCode)checkDownloadPathValid:(NSString *)path {
    if (!path) {
        /**
         * If path is nil, we won't check.
         */
        return ERROR_USER_CHECK_PATH_SUCCESS;
    }
    
    if ([path hasSuffix:@"/"] || ([path stringByDeletingLastPathComponent].length <= 0)) {
        DLLOGE(@"Must input file Path!");
        return ERROR_USER_NO_VALID_FILE_PATH;
    }
    
    NSString *realPath = [self.class getUserRealFullPath:path];
    
    if (![self.class isDirectoryExist:[realPath stringByDeletingLastPathComponent]]) {
        return ERROR_USER_DIRECTORY_NOT_EXIST;
    } else if ([self.class isFileExist:realPath]) {
        return ERROR_USER_FILE_EXIST;
    }
    return ERROR_USER_CHECK_PATH_SUCCESS;
}

+ (NSString *)getUserRealFullPath:(NSString *)path {
    if (!path) {
        return nil;
    }
    if ([path hasPrefix:kTTDownloadLibraryDir]) {
        return [[TTDownloadCommonTools shareInstance].systemHomeDir stringByAppendingPathComponent:path];
    } else if ([path hasPrefix:kTTDownloadDocumentsDir]) {
        return [[TTDownloadCommonTools shareInstance].systemHomeDir stringByAppendingPathComponent:path];
    } else if ([path hasPrefix:kTTDownloadSystemTmpDir]) {
        return [[TTDownloadCommonTools shareInstance].systemHomeDir stringByAppendingPathComponent:path];
    } else if ([path hasPrefix:kTTDownloadSystemDataDir]) {
        return [[TTDownloadCommonTools shareInstance].systemHomeDir stringByAppendingPathComponent:path];
    }
    return nil;
}

@end
NS_ASSUME_NONNULL_END
