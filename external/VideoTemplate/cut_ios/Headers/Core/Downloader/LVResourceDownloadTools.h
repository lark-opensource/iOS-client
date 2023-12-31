//
//  LVResourceDownloadTools.h
//  Pods
//
//  Created by kevin gao on 9/27/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LVDraftPayload;
@class LVResourceRequest;

@interface LVResourceDownloadTools : NSObject

+ (BOOL)fileExistsAtPath:(NSString *)filePath;

+ (BOOL)removeItemAtPath:(NSString *)filePath;

+ (BOOL)moveItemAtPath:(NSString *)sourceFilePath toPath:(NSString *)targetFilePath;

+ (BOOL)copyItemAtPath:(NSString *)sourceFilePath toPath:(NSString *)targetFilePath;

+ (NSArray<NSString *> *)contentsOfDirectoryAtPath:(NSString *)parentFilePath;

@end

@interface LVResourceDownloadTools (ResourceDownloadUpdate)

//修改资源存储路径 因为资源被使用MD5来命名存储了
+ (void)pathUpdate:(LVDraftPayload *)payload request:(LVResourceRequest*)request md5:(NSString *)resourceMD5;

@end

NS_ASSUME_NONNULL_END
