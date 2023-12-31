//
//  BDPPackageDownloadResponseHandler.m
//  Timor
//
//  Created by houjihu on 2020/7/7.
//

#import "BDPPackageDownloadResponseHandler.h"

@interface BDPPackageDownloadResponseHandler ()

/// 下载标识
@property (nonatomic, copy, readwrite) NSString *identifier;
/// 开始下载回调
@property (nonatomic, copy, nullable, readwrite) BDPPackageDownloaderBegunBlock begunBlock;
/// 下载进度回调
@property (nonatomic, copy, nullable, readwrite) BDPPackageDownloaderProgressBlock progressBlock;
/// 下载完成回调
@property (nonatomic, copy, nullable, readwrite) BDPPackageDownloaderCompletedBlock completedBlock;

@end

@implementation BDPPackageDownloadResponseHandler

- (instancetype)initWithID:(NSString *)identifier
                begunBlock:(nullable BDPPackageDownloaderBegunBlock)begunBlock
             progressBlock:(nullable BDPPackageDownloaderProgressBlock)progressBlock
            completedBlock:(nullable BDPPackageDownloaderCompletedBlock)completedBlock {
    if (self = [super init]) {
        self.identifier = identifier;
        self.begunBlock = begunBlock;
        self.progressBlock = progressBlock;
        self.completedBlock = completedBlock;
    }
    return self;
}

@end
