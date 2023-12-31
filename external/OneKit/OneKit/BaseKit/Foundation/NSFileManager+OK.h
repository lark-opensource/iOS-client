//
//  NSFileManager+OK.h
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 home => /var/mobile/Containers/Data/Application/XXX/
    - Documents => /var/mobile/Containers/Data/Application/XXX/Documents
    - Applications =>
    - Library =>
    - Library/Caches
 */

@interface NSFileManager (OK)

+ (NSString *)ok_homePath;
+ (NSString *)ok_cachePath;
+ (NSString *)ok_documentPath;
+ (NSString *)ok_libraryPath;

/// /private/var/containers/Bundle/Application/XXX/YYY.app
+ (NSString *)ok_mainBundlePath;

- (nullable NSURL *)ok_pathForNotificationFile:(NSString *)file group:(NSString *)group;

@end

NS_ASSUME_NONNULL_END
