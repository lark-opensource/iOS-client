//
//  LVTemplateResourceDownloadOperation.h
//  Pods
//
//  Created by Chipengliu on 2020/5/27.
//

#import "LVResourceDownloadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVTemplateResourceDownloadOperation : NSOperation

/// 资源包 url
@property (nonatomic, copy, readonly) NSString *resourceUrlString;

/// 资源包在本地的存储路径
@property (nonatomic, copy, readonly) NSString *filePath;

/// 资源包的校验的md5
@property (nonatomic, copy) NSString *md5;

@property (nonatomic, copy, readonly) NSString *operationID;

/// 下载完成回调
@property (nonatomic, copy) void(^completionHandler)(NSString * _Nullable filePath, NSError * _Nullable error);

/// 进度回调
@property (nonatomic, copy) void(^progressHandler)(CGFloat progress);


- (instancetype)initWithTemplateSourceURLString:(NSString *)urlString
                                            md5:(NSString *)md5
                                       filePath:(NSString *)filePath;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
