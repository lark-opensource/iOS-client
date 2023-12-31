//
//  BDLImageLoaderProtocol.h
//  BDLynx
//
//  Created by annidy on 2020/3/29.
//

#ifndef BDLResourceLoaderProtocol_h
#define BDLResourceLoaderProtocol_h

@protocol BDLImageLoaderProtocol <NSObject>

@required

/// 检查是否能处理图片资源
/// @param url 请求的URL
/// @return 可以处理返回YES
- (BOOL)canRequestURL:(NSURL *_Nonnull)url;

/// 请求图片
/// @param url 图片URL
/// @param targetSize 目标图片大小
/// @param complete 完成回调

- (void)requestImage:(NSURL *_Nonnull)url
                size:(CGSize)targetSize
            complete:(nullable void (^)(UIImage *_Nonnull, NSError *__nullable))complete;

@end

#endif /* BDLResourceLoaderProtocol_h */
