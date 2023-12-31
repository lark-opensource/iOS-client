//
//  NSFileManager+OK.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "NSFileManager+OK.h"

@implementation NSFileManager (OK)

+ (NSString *)ok_homePath {
    static NSString *value = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       value = NSHomeDirectory();
    });
    
    return value;
}

+ (NSString *)ok_cachePath {
    static NSString *value = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
       value = [paths objectAtIndex:0];
    });
    
    return value;
}

+ (NSString *)ok_documentPath {
    static NSString *value = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
       value = [paths objectAtIndex:0];
    });
    
    return value;
}

+ (NSString *)ok_libraryPath {
    static NSString *value = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
       value = [paths objectAtIndex:0];
    });
    
    return value;
}

+ (NSString *)ok_mainBundlePath {
    return [[NSBundle mainBundle] bundlePath];
}

- (NSURL *)ok_pathForNotificationFile:(NSString *)file group:(NSString *)group {
    NSURL *containerURL = [self containerURLForSecurityApplicationGroupIdentifier:group];
    if (containerURL == nil) {
        return nil;
    }
    
    NSURL *sdkPath = [containerURL URLByAppendingPathComponent:@"Library/Notification" isDirectory:YES];
    BOOL isDir = NO;
    BOOL needCreate = NO;
    if ([self fileExistsAtPath:sdkPath.path isDirectory:&isDir]) {
        if (!isDir) {
            [self removeItemAtURL:sdkPath error:nil];
            needCreate = YES;
        }
    } else {
        needCreate = YES;
    }
    if (needCreate) {
        [self createDirectoryAtURL:sdkPath withIntermediateDirectories:YES attributes:nil error:nil];
        /// cost time
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [sdkPath setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
        });
    }
    
    return [sdkPath URLByAppendingPathComponent:file];
}

@end
