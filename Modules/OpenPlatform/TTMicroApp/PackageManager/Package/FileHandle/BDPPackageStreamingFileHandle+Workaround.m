//
//  BDPPackageStreamingFileHandle+Workaround.m
//  Timor
//
//  Created by lixiaorui on 2020/7/28.
//
#import "BDPPackageStreamingFileHandle+Workaround.h"
#import "BDPPackageStreamingFileHandle+Private.h"
#import "BDPPackageContext.h"

@implementation BDPPackageStreamingFileHandle (Workaround)

#pragma mark - 原BDPPkgFileReadHandleProtocol特有方法

/** 添加下载完成的回调. 如调用时已下载完成, 则会异步丢至main thread处理 */
- (void)addCompletedBlk:(void (^)(NSError *_Nullable error))completedBlk {
    // 原始该方法用于在加载流程中添加pkg下周完成的回调，新版流程中下载流程由meta和包管理统一处理
     NSAssert(false, @"new package flow should handled");
}

/// 应用退出时打印日志，记录访问过的文件列表
- (void)appContainerWillBeClosed {
    WeakSelf;
    [self executeSync:NO inSelfQueueOfBlk:^{
        StrongSelfIfNilReturn;
        if (!self.fileRecords.count) {
            return;
        }
        NSArray *records = [self.fileRecords copy];
        NSString *filesJsonStr = [records JSONRepresentation];
        if (filesJsonStr.length) {
            BDPLogInfo(@"mp_stream_load_files_index with uniqueID(%@), packageName(%@), files:(%@)", self.packageContext.uniqueID, self.packageContext.packageName, filesJsonStr);
        }
    }];
}

@end

