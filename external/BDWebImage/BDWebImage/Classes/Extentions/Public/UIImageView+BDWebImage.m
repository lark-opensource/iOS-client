//
//  UIImageView+BDWebImage.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/29.
//
//这个文件就是拿来重定义BDWebImage里面的下载接口的
#import "UIImageView+BDWebImage.h"
//#import "BDWebImage.h"
#import <objc/runtime.h>
#import "UIImage+BDWebImage.h"
#import "BDWebImageRequest.h"
#import "BDWebImageRequest+TTMonitor.h"
#import "BDWebImageRequest+Private.h"
#import "BDImagePerformanceRecoder.h"
#import "BDImageLargeSizeMonitor.h"
#import "BDImageSensibleMonitor.h"
#import "BDImageView.h"
#if __has_include("BDBaseInternal.h")
#import <BDAlogProtocol/BDAlogProtocol.h>
#endif

@implementation UIImageView (BDWebImage)

- (void)setBd_isOpenDownsample:(BOOL)bd_isOpenDownsample {
    objc_setAssociatedObject(self, @selector(bd_isOpenDownsample), @(bd_isOpenDownsample), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bd_isOpenDownsample {
    return [(NSNumber *)objc_getAssociatedObject(self, @selector(bd_isOpenDownsample)) boolValue];
}

- (void)setImageRequest:(BDWebImageRequest *)imageRequest
{
    objc_setAssociatedObject(self, @selector(imageRequest), imageRequest, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable BDWebImageRequest *)imageRequest
{
    return objc_getAssociatedObject(self, @selector(imageRequest));
}

- (nullable BDWebImageRequest *)bd_setImageWithURL:(NSURL *)imageURL
{
    return [self bd_setImageWithURL:imageURL placeholder:nil options:BDImageRequestDefaultOptions progress:NULL completion:NULL];
}

- (nullable BDWebImageRequest *)bd_setImageWithURL:(NSURL *)imageURL
                              placeholder:(nullable UIImage *)placeholder
{
    return [self bd_setImageWithURL:imageURL placeholder:placeholder options:BDImageRequestDefaultOptions progress:NULL completion:NULL];
}

- (nullable BDWebImageRequest *)bd_setImageWithURL:(NSURL *)imageURL options:(BDImageRequestOptions)options
{
    return [self bd_setImageWithURL:imageURL placeholder:nil options:options progress:NULL completion:NULL];
}

- (nullable BDWebImageRequest *)bd_setImageWithURL:(NSURL *)imageURL
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                               completion:(BDImageRequestCompletedBlock)completion
{
    return [self bd_setImageWithURL:imageURL placeholder:placeholder options:options progress:NULL completion:completion];
}

- (nullable BDWebImageRequest *)bd_setImageWithURL:(NSURL *)imageURL
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                                 progress:(BDImageRequestProgressBlock)progress
                               completion:(BDImageRequestCompletedBlock)completion
{
   return [self bd_setImageWithURL:imageURL placeholder:placeholder options:options cacheName:nil progress:progress completion:completion];
}

- (nullable BDWebImageRequest *)bd_setImageWithURL:(NSURL *)imageURL
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                                 progress:(BDImageRequestProgressBlock)progress
                              transformer:(BDBaseTransformer *)transformer
                               completion:(BDImageRequestCompletedBlock)completion {
    NSString *cacheName = transformer.appendingStringForCacheKey;
    return [self bd_setImageWithURL:imageURL alternativeURLs:nil placeholder:placeholder options:options cacheName:cacheName transformer:transformer progress:progress completion:completion];
}

- (nullable BDWebImageRequest *)bd_setImageWithURL:(NSURL *)imageURL
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                                cacheName:(NSString *)cacheName
                                 progress:(BDImageRequestProgressBlock)progress
                               completion:(BDImageRequestCompletedBlock)completion {
    return [self bd_setImageWithURL:imageURL alternativeURLs:nil placeholder:placeholder options:options cacheName:cacheName transformer:nil  progress:progress completion:completion];
}

- (nullable BDWebImageRequest *)bd_setImageWithURL:(NSURL *)imageURL
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                              transformer:(BDBaseTransformer *)transformer
                                 progress:(BDImageRequestProgressBlock)progress
                               completion:(BDImageRequestCompletedBlock)completion {
    return [self bd_setImageWithURL:imageURL alternativeURLs:nil placeholder:placeholder options:options cacheName:nil transformer:transformer progress:progress completion:completion];
}

- (nullable BDWebImageRequest *)bd_setImageWithURLs:(NSArray *)imageURLs
                               placeholder:(nullable UIImage *)placeholder
                                   options:(BDImageRequestOptions)options
                               transformer:(BDBaseTransformer *)transformer
                                  progress:(BDImageRequestProgressBlock)progress
                                completion:(BDImageRequestCompletedBlock)completion {
    //这里如果传空会出发后面的参数断言，imageURLs不从1开始取数的原因是因为失败后 currentIndex++ 即从1开始
    return [self bd_setImageWithURL:imageURLs.firstObject alternativeURLs:imageURLs placeholder:placeholder options:options cacheName:nil transformer:transformer progress:progress completion:completion];
}

- (nullable BDWebImageRequest *)bd_setImageWithURL:(NSURL *)imageURL
                          alternativeURLs:(NSArray *)alternativeURLs
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                                cacheName:(NSString *)cacheName
                              transformer:(BDBaseTransformer *)transformer
                                 progress:(BDImageRequestProgressBlock)progress
                               completion:(BDImageRequestCompletedBlock)completion
{
    return [self bd_setImageWithURL:imageURL
                    alternativeURLs:alternativeURLs
                        placeholder:placeholder
                            options:options
                    timeoutInterval:0
                          cacheName:cacheName
                        transformer:transformer
                           progress:progress
                         completion:completion];
}

- (nullable BDWebImageRequest *)bd_setImageWithURL:(NSURL *)imageURL
                          alternativeURLs:(nullable NSArray *)alternativeURLs
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                          timeoutInterval:(CFTimeInterval)timeoutInterval
                                cacheName:(nullable NSString *)cacheName
                              transformer:(nullable BDBaseTransformer *)transformer
                                 progress:(nullable BDImageRequestProgressBlock)progress
                               completion:(nullable BDImageRequestCompletedBlock)completion
{
    return [self bd_setImageWithURL:imageURL
                    alternativeURLs:alternativeURLs
                        placeholder:placeholder
                            options:options
                    timeoutInterval:0
                          cacheName:cacheName
                        transformer:transformer
                       decryptBlock:nil
                           progress:progress
                         completion:completion];
}

- (nullable BDWebImageRequest *)bd_setImageWithURL:(NSURL *)imageURL
                          alternativeURLs:(NSArray *)alternativeURLs
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                          timeoutInterval:(CFTimeInterval)timeoutInterval
                                cacheName:(NSString *)cacheName
                              transformer:(BDBaseTransformer *)transformer
                             decryptBlock:(nullable BDImageRequestDecryptBlock)decrypt
                                 progress:(nullable BDImageRequestProgressBlock)progress
                               completion:(nullable BDImageRequestCompletedBlock)completion {
    BDWebImageRequestConfig *config = [BDWebImageRequestConfig new];
    config.cacheName = cacheName;
    config.timeoutInterval = timeoutInterval;
    config.transformer = transformer;
    
    BDWebImageRequestBlocks *blocks = [BDWebImageRequestBlocks new];
    blocks.decryptBlock = decrypt;
    blocks.progressBlock = progress;
    blocks.completedBlock = completion;
    return [self bd_setImageWithURL:imageURL alternativeURLs:alternativeURLs placeholder:placeholder options:options config:config blocks:blocks];
}

- (nullable BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)imageURL
                                   alternativeURLs:(nullable NSArray *)alternativeURLs
                                       placeholder:(nullable UIImage *)placeholder
                                           options:(BDImageRequestOptions)options
                                            config:(nullable BDWebImageRequestConfig *)config
                                            blocks:(nonnull BDWebImageRequestBlocks *)blocks
{
    if (options & BDImageRequestCallbackNotInMainThread) {
        options &= ~BDImageRequestCallbackNotInMainThread;
    }
    if (![self isKindOfClass:[BDImageView class]]) {
        // 设置的 ImageView 不是 BDImageView，预加载动图帧兼容 UIImageView 动图播放
        options |= BDImageRequestPreloadAllFrames;
    }
    if ([imageURL isKindOfClass:NSString.class]) {
        imageURL = [NSURL URLWithString:(NSString *)imageURL];
    }
    
    BDBaseTransformer *transformer = config.transformer;
    
    BDImageRequestDecryptBlock decrypt = blocks.decryptBlock;
    BDImageRequestProgressBlock progress = blocks.progressBlock;
    BDImageRequestCompletedBlock completion = blocks.completedBlock;
    
    CGSize downsampleSize = CGSizeZero;
    if ([self bd_isOpenDownsample] || [BDWebImageManager sharedManager].enableAllImageDownsample) {
        downsampleSize = !CGSizeEqualToSize(self.bounds.size, CGSizeZero) ? self.bounds.size : [BDWebImageManager sharedManager].allImageDownsampleSize;
    }
    config.size = !CGSizeEqualToSize(config.size, CGSizeZero) ? config.size : downsampleSize;
    
    BDImageRequestKey *tempKey = [[BDImageRequestKey alloc] initWithURL:[[BDWebImageManager sharedManager]
                                                                         requestKeyWithURL:imageURL]
                                                         downsampleSize:(options & BDImageNotDownsample) ? CGSizeZero :config.size
                                                               cropRect:CGRectZero
                                                          transfromName:transformer ? [transformer appendingStringForCacheKey] : @""
                                                              smartCrop:(options & BDImageRequestSmartCorp)];
    BOOL needSetImage = YES;
    if (self.image.bd_requestKey && [self.image.bd_requestKey isEqual:tempKey]) {
        if (!self.image.bd_isThumbnail) {
            if (completion) {
                BDWebImageRequest *request = [[BDWebImageRequest alloc] initWithURL:imageURL];
                completion(request,self.image,nil,nil,BDWebImageResultFromMemoryCache);
            }
            return nil;
        } else {
            needSetImage = NO;
        }
    }
    
    if (needSetImage) {
        if (options & BDImageKeepPreviousImage){
            [self setImage:placeholder?:self.image];
        }else{
            [self setImage:placeholder?:nil];
        }
    }
    
    BDImageSensibleMonitor *sensibleMonitor = [self bd_createSensibleMonitor];
    [sensibleMonitor startImageSensibleMonitor];
    
    __weak typeof(self) weakSelf = self;
    BDImageRequestCompletedBlock completionBlk = ^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) {
            return ;
        }
        if ((options & BDImageHeicProgressDownloadForThumbnail) && image && image.bd_isThumbnail) {
            if (!strongSelf.image) {
                strongSelf.image = image;
                if (options & BDImageHeicThumbnailPassToBusinessLayer) {
                    // 缩略图回抛给业务层
                    completion(request,image,data,error,from);
                }
            }
            return;
        }
        if (!request.finished && image) {
            image.bd_webURL = request.currentRequestURL.absoluteURL;
            image.bd_loading = YES;
            strongSelf.image = image;
            return;
        }
        strongSelf.imageRequest = nil;
        UIImage *realImage = nil;
        if (image  && !(options & BDImageRequestSetDelaySetImage)) {
            if ((options&BDImageRequestSetAnimationFade) == BDImageRequestSetAnimationFade &&
                from == BDWebImageResultFromDownloading) {
                CATransition *transition = [CATransition animation];
                transition.duration = config.transitionDuration;
                transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                transition.type = kCATransitionFade;
                [strongSelf.layer addAnimation:transition forKey:BDWebImageSetAnimationKey];
            }
            if ([request.transformer respondsToSelector:@selector(transformImageAfterStoreWithImage:)]) {
                realImage = [request.transformer transformImageAfterStoreWithImage:image];
            }else {
                realImage = image;
            }
            realImage.bd_webURL = request.currentRequestURL.absoluteURL;
            realImage.bd_loading = NO;
            
            // 检查 realImage 的类型，需要将其强制转换为 BDImage *
            if (![strongSelf isKindOfClass:[BDImageView class]] &&
                [realImage isKindOfClass:[BDImage class]] &&
                ((BDImage *)realImage).frameCount > 1) {
                
                if (@available(iOS 15.0, *)) {
                    // 当系统为 iOS15 及以上，且使用 UIImageView 以及图片是动图的时候采用这种方式来获取动图
                    UIImage *animatedImage = [UIImage animatedImageWithImages:realImage.images duration:realImage.duration];
                    [strongSelf setImage:animatedImage];
                } else {
                    // 在 iOS15 之前，如果当前为动图，下面这行代码会触发 images 的 getter 方法
                    strongSelf.image = realImage;
                }
            } else {
                // 所有静图
                strongSelf.image = realImage;
            }
        } else {
            realImage = image;
        }
        [strongSelf bd_trackSensibleMonitor:sensibleMonitor Request:request Image:realImage from:from];
        if ((completion && request.finished) || (completion && request == nil)) {
            completion(request,realImage,data,error,from);
        }
    };
    //第三个判断条件为 两次下载的option不同且有一次为BDImageProgressiveDownload的情况 之外的所有情况
    BDWebImageRequest *oldRequest = self.imageRequest;
    if (oldRequest && !oldRequest.isCancelled && [tempKey isEqual:oldRequest.originalKey] && (oldRequest.option == options)) {
        oldRequest.completedBlock = completionBlk;
        oldRequest.progressBlock = progress;
        oldRequest.decryptBlock = decrypt;
        [oldRequest setupKeyAndTransformer:transformer];
        oldRequest.option = options;
        if (alternativeURLs) {
            oldRequest.alternativeURLs = alternativeURLs;
        }
        return oldRequest;
    }
    
    [self bd_cancelImageLoad];
    
    [self.layer removeAnimationForKey:BDWebImageSetAnimationKey];
    
    blocks.completedBlock = completionBlk;
    BDWebImageRequest *request = [[BDWebImageManager sharedManager] requestImage:imageURL
                                                                 alternativeURLs:alternativeURLs
                                                                         options:options
                                                                          config:config
                                                                          blocks:blocks];
    if (!request.isFinished) {
        self.imageRequest = request;
    } else {
        self.imageRequest = nil;
    }
    request.largeImageMonitor.requestView = self;
    request.recorder.requestImageSize = CGSizeMake(config.size.width * UIScreen.mainScreen.scale, config.size.height * UIScreen.mainScreen.scale);
    request.recorder.viewSize = CGSizeMake(self.bounds.size.width * UIScreen.mainScreen.scale, self.bounds.size.height * UIScreen.mainScreen.scale);
    
    return request;
}

- (BDImageSensibleMonitor *)bd_createSensibleMonitor {
    BOOL enableWithService = [BDWebImageManager sharedManager].enableSensibleMonitorWithService;
    BOOL enableWithLogType = [BDWebImageManager sharedManager].enableSensibleMonitorWithLogType;
    if (!enableWithService && !enableWithLogType) {
        return nil;
    }
    BDImageSensibleMonitor *sensibleMonitor = [BDImageSensibleMonitor new];
    sensibleMonitor.monitorWithService = enableWithService;
    sensibleMonitor.monitorWithLogType = enableWithLogType;
    sensibleMonitor.requestView = self;
    return sensibleMonitor;
}

- (void)bd_trackSensibleMonitor:(BDImageSensibleMonitor *)monitor Request:(BDWebImageRequest *)request Image:(UIImage *)image from:(BDWebImageResultFrom)from {
    NSInteger samplingIndex = [BDWebImageManager sharedManager].sensibleMonitorSamplingIndex;
    if (samplingIndex <= 0) {
        samplingIndex = 1;
    }
    if (nil == monitor || monitor.index % samplingIndex != 0) {
        return;
    }
    
    monitor.requestImage = image;
    monitor.from = from;
    if (request.bizTag.length > 0) {
        monitor.bizTag = request.bizTag;
    } else if ([BDWebImageManager sharedManager].bizTagURLFilterBlock) {
        NSString *bizTag = [BDWebImageManager sharedManager].bizTagURLFilterBlock(request.currentRequestURL);
        monitor.bizTag = bizTag.length > 0 ? bizTag : @"";
    } else {
        monitor.bizTag = @"";
    }
    monitor.imageURL = request.currentRequestURL.absoluteString;
    monitor.exceptionTag = request.recorder.exceptionType;
    [monitor trackImageSensibleMonitor];
}

- (void)bd_cancelImageLoad
{
    [self.imageRequest cancel];
    self.imageRequest = nil;
}

- (NSURL *)bd_imageURL {
    return self.imageRequest.currentRequestURL;
}
@end
