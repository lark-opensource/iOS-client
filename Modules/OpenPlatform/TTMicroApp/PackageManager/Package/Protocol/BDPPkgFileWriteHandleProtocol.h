//
//  BDPPkgFileWriteHandleProtocol.h
//  Timor
//
//  Created by 傅翔 on 2019/1/24.
//

#import "BDPPackageInfoManagerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class OPError;

/// 应用文件写入句柄协议
@protocol BDPPkgFileWriteHandleProtocol <NSObject>

@required

/// 开始下载前，判断是否需要重置文件
- (BOOL)shouldResetAppFileDataBeforeDownloadingWithLastFileOffset:(uint64_t)lastFileOffset;

/// 追加数据给writer"写入"(内存+IO缓存)
- (NSData *)writeAppFileData:(NSData *)data withTotalBytes:(int64_t)bytes parseError:(OPError **)parseError;

/// 追加数据给writer"写入"(内存+IO缓存)成功的事件通知
- (void)notifyToWriteAppFileDataSuccess;

/// 重置文件后的loadStatus
- (BDPPkgFileLoadStatus)loadStatusForResetFileHandleAndCache;

@end

NS_ASSUME_NONNULL_END
