//
//  UIButton+BDWebImage.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/12/5.
//

#import "UIButton+BDWebImage.h"
#import <pthread.h>
#import "BDImagePerformanceRecoder.h"
#import "BDWebImageError.h"
//#import <BDAlogProtocol/BDAlogProtocol.h>
//#import "BDImageDecoderFactory.h"
#import "BDBaseTransformer.h"
#import "UIImage+BDWebImage.h"
#import "BDWebImageCompat.h"
#import "BDWebImageRequest+TTMonitor.h"
#import "BDWebImageRequest+Private.h"
#import <objc/runtime.h>

@interface BDWebImageButtonImageSetter : NSObject
{
    NSMutableDictionary *_requestDictionary;
    pthread_mutex_t _lock;
}

- (BDWebImageRequest *)imageRequestForState:(UIControlState)state;
- (void)setImageRequest:(BDWebImageRequest *)request state:(UIControlState)state;
- (BDWebImageRequest *)backgroundRequestForState:(UIControlState)state;
- (void)setBackgroundRequest:(BDWebImageRequest *)request state:(UIControlState)state;
@end

@implementation BDWebImageButtonImageSetter
- (void)dealloc
{
    pthread_mutex_destroy(&_lock);
}

- (NSMutableDictionary *)requestDictionary
{
    if (!_requestDictionary) {
        _requestDictionary = [NSMutableDictionary dictionary];
        pthread_mutex_init(&_lock, 0);
    }
    return _requestDictionary;
}

- (BDWebImageRequest *)imageRequestForState:(UIControlState)state
{
    BDWebImageRequest *request = nil;
    pthread_mutex_lock(&_lock);
    request = [[self requestDictionary] objectForKey:[NSString stringWithFormat:@"image_%li",state]];
    pthread_mutex_unlock(&_lock);
    return request;
}

- (void)setImageRequest:(BDWebImageRequest *)request state:(UIControlState)state
{
    pthread_mutex_lock(&_lock);
    if (request) {
        [[self requestDictionary] setObject:request forKey:[NSString stringWithFormat:@"image_%li",state]];
    } else {
        [[self requestDictionary] removeObjectForKey:[NSString stringWithFormat:@"image_%li",state]];
    }
    pthread_mutex_unlock(&_lock);
}

- (BDWebImageRequest *)backgroundRequestForState:(UIControlState)state
{
    BDWebImageRequest *request = nil;
    pthread_mutex_lock(&_lock);
    request = [[self requestDictionary] objectForKey:[NSString stringWithFormat:@"background_%li",state]];
    pthread_mutex_unlock(&_lock);
    return request;
}

- (void)setBackgroundRequest:(BDWebImageRequest *)request state:(UIControlState)state
{
    pthread_mutex_lock(&_lock);
    if (request) {
        [[self requestDictionary] setObject:request forKey:[NSString stringWithFormat:@"background_%li",state]];
    } else {
        [[self requestDictionary] removeObjectForKey:[NSString stringWithFormat:@"background_%li",state]];
    }
    pthread_mutex_unlock(&_lock);
}
@end


@implementation UIButton (BDWebImage)
- (BDWebImageRequest *)bd_setImageWithURL:(NSURL *)url
                                 forState:(UIControlState)state{
    return [self bd_setImageWithURL:url
                           forState:state
                   placeholderImage:nil
                            options:BDImageRequestDefaultOptions
                           progress:NULL
                          completed:NULL];
}
- (BDWebImageRequest *)bd_setImageWithURL:(NSURL *)url
                                 forState:(UIControlState)state
                         placeholderImage:(UIImage *)placeholder{
    return [self bd_setImageWithURL:url
                           forState:state
                   placeholderImage:placeholder
                            options:BDImageRequestDefaultOptions
                           progress:NULL
                          completed:NULL];
}

- (BDWebImageRequest *)bd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder decryption:(BDImageRequestDecryptBlock)decrption {
    return [self bd_setImageWithURL:url
                    alternativeURLs:nil
                           forState:state
                   placeholderImage:placeholder
                            options:BDImageRequestDefaultOptions
                    timeoutInterval:0
                          cacheName:nil
                        transformer:nil
                           progress:NULL
                          completed:NULL
                         decryption:decrption];
}

- (BDWebImageRequest *)bd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(BDImageRequestCompletedBlock)completedBlock
{
    return [self bd_setImageWithURL:url forState:state placeholderImage:placeholder options:BDImageRequestDefaultOptions progress:NULL completed:completedBlock];
}

- (BDWebImageRequest *)bd_setImageWithURL:(NSURL *)url
                                 forState:(UIControlState)state
                         placeholderImage:(UIImage *)placeholder
                                 progress:(BDImageRequestProgressBlock)progressBlock
                                completed:(BDImageRequestCompletedBlock)completedBlock {
    return [self bd_setImageWithURL:url
                           forState:state
                   placeholderImage:placeholder
                            options:BDImageRequestDefaultOptions
                           progress:progressBlock
                          completed:completedBlock];
}

- (BDWebImageRequest *)bd_setImageWithURL:(NSURL *)url
                                 forState:(UIControlState)state
                         placeholderImage:(UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                                cacheName:(NSString *)cacheName
                                 progress:(BDImageRequestProgressBlock)progressBlock
                                completed:(BDImageRequestCompletedBlock)completedBlock {
    return [self bd_setImageWithURL:url
                    alternativeURLs:nil
                           forState:state
                   placeholderImage:placeholder
                            options:options
                          cacheName:cacheName
                        transformer:nil
                           progress:progressBlock
                          completed:completedBlock];
}

- (BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)url
                          alternativeURLs:(nullable NSArray *)alternativeURLs
                                 forState:(UIControlState)state
                         placeholderImage:(UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                              transformer:(BDBaseTransformer *)transformer
                                 progress:(BDImageRequestProgressBlock)progressBlock
                                completed:(BDImageRequestCompletedBlock)completedBlock {
    return [self bd_setImageWithURL:url
                    alternativeURLs:alternativeURLs
                           forState:state
                   placeholderImage:placeholder
                            options:options
                          cacheName:nil
                        transformer:transformer
                           progress:progressBlock
                          completed:completedBlock];
}

- (BDWebImageRequest *)bd_setImageWithURL:(NSURL *)url
                                 forState:(UIControlState)state
                         placeholderImage:(UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                                 progress:(BDImageRequestProgressBlock)progressBlock
                                completed:(BDImageRequestCompletedBlock)completedBlock {
    return [self bd_setImageWithURL:url alternativeURLs:nil forState:state placeholderImage:placeholder options:options transformer:nil progress:progressBlock completed:completedBlock];
}

- (BDWebImageRequest *)bd_setImageWithURLs:(NSArray *)URLs
                                  forState:(UIControlState)state
                          placeholderImage:(UIImage *)placeholder
                                   options:(BDImageRequestOptions)options
                               transformer:(BDBaseTransformer *)transformer
                                  progress:(BDImageRequestProgressBlock)progressBlock
                                 completed:(BDImageRequestCompletedBlock)completedBlock {
    return [self bd_setImageWithURL:URLs.count ? URLs.firstObject : nil alternativeURLs:URLs forState:state placeholderImage:placeholder options:options transformer:transformer progress:progressBlock completed:completedBlock];
}

- (BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)url
                          alternativeURLs:(nullable NSArray<NSURL *> *)alternativeURLs
                                 forState:(UIControlState)state
                         placeholderImage:(UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                                cacheName:(NSString *)cacheName
                              transformer:(nullable BDBaseTransformer *)transformer
                                 progress:(BDImageRequestProgressBlock)progressBlock
                                completed:(BDImageRequestCompletedBlock)completedBlock
{
    return [self bd_setImageWithURL:url
                    alternativeURLs:alternativeURLs
                           forState:state
                   placeholderImage:placeholder
                            options:options
                    timeoutInterval:0
                          cacheName:cacheName
                        transformer:transformer
                           progress:progressBlock
                          completed:completedBlock];
}

- (BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)url
                          alternativeURLs:(nullable NSArray<NSURL *> *)alternativeURLs
                                 forState:(UIControlState)state
                         placeholderImage:(UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                          timeoutInterval:(CFTimeInterval)timeoutInterval
                                cacheName:(NSString *)cacheName
                              transformer:(BDBaseTransformer *)transformer
                                 progress:(BDImageRequestProgressBlock)progressBlock
                                completed:(BDImageRequestCompletedBlock)completedBlock
{
    return [self bd_setImageWithURL:url
                    alternativeURLs:alternativeURLs
                           forState:state
                   placeholderImage:placeholder
                            options:options
                    timeoutInterval:0
                          cacheName:cacheName
                        transformer:transformer
                           progress:progressBlock
                          completed:completedBlock
                         decryption:nil];
}

- (BDWebImageRequest *)bd_setImageWithURL:(NSURL *)url
                          alternativeURLs:(NSArray<NSURL *> *)alternativeURLs
                                 forState:(UIControlState)state
                         placeholderImage:(UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                          timeoutInterval:(CFTimeInterval)timeoutInterval
                                cacheName:(NSString *)cacheName
                              transformer:(BDBaseTransformer *)transformer
                                 progress:(BDImageRequestProgressBlock)progressBlock
                                completed:(BDImageRequestCompletedBlock)completedBlock
                               decryption:(BDImageRequestDecryptBlock)decrption
{
    if (options & BDImageRequestCallbackNotInMainThread) {
        options &= ~BDImageRequestCallbackNotInMainThread;
    }
    options |= BDImageRequestPreloadAllFrames;
    if ([url isKindOfClass:[NSString class]]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
    __weak typeof(self) weakSelf = self;
    BDImageRequestCompletedBlock completionBlk = ^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) {
            return ;
        }
        if (!request.finished) {
            if (image) {
                [strongSelf setImage:image forState:state];
            }
            else {
                [strongSelf setImage:placeholder forState:state];
            }
            return;
        }
        UIImage *realImage = nil;
        if (image  && !(options & BDImageRequestSetDelaySetImage)) {
            if ((options&BDImageRequestSetAnimationFade) == BDImageRequestSetAnimationFade) {
                CATransition *transition = [CATransition animation];
                transition.duration = 0.2;
                transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                transition.type = kCATransitionFade;
                [strongSelf.layer addAnimation:transition forKey:BDWebImageSetAnimationKey];
            }
            if ([request.transformer respondsToSelector:@selector(transformImageAfterStoreWithImage:)]) {
                realImage = [request.transformer transformImageAfterStoreWithImage:image];
                if (!realImage && !error && image) {
                    error = [NSError errorWithDomain:BDWebImageErrorDomain
                                                code:BDWebImageEmptyImage
                                            userInfo:@{NSLocalizedDescriptionKey:@"AfterTransform failed"}];
                }
            }else {
                realImage = image;
            }
            [strongSelf setImage:realImage forState:state];
        } else {
            realImage = image;
        }
        if (completedBlock && request.finished) {
            completedBlock(request,realImage,data,error,from);
        }
        [[strongSelf imageSetter] setImageRequest:nil state:state];
    };
    
    CGSize downsampleSize = CGSizeZero;
    if ([self bd_isOpenDownsample] || [BDWebImageManager sharedManager].enableAllImageDownsample) {
        downsampleSize = self.bounds.size;
    }
    
    BDImageRequestKey *tempKey = [[BDImageRequestKey alloc] initWithURL:[[BDWebImageManager sharedManager] requestKeyWithURL:url] downsampleSize:(options & BDImageNotDownsample) ? CGSizeZero :downsampleSize cropRect:CGRectZero transfromName:transformer ? [transformer appendingStringForCacheKey] : @"" smartCrop:(options & BDImageRequestSmartCorp)];
    UIImage *image = [self imageForState:state];
    if (image.bd_requestKey && [image.bd_requestKey isEqual:tempKey]) {
        if (completedBlock) {
            BDWebImageRequest *request = [[BDWebImageRequest alloc] initWithURL:url];
            completedBlock(request,image,nil,nil,BDWebImageResultFromMemoryCache);
        }
        return nil;
    }
    
    BDWebImageButtonImageSetter *imageSetter = [self imageSetter];
    
    BDWebImageRequest *oldRequest = [imageSetter imageRequestForState:state];
    if (oldRequest && !oldRequest.isCancelled && [tempKey isEqual:oldRequest.originalKey] && (oldRequest.option == options)) {
        oldRequest.completedBlock = completionBlk;
        oldRequest.progressBlock = progressBlock;
        oldRequest.decryptBlock = decrption;
        [oldRequest setupKeyAndTransformer:transformer];
        if (alternativeURLs) {
            oldRequest.alternativeURLs = alternativeURLs;
        }
        return oldRequest;
    }
    
    [self bd_cancelImageLoadForState:state];
    
    [self setImage:placeholder forState:state];
    
    [self.layer removeAnimationForKey:BDWebImageSetAnimationKey];
    BDWebImageRequest *request = [[BDWebImageManager sharedManager] requestImage:url
                                                                 alternativeURLs:alternativeURLs
                                                                         options:options
                                                                            size:downsampleSize
                                                                 timeoutInterval:timeoutInterval
                                                                       cacheName:cacheName
                                                                     transformer:transformer
                                                                    decryptBlock:decrption
                                                                        progress:progressBlock
                                                                        complete:completionBlk];
    if (!request.isFinished) {
        if (!imageSetter) {
            imageSetter = [BDWebImageButtonImageSetter new];
            [self setImageSetter:imageSetter];
        }
        [imageSetter setImageRequest:request state:state];
    } else {
        [imageSetter setImageRequest:nil state:state];
    }
    
    request.recorder.requestImageSize = CGSizeMake(self.bounds.size.width * UIScreen.mainScreen.scale, self.bounds.size.height * UIScreen.mainScreen.scale);

    return request;
}

#pragma mark - BackgroudImage Method

- (BDWebImageRequest *)bd_setBackgroundImageWithURL:(NSURL *)url
                                           forState:(UIControlState)state{
    return [self bd_setBackgroundImageWithURL:url
                                     forState:state
                             placeholderImage:nil
                                      options:BDImageRequestDefaultOptions
                                     progress:NULL
                                    completed:NULL];
}

- (BDWebImageRequest *)bd_setBackgroundImageWithURL:(NSURL *)url
                                           forState:(UIControlState)state
                                   placeholderImage:(UIImage *)placeholder{
    return [self bd_setBackgroundImageWithURL:url
                                     forState:state
                             placeholderImage:placeholder
                                      options:BDImageRequestDefaultOptions
                                     progress:NULL
                                    completed:NULL];
}

- (BDWebImageRequest *)bd_setBackgroundImageWithURL:(NSURL *)url
                                           forState:(UIControlState)state
                                   placeholderImage:(UIImage *)placeholder
                                          completed:(BDImageRequestCompletedBlock)completedBlock
{
    return [self bd_setBackgroundImageWithURL:url
                                     forState:state
                             placeholderImage:placeholder
                                      options:BDImageRequestDefaultOptions
                                     progress:NULL
                                    completed:completedBlock];
}

- (BDWebImageRequest *)bd_setBackgroundImageWithURL:(NSURL *)url
                                           forState:(UIControlState)state
                                   placeholderImage:(UIImage *)placeholder
                                            options:(BDImageRequestOptions)options
                                           progress:(BDImageRequestProgressBlock)progressBlock
                                          completed:(BDImageRequestCompletedBlock)completedBlock {
    return [self bd_setBackgroundImageWithURL:url
                              alternativeURLs:nil
                                     forState:state
                             placeholderImage:placeholder
                                      options:options
                                    cacheName:nil
                                  transformer:nil
                                     progress:progressBlock
                                    completed:completedBlock];
}

- (BDWebImageRequest *)bd_setBackgroundImageWithURL:(NSURL *)url
                                           forState:(UIControlState)state
                                   placeholderImage:(UIImage *)placeholder
                                            options:(BDImageRequestOptions)options
                                          cacheName:(NSString *)cacheName
                                           progress:(BDImageRequestProgressBlock)progressBlock
                                          completed:(BDImageRequestCompletedBlock)completedBlock {
    return [self bd_setBackgroundImageWithURL:url
                              alternativeURLs:nil
                                     forState:state
                             placeholderImage:placeholder
                                      options:options
                                    cacheName:cacheName
                                  transformer:nil
                                     progress:progressBlock
                                    completed:completedBlock];
}

- (BDWebImageRequest *)bd_setBackgroundImageWithURLs:(NSArray *)URLs
                                  forState:(UIControlState)state
                          placeholderImage:(UIImage *)placeholder
                                   options:(BDImageRequestOptions)options
                               transformer:(BDBaseTransformer *)transformer
                                  progress:(BDImageRequestProgressBlock)progressBlock
                                 completed:(BDImageRequestCompletedBlock)completedBlock {
    return [self bd_setBackgroundImageWithURL:URLs.firstObject
                              alternativeURLs:URLs
                                     forState:state
                             placeholderImage:placeholder
                                      options:options
                                    cacheName:nil
                                  transformer:transformer
                                     progress:progressBlock
                                    completed:completedBlock];
}

- (BDWebImageRequest *)bd_setBackgroundImageWithURL:(NSURL *)url
                                    alternativeURLs:(nullable NSArray *)alternativeURLs
                                           forState:(UIControlState)state
                                   placeholderImage:(UIImage *)placeholder
                                            options:(BDImageRequestOptions)options
                                          cacheName:(NSString *)cacheName
                                        transformer:(BDBaseTransformer *)transformer
                                           progress:(BDImageRequestProgressBlock)progressBlock
                                          completed:(BDImageRequestCompletedBlock)completedBlock
{
    return [self bd_setBackgroundImageWithURL:url
                              alternativeURLs:alternativeURLs
                                     forState:state
                             placeholderImage:placeholder
                                      options:options
                                    timeoutInterval:0
                                    cacheName:cacheName
                                  transformer:transformer
                                     progress:progressBlock
                                    completed:completedBlock];
}

- (BDWebImageRequest *)bd_setBackgroundImageWithURL:(NSURL *)url
                                    alternativeURLs:(nullable NSArray *)alternativeURLs
                                           forState:(UIControlState)state
                                   placeholderImage:(UIImage *)placeholder
                                            options:(BDImageRequestOptions)options
                                    timeoutInterval:(CFTimeInterval)timeoutInterval
                                          cacheName:(NSString *)cacheName
                                        transformer:(BDBaseTransformer *)transformer
                                           progress:(BDImageRequestProgressBlock)progressBlock
                                          completed:(BDImageRequestCompletedBlock)completedBlock
{
    if (options & BDImageRequestCallbackNotInMainThread) {
        options &= ~BDImageRequestCallbackNotInMainThread;
    }
    options |= BDImageRequestPreloadAllFrames;
    if ([url isKindOfClass:[NSString class]]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
    
    CGSize downsampleSize = CGSizeZero;
    if ([self bd_isOpenDownsample] || [BDWebImageManager sharedManager].enableAllImageDownsample) {
        downsampleSize = self.bounds.size;
    }
    
    BDImageRequestKey *tempKey = [[BDImageRequestKey alloc] initWithURL:[[BDWebImageManager sharedManager] requestKeyWithURL:url] downsampleSize:(options & BDImageNotDownsample) ? CGSizeZero : downsampleSize cropRect:CGRectZero transfromName:transformer ? [transformer appendingStringForCacheKey] : @"" smartCrop:(options & BDImageRequestSmartCorp)];
    UIImage *image = [self backgroundImageForState:state];
    if (image.bd_requestKey && [image.bd_requestKey isEqual:tempKey]) {
        if (completedBlock) {
            BDWebImageRequest *request = [[BDWebImageRequest alloc] initWithURL:url];
            completedBlock(request,image,nil,nil,BDWebImageResultFromMemoryCache);
        }
        return nil;
    }
    
    BDWebImageButtonImageSetter *imageSetter = [self imageSetter];
    
    BDWebImageRequest *oldRequest = [imageSetter backgroundRequestForState:state];
    
    __weak typeof(self) weakSelf = self;
    BDImageRequestCompletedBlock completionBlk = ^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) {
            return ;
        }
        if (!request.finished) {
            [strongSelf setBackgroundImage:image forState:state];
            return;
        }
        UIImage *realImage = nil;
        if (image  && !(options & BDImageRequestSetDelaySetImage)) {
            if ((options&BDImageRequestSetAnimationFade) == BDImageRequestSetAnimationFade) {
                CATransition *transition = [CATransition animation];
                transition.duration = 0.2;
                transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                transition.type = kCATransitionFade;
                [strongSelf.layer addAnimation:transition forKey:BDWebImageSetAnimationKey];
            }
            if ([request.transformer respondsToSelector:@selector(transformImageAfterStoreWithImage:)]) {
                realImage = [request.transformer transformImageAfterStoreWithImage:image];
                if (!realImage && !error && image) {
                    error = [NSError errorWithDomain:BDWebImageErrorDomain
                                                code:BDWebImageEmptyImage
                                            userInfo:@{NSLocalizedDescriptionKey:@"AfterTransform failed"}];
                }
            }else {
                realImage = image;
            }
            [strongSelf setBackgroundImage:image forState:state];
        } else {
            realImage = image;
        }
        BDWebImageButtonImageSetter *imageSetter = [strongSelf imageSetter];
        [imageSetter setBackgroundRequest:nil state:state];
        if (completedBlock && request.finished) {
            completedBlock(request,realImage,data,error,from);
        }
        [[strongSelf imageSetter] setBackgroundRequest:nil state:state];
    };
    if (oldRequest && !oldRequest.isCancelled && [tempKey isEqual:oldRequest.originalKey] && (oldRequest.option == options)) {
        oldRequest.completedBlock = completionBlk;
        oldRequest.progressBlock = progressBlock;
        [oldRequest setupKeyAndTransformer:transformer];
        if (alternativeURLs) {
            oldRequest.alternativeURLs = alternativeURLs;
        }
        return oldRequest;
    }
    
    [self bd_cancelBackgroundImageLoadForState:state];
    
    [self setBackgroundImage:placeholder forState:state];
    
    [self.layer removeAnimationForKey:BDWebImageSetAnimationKey];
    BDWebImageRequest *request = [[BDWebImageManager sharedManager] requestImage:url
                                                                 alternativeURLs:alternativeURLs
                                                                         options:options
                                                                            size:downsampleSize
                                                                 timeoutInterval:timeoutInterval
                                                                       cacheName:nil
                                                                     transformer:transformer
                                                                    decryptBlock:nil
                                                                        progress:progressBlock
                                                                        complete:completionBlk];
    if (!request.isFinished) {
        if (!imageSetter) {
            imageSetter = [BDWebImageButtonImageSetter new];
            [self setImageSetter:imageSetter];
        }
        [imageSetter setBackgroundRequest:request state:state];
    } else {
        [imageSetter setBackgroundRequest:nil state:state];
    }
    
    request.recorder.requestImageSize = CGSizeMake(self.bounds.size.width * UIScreen.mainScreen.scale, self.bounds.size.height * UIScreen.mainScreen.scale);

    return request;
}


#pragma mark - cancel Method

- (void)bd_cancelImageLoadForState:(UIControlState)state
{
    BDWebImageRequest *request = [[self imageSetter] imageRequestForState:state];
    if (request) {
        [request cancel];
        [[self imageSetter] setImageRequest:nil state:state];
    }
}

- (void)bd_cancelBackgroundImageLoadForState:(UIControlState)state
{
    BDWebImageRequest *request = [[self imageSetter] backgroundRequestForState:state];
    if (request) {
        [request cancel];
        [[self imageSetter] setBackgroundRequest:nil state:state];
    }
}

static char STRING_KEY_IMAGE_SETTER;

- (BDWebImageButtonImageSetter *)imageSetter
{
    return objc_getAssociatedObject(self, &STRING_KEY_IMAGE_SETTER);
}

- (void)setImageSetter:(BDWebImageButtonImageSetter *)imageRequest
{
    objc_setAssociatedObject(self, &STRING_KEY_IMAGE_SETTER, imageRequest, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *)bd_imageURLForState:(UIControlState)state {
    BDWebImageRequest *request = [[self imageSetter] imageRequestForState:state];
    return request.currentRequestURL;
}

- (void)setBd_isOpenDownsample:(BOOL)bd_isOpenDownsample {
    objc_setAssociatedObject(self, @selector(bd_isOpenDownsample), @(bd_isOpenDownsample), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bd_isOpenDownsample {
    return [(NSNumber *)objc_getAssociatedObject(self, @selector(bd_isOpenDownsample)) boolValue];
}
@end
