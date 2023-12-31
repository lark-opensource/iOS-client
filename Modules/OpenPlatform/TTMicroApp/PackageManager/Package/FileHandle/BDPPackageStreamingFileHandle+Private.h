//
//  BDPPackageStreamingFileHandle+Private.h
//  Timor
//
//  Created by houjihu on 2020/7/17.
//

#import "BDPPackageStreamingFileHandle.h"
#import "BDPAppLoadDefineHeader.h"
#import <OPFoundation/BDPMacroUtils.h>
#import "BDPPackageModuleProtocol.h"
#import "BDPPackageStreamingFileReadTask.h"
#import "BDPPkgDownloadTask.h"
#import "BDPPkgHeaderInfo.h"
#import "BDPPkgHeaderParser.h"
#import <OPFoundation/BDPQueue.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <OPFoundation/TMAMD5.h>

#define LOAD_TIMEOUT dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC)
static NSUInteger const MAX_FILE_RECORD_COUNT = 25;

/** 全局串行队列, 用于处理音频文件读写的任务 */
extern dispatch_queue_t BDPPackageStreamingFileHandleSerialQueue;

NS_ASSUME_NONNULL_BEGIN

@interface BDPPackageStreamingFileHandle ()

/// 下载上下文
@property (nonatomic, strong) BDPPackageDownloadContext *downloadContext;

/** Reader创建时间 */
@property (nonatomic, assign) NSTimeInterval createTime;

/// 下载并写入数据的串行队列
@property (nonatomic, strong) dispatch_queue_t serialQueue;

/// app包路径: xxx/tma/app/tt00a0000bc0000def/name/app.ttpkg
@property (nonatomic, copy, readonly) NSString *pkgPath;

/// 加载状态
@property (nonatomic, assign) BDPPkgFileLoadStatus loadStatus;
/// 记录创建时的加载状态，用于外部判断是否统计时间
@property (nonatomic, assign) BDPPkgFileLoadStatus createLoadStatus;

/// 流式包 文件描述信息(基础信息+各文件索引)
@property (nonatomic, strong) BDPPkgHeaderInfo *fileInfo;
/// 流式包 文件描述信息解析器
@property (nonatomic, strong) BDPPkgHeaderParser *parser;

/** 读取数据的任务队列. 必须「依次执行」回调 */
@property (nonatomic, strong) BDPQueue<BDPPackageStreamingFileReadTask *> *readDataTasksQueue;
/** 读取数据的任务集合. 「无回调顺序」要求 */
@property (nonatomic, strong) NSMutableSet<BDPPackageStreamingFileReadTask *> *readDataTasksSet;
/** 检查文件信息相关的Block(比如是否存在, 文件大小等). 在读取文件头完成后执行Block回调 */
@property (nonatomic, strong) BDPQueue<dispatch_block_t> *checkFileInfoBlkQueue;
/// read data tasks lock
@property (nonatomic, strong) NSRecursiveLock *readDataTasksLock;

/** 同步api的信号量, 增删改O(1). 用于读写数据 */
@property (nonatomic, strong) NSMutableSet<dispatch_semaphore_t> *syncApiSemaphores;
/** 除了自旋锁, 性能比pthread_mutex、递归锁好很多 */
@property (nonatomic, strong) dispatch_semaphore_t syncApiLock;

/// 记录请求过的文件集合
@property (nonatomic, strong) NSMutableSet<NSString *> *loadedFileNames;
/// 记录请求过的文件索引(index)和路径集合
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *fileRecords;
/// 记录文件请求顺序，从0依次递增
@property (nonatomic, assign) int8_t index;
/// last written offset of download file handle
@property (nonatomic, assign, readonly) uint64_t lastFileOffset;

#pragma mark - workaround

// 外部添加的进度回调
@property (nonatomic, strong) NSMutableArray<BDPPkgFileLoadProgressBlk> *downloadProgressBlks DEPRECATED_MSG_ATTRIBUTE("Workaround");

/// 基础信息，埋点用
@property (nonatomic, strong) BDPPkgFileBasicModel *basic DEPRECATED_MSG_ATTRIBUTE("Workaround");

#pragma mark - Helper

/// 在串行队列执行任务
- (void)executeSync:(BOOL)sync inSelfQueueOfBlk:(dispatch_block_t)blk;

@end

NS_ASSUME_NONNULL_END
