//
//  BDPPackageStreamingFileHandle+AsyncRead.h
//  Timor
//
//  Created by houjihu on 2020/7/16.
//

#import "BDPPackageStreamingFileHandle.h"
#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>
#import "BDPPackageStreamingFileReadTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPPackageStreamingFileHandle (AsyncRead) <BDPPkgFileAsyncReadHandleProtocol>

/// 添加读取任务
- (BOOL)tryAddReadTask:(BDPPackageStreamingFileReadTask *)task inDataTasks:(NSMutableArray **)dataTasks;

/// 处理读取任务
- (void)handleReadDataTaskWithTask:(BDPPackageStreamingFileReadTask *)task;


/// 头文件解析成功的事件处理
/// @param blk 需要在头文件解析成功后处理的逻辑
- (void)handleWhenHeaderReady:(dispatch_block_t)blk;

@end

NS_ASSUME_NONNULL_END
