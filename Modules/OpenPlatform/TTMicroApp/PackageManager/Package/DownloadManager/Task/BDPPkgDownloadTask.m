//
//  BDPPkgDownloadTask.m
//  Timor
//
//  Created by 傅翔 on 2019/1/22.
//

#import "BDPPkgDownloadTask.h"
#import "BDPHttpDownloadTask.h"
#import "BDPHttpDownloadTask+BrSupport.h"

@interface BDPPkgDownloadTask ()

@property (nonatomic, strong) NSDate *beginDate;
@property (nonatomic, strong) NSDate *endDate;

@property (nonatomic, assign) NSUInteger urlIndex;
@property (nonatomic, assign) NSUInteger lastUrlIndex;

@end

@implementation BDPPkgDownloadTask

- (void)startTask {
    if (!self.downloadTask) {
        return;
    }
    if (self.isDownloadBr && BDPHttpDownloadTask.isSupportBr) {
        [self.downloadTask setupBrContext];
    }
    self.beginDate = [NSDate date];
    [self.downloadTask resume];
}

- (void)suspendTask {
    [self.downloadTask suspend];
}

- (void)stopTask {
    if (self.isDownloadBr && BDPHttpDownloadTask.isSupportBr) {
        [self.downloadTask releaseBrContext];
    }
    [self.downloadTask cancel];
    self.downloadTask = nil;
}

- (void)recordEndTime {
    self.endDate = [NSDate date];
}

- (void)tryNextUrl {
    if (self.isDownloadBr && BDPHttpDownloadTask.isSupportBr && self.urlIndex + 1 >= _requestURLs.count) {
        // brotil下载失败，切换到正常url下载
        self.isDownloadBr = NO;
        self.urlIndex = 0;
        self.lastUrlIndex = 0;
        return;
    }
    self.lastUrlIndex = self.urlIndex;
    self.urlIndex++;
}

- (void)setPriority:(float)priority {
    _priority = priority;
    _downloadTask.priority = priority;
}

#pragma mark - Computed Properties
- (NSURL *)requestURL {
    return [self realUrl:(_urlIndex < _requestURLs.count ? _requestURLs[_urlIndex] : nil)];
}

- (BOOL)isLastRequestURL {
    if (self.isDownloadBr && BDPHttpDownloadTask.isSupportBr && _requestURLs.count) {
        return NO;
    }
    return _urlIndex == _requestURLs.count - 1 || !_requestURLs.count;
}

- (NSURL *)prevRequestURL {
    return [self realUrl:(_lastUrlIndex < _requestURLs.count ? _requestURLs[_lastUrlIndex] : _requestURLs.firstObject)];
}

- (NSURL *)realUrl:(NSURL *)url
{
    if (self.isDownloadBr && BDPHttpDownloadTask.isSupportBr) {
//        return [NSURL URLWithString:@"https://tt8kp9gn4oeqgoh39x.tt.host.bytedance.net/app.ttpkg.js.br"];
        return [url URLByAppendingPathExtension:@"br"];
    } else {
//        return [NSURL URLWithString:@"https://tt8kp9gn4oeqgoh39x.tt.host.bytedance.net/app.ttpkg"];
    }
    return url;
}

- (NSData *)decodeData:(NSData *)data
{
    if (self.isDownloadBr && BDPHttpDownloadTask.isSupportBr) {
        return [self.downloadTask brDecode:data];
    }
    return data;
}
@end
