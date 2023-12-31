//
//  BDPPackageStreamingFileReadTask.h
//  Timor
//
//  Created by houjihu on 2020/7/16.
//

#import "BDPPkgHeaderInfo.h"
#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>

NS_ASSUME_NONNULL_BEGIN

/// 记录要读取的包文件信息任务
@interface BDPPackageStreamingFileReadTask : NSObject

/// 想要读取的文件路径
@property (nonatomic, copy) NSString *filePath;
/// 文件索引信息
@property (nonatomic, strong) BDPPkgFileIndexInfo *indexInfo;

/// 读取文件之后执行回调所在的dispatch queue
@property (nonatomic, strong) dispatch_queue_t queue;

/// 读取代码包文件数据之后的回调，调用优先级高于urlCompletedBlk
@property (nonatomic, copy) BDPPkgFileReadDataBlock dataCompletedBlk;
/// 读取代码包文件数据，写到单独文件之后的回调
@property (nonatomic, copy) BDPPkgFileReadURLBlock urlCompletedBlk;

/// 读取数据过程中的失败信息
@property (nonatomic, strong) NSError *error;

/// 读取数据后按顺序执行回调
@property (nonatomic, assign, getter=isInOrder) BOOL inOrder;

/** 记录是否尝试匹配过(即filePath去匹配indexModel) */
@property (nonatomic, assign) BOOL didMatchIndex;

/// 如果包已下载, 改成同步执行
@property (nonatomic, assign) BOOL syncIfDownloaded;
/// 下载完成后，且iesyncIfDownloaded为YES，则在当前线程同步执行回调
@property (nonatomic, assign) BOOL execSync;

@end

NS_ASSUME_NONNULL_END
