//
//  SDWebImageDownloaderOperation+Monitor.m
//  BDWebImage
//
//  Created by fengyadong on 2017/12/10.
//

#import "SDWebImageDownloaderOperation+Monitor.h"
#import "BDWebImageCompat.h"
#import "SDWebImageManager+Monitor.h"
#import <objc/runtime.h>

static char kDictReportDataKey;

@interface SDWebImageDownloaderOperation (_Private)
- (void)callCompletionBlocksWithImage:(nullable UIImage *)image
                                       imageData:(nullable NSData *)imageData
                                           error:(nullable NSError *)error
                                        finished:(BOOL)finished;
@end

@implementation SDWebImageDownloaderOperation (Monitor)

+ (void)load
{
    BDWebImageMethodSwizzle(self, @selector(start), @selector(bdwebimage_start));
    BDWebImageMethodSwizzle(self, @selector(URLSession:task:didCompleteWithError:),
                            @selector(BDWebImageURLSession:task:didCompleteWithError:));
    BDWebImageMethodSwizzle(self, @selector(callCompletionBlocksWithImage:imageData:error:finished:), @selector(bdwebimage_callCompletionBlocksWithImage:imageData:error:finished:));
}
                            
- (NSMutableDictionary *)dictReportData {
    NSMutableDictionary *rst = objc_getAssociatedObject(self, &kDictReportDataKey);
    if (rst == nil) {
        rst = [NSMutableDictionary dictionaryWithCapacity:5];
        objc_setAssociatedObject(self, &kDictReportDataKey, rst, OBJC_ASSOCIATION_RETAIN);
    }
    return rst;
}

- (void)BDWebImageURLSession:(NSURLSession *)session
                        task:(NSURLSessionTask *)task
        didCompleteWithError:(NSError *)error
{
    double dowloadDuration = [[SDWebImageManager monitor] stop:[self.request.URL.absoluteString stringByAppendingString:@"download"]];
    [[SDWebImageManager monitor] start:[self.request.URL.absoluteString stringByAppendingString:@"decode"]];
    NSMutableDictionary *attributes = [self dictReportData];
    [attributes setValue:@(dowloadDuration) forKey:@"image_download_duration"];
    [attributes setValue:@(task.countOfBytesReceived/1024.f) forKey:@"image_size"];
    [attributes setValue:error ? @"fail":@"success" forKey:@"download_status"];
    if (error) {
        [attributes setValue:@(error.code) forKey:@"err_code"];
    }
    
    [self BDWebImageURLSession:session task:task didCompleteWithError:error];
}

- (void)bdwebimage_start
{
    [[SDWebImageManager monitor] start:[self.request.URL.absoluteString stringByAppendingString:@"download"]];
    [self bdwebimage_start];
}
                            
- (void)_reportUrl:(NSString *)url error:(nullable NSError *)error {
    NSDictionary *attributes = [self dictReportData];
    if (error == nil) {
        double decodeDuration = [[SDWebImageManager monitor] stop:[self.request.URL.absoluteString stringByAppendingString:@"decode"]];
        [attributes setValue:@(decodeDuration) forKey:@"image_decode_duration"];
    }
    
    if ([[SDWebImageManager monitor] ifExist:[url stringByAppendingString:@"startReq"]]) {
        [[SDWebImageManager monitor] storeData:attributes forKey:url];
    }

}

- (void)bdwebimage_callCompletionBlocksWithImage:(nullable UIImage *)image
                                       imageData:(nullable NSData *)imageData
                                           error:(nullable NSError *)error
                                        finished:(BOOL)finished {
    [self _reportUrl:self.request.URL.absoluteString error:error];
    
    [self bdwebimage_callCompletionBlocksWithImage:image imageData:imageData error:error finished:finished];
}
@end

