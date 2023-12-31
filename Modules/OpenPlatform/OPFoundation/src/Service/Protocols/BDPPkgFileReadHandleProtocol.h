//
//  BDPPkgFileReadHandleProtocol.h
//  Timor
//
//  Created by 傅翔 on 2019/1/24.
//

#import <Foundation/Foundation.h>

@class BDPPkgFileBasicModel;

/// FROM: TTMicroApp, PackageManager BDPPackageInfoManagerProtocol.h
/// 代码包下载状态
typedef NS_ENUM(NSInteger, BDPPkgFileLoadStatus) {
    BDPPkgFileLoadStatusUnknown = -1,
    /** 缺少文件描述(未开始下载或才开始)。
     用于流式下载，在文件头下载完成后切换为downloading。
     针对非流式包，开始下载后直接切换为downloading。
     */
    BDPPkgFileLoadStatusNoFileInfo,
    /** 文件下载中 */
    BDPPkgFileLoadStatusDownloading,
    /** 文件下载已下载 */
    BDPPkgFileLoadStatusDownloaded
};

#define BDP_PKG_OLD_VERSION 1

@protocol BDPPkgFileReadHandleProtocol, BDPPkgFileManagerHandleProtocol, BDPPkgFileAsyncReadHandleProtocol;
typedef id<BDPPkgFileReadHandleProtocol> BDPPkgFileReader;

NS_ASSUME_NONNULL_BEGIN

/** 获取NSData内容的Blk. pkgName用于校验回调是否为相应文件的 */
typedef void (^BDPPkgFileReadDataBlock)(NSError *_Nullable error, NSString *pkgName, NSData *_Nullable data);
/** 支持获取chunk数据的blk */
typedef void (^BDPPkgFileReadChunkDataBlock)(NSError *_Nullable error, NSString *pkgName, NSData *_Nullable data, uint64_t totalBytes, BOOL finished);
/** 获取需要写成单个文件的file的Blk, 返回fileURL. pkgName用于校验回调是否为相应文件的 */
typedef void (^BDPPkgFileReadURLBlock)(NSError *_Nullable error, NSString *pkgName, NSURL *_Nullable fileURL);
/** 文件加载进度回调 */
typedef void (^BDPPkgFileLoadProgressBlk)(float progress);


/** 小程序文件读取句柄协议 */
@protocol BDPPkgFileReadHandleProtocol <BDPPkgFileManagerHandleProtocol>

/** 是否为使用缓存meta下载的ttpkg */
@property(nonatomic, assign) BOOL usedCacheMeta;

/** 基础信息 */
- (BDPPkgFileBasicModel *)basic;

/** 添加下载完成的回调. 如调用时已下载完成, 则会异步丢至main thread处理 */
- (void)addCompletedBlk:(void (^)(NSError *_Nullable error))completedBlk;

/** 应用容器将关闭 */
- (void)appContainerWillBeClosed;

@end

#pragma mark async read

/// 异步加载Api
@protocol BDPPkgFileAsyncReadHandleProtocol <NSObject>

/// 当前加载状态
- (BDPPkgFileLoadStatus)loadStatus;

/** 创建时的加载状态, 如果为0说明之前不存在, 刚开始下载 */
- (BDPPkgFileLoadStatus)createLoadStatus;

/** 取消所有加载文件(包括音频文件)的完成回调blk */
- (void)cancelAllReadDataCompletionBlks;

/** 文件是否存在包内 */
- (void)checkExistedFileInPkg:(NSString *)filePath withCompletion:(void (^)(BOOL existed))completion;

/** 获取文件大小, 若不存在则会返回负数 */
- (void)getFileSizeInPkg:(NSString *)filePath withCompletion:(void (^)(int64_t size))completion;

/** 获取目录下的所有文件名 */
- (void)getContentsOfDirAtPath:(NSString *)dirPath withCompletion:(void (^)(NSArray<NSString *> *_Nullable filenames))completion;

/**
 读取数据内容
 
 @param inOrder 是否有顺序要求. YES的读取任务会有自己的队列
 @param filePath 文件路径
 @param dispatchQueue completion的回调队列. 若为nil, 则completion将在主线程回调
 @param completion 返回Data的Block
 */
- (void)readDataInOrder:(BOOL)inOrder
           withFilePath:(NSString *)filePath
          dispatchQueue:(nullable dispatch_queue_t)dispatchQueue
             completion:(BDPPkgFileReadDataBlock)completion;

/**
 读取音频资源URL
 
 @param inOrder 是否有顺序要求. YES的读取任务会有自己的队列
 @param filePath 文件路径
 @param dispatchQueue completion的回调队列. 若为nil, 则completion将在主线程回调
 @param completion 返回Data的Block
 */
- (void)readDataURLInOrder:(BOOL)inOrder
              withFilePath:(NSString *)filePath
             dispatchQueue:(nullable dispatch_queue_t)dispatchQueue
                completion:(BDPPkgFileReadURLBlock)completion;

/// 异步读取文件内容
/// @param filePath 包内文件路径
/// @param syncIfDownloaded 如果包已下载, 同步执行回调
/// @param dispatchQueue 回调队列, 如果syncIfDownloaded=YES, 该传参不使用
/// @param completion 回调blokc
- (void)readDataWithFilePath:(NSString *)filePath
            syncIfDownloaded:(BOOL)syncIfDownloaded
               dispatchQueue:(nullable dispatch_queue_t)dispatchQueue
                  completion:(BDPPkgFileReadDataBlock)completion;

@end

#pragma mark sync read

/// 同步加载Api
@protocol BDPPkgFileSyncReadHandleProtocol <NSObject>

/** 同步加载Data */
- (nullable NSData *)readDataWithFilePath:(NSString *)filePath error:(NSError * *)error;
/** 同步批量加载Data，如果包未下载完成会直接返回nil */
- (NSArray<NSData *> *)readDatasWithFilePaths:(NSArray<NSString *> *)filePaths error:(NSError **)error;
/** 同步获取辅助文件的URL */
- (nullable NSURL *)urlOfDataWithFilePath:(NSString *)filePath error:(NSError * *)error;
/** 文件是否存在包内 */
- (BOOL)fileExistsInPkgAtPath:(NSString *)filePath;
/** 获取文件大小, 若不存在则会返回负数 */
- (int64_t)fileSizeInPkgAtPath:(NSString *)filePath;
/** 获取目录下的所有文件名 */
- (nullable NSArray<NSString *> *)contentsOfPkgDirAtPath:(NSString *)dirPath;

@end


/// 小程序/H5小程序/卡片异步加载代码包文件的统一协议
/// 目前只有API实现时会使用
@protocol BDPPkgCommonAsyncReadDataHandleProtocol <NSObject>

/** 异步加载Data */
- (void)asyncReadDataWithFilePath:(NSString *)filePath
                    dispatchQueue:(nullable dispatch_queue_t)dispatchQueue
                       completion:(BDPPkgFileReadDataBlock)completion;

/// 异步加载Data，文件存到app包辅助文件目录
- (void)asyncReadDataURLWithFilePath:(NSString *)filePath
                       dispatchQueue:(nullable dispatch_queue_t)dispatchQueue
                          completion:(BDPPkgFileReadURLBlock)completion;

@end


/// 小程序/H5小程序/卡片加载代码包文件的统一协议
/// 目前只有API实现时会使用
@protocol BDPPkgFileManagerHandleProtocol <BDPPkgFileSyncReadHandleProtocol, BDPPkgCommonAsyncReadDataHandleProtocol, BDPPkgFileAsyncReadHandleProtocol>

@end

NS_ASSUME_NONNULL_END
