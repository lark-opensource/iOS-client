//
//  BDPPackageStreamingFileHandle+FileManagerHandle.m
//  Timor
//
//  Created by houjihu on 2020/7/17.
//

#import "BDPPackageStreamingFileHandle+FileManagerHandle.h"
#import "BDPPackageStreamingFileHandle+AsyncRead.h"
#import "BDPPackageStreamingFileHandle+SyncRead.h"
#import "BDPPackageStreamingFileReadTask.h"

@implementation BDPPackageStreamingFileHandle (FileManagerHandle)

#pragma mark - BDPPkgCommonAsyncReadDataHandleProtocol

/** 异步加载Data */
- (void)asyncReadDataWithFilePath:(NSString *)filePath
                    dispatchQueue:(nullable dispatch_queue_t)dispatchQueue
                       completion:(BDPPkgFileReadDataBlock)completion {
    return [self readDataInOrder:NO withFilePath:filePath dispatchQueue:dispatchQueue completion:completion];
}

/// 异步加载Data，文件存到app包辅助文件目录
- (void)asyncReadDataURLWithFilePath:(NSString *)filePath
                       dispatchQueue:(nullable dispatch_queue_t)dispatchQueue
                          completion:(BDPPkgFileReadURLBlock)completion {
    return [self readDataURLInOrder:YES withFilePath:filePath dispatchQueue:dispatchQueue completion:completion];
}

@end
