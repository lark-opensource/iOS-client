//
//  BDPPackageStreamingFileHandle+Workaround.h
//  Timor
//
//  Created by lixiaorui on 2020/7/28.
//

// 该文件为新版通用包管理流程FileReader适配层
// 目的是为了对齐BDPPkgFileReadHandleProtocol与BDPPkgFileReadHandleProtocol，以收敛外部实现的修改
// 新版通用包管理流程GA后该文件应该删掉，且外部对应方法也应该删掉
#import "BDPPkgFileBasicModel.h"
#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>
#import "BDPPackageStreamingFileHandle.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPPackageStreamingFileHandle (Workaround)

#pragma mark - 原BDPPkgFileReadHandleProtocol特有方法

/** 添加下载完成的回调. 如调用时已下载完成, 则会异步丢至main thread处理 */
- (void)addCompletedBlk:(void (^)(NSError *_Nullable error))completedBlk DEPRECATED_ATTRIBUTE;

/// 应用退出时打印日志，记录访问过的文件列表
- (void)appContainerWillBeClosed;

@end

NS_ASSUME_NONNULL_END
