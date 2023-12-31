//
//  BDPHttpDownloadTask+BrSupport.h
//  Timor
//
//  Created by annidy on 2019/11/12.
//


#import "BDPHttpDownloadTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPHttpDownloadTask (BrSupport)

/// 初始化brotli环境
/// @warning *Important:* 该方法可能未实现，调用前请先检查 +[BDPHttpDownloadTask isSupportBr] = YES
- (void)setupBrContext;

/// 释放brotli环境
/// @warning *Important:* 该方法可能未实现，调用前请先检查 +[BDPHttpDownloadTask isSupportBr] = YES
- (void)releaseBrContext;

/// 解压缩数据
/// @param chunk 流式数据
/// @return 解压后的数据。brotli未初始化返回nil
/// @warning *Important:* 该方法可能未实现，调用前请先检查 +[BDPHttpDownloadTask isSupportBr] = YES
- (NSData *)brDecode:(NSData *)chunk;

/// 是否支持Br解码
@property (class, readonly) BOOL isSupportBr;

@end

NS_ASSUME_NONNULL_END
