//
//  BDPPackageStreamingFileHandle+WriteHandle.h
//  Timor
//
//  Created by houjihu on 2020/7/17.
//

#import "BDPPackageStreamingFileHandle.h"
#import "BDPPkgFileWriteHandleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPPackageStreamingFileHandle (WriteHandle) <BDPPkgFileWriteHandleProtocol>

/// 读取文件头，用于开始下载前以及已下载需要返回可用的reader时
- (BDPPkgHeaderInfo *)readHeaderInfoWithLastFileOffset:(uint64_t)lastFileOffset;

/// 尝试处理读取数据任务
- (void)tryHandleReadDataTasks;

@end

NS_ASSUME_NONNULL_END
