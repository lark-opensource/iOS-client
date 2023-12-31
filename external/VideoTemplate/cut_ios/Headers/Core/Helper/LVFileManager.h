//
//  LVFileManager.h
//  LVTemplate
//
//  Created by lxp on 2020/2/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVFileManager : NSObject

+ (BOOL)fileExistsAtPath:(NSString *)filePath;

+ (BOOL)copyItemAtPath:(NSString *)sourceFilePath toPath:(NSString *)targetFilePath;

+ (BOOL)removeItemAtPath:(NSString *)filePath;

+ (NSArray<NSString *> *)contentsOfDirectoryAtPath:(NSString *)parentFilePath;

+ (BOOL)getAllocatedSize:(unsigned long long *)size ofDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)error;

#pragma MARK: - FileHash
+ (NSString * _Nullable)md5HashOfFileAtPath:(NSString *)filePath;
+ (NSString * _Nullable)sha1HashOfFileAtPath:(NSString *)filePath;
+ (NSString * _Nullable)sha512HashOfFileAtPath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
