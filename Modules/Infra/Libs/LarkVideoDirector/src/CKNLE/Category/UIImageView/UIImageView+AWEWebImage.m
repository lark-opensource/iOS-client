//
//  UIImageView+AWEWebImage.m
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import "UIImageView+AWEWebImage.h"
#import "AWEWebImageOptions.h"
#import <AWEBaseLib/AWEMacros.h>
#import "NSArray+AnimatedType.h"
#import "AWEWebImageTransformer.h"
#import "AWEWebImageTransformProtocol.h"
#import "AWECustomWebImageManager.h"

static NSString *tosImagePattern = nil;
static NSString *tosImageFormat = nil;

@implementation UIImageView (AWEWebImageRequest)

// AB控制 默认指定一个目录，如果cacheName传空会默认索引到这个自定义目录，目的是区分sdk内部的图片缓存目录
+ (NSString *)customCacheName {
//    id<AWEBDWebImageABTestProtocol> awe_BDWebImageABTest = [[AWEAppContext appContext] objectForProtocol:@protocol(AWEBDWebImageABTestProtocol)];
//    NSString* custom_Cache_Name = nil;
//    if (awe_BDWebImageABTest.enableAWEWebImageInternalBDWebImage){
//        custom_Cache_Name = @"awe_image_request_cache";
//    }
//    return custom_Cache_Name;
    return @"awe_image_request_cache";
}

#pragma mark - Request with URL array

- (void)aweme_setImageWithURLArray:(NSArray *)imageUrlArray
{
    [self aweme_setImageWithURLArray:imageUrlArray placeholder:nil];
}

- (void)aweme_setImageWithURLArray:(NSArray *)imageUrlArray
                       placeholder:(UIImage *)placeholder
{
    [self aweme_setImageWithURLArray:imageUrlArray
                         placeholder:placeholder
                             options:AWEWebImageOptionsSetImageWithFadeAnimation | AWEWebImageOptionsDefaultOptions
                          completion:nil];
}

- (void)aweme_setImageWithURLArray:(NSArray *)imageUrlArray
                           options:(AWEWebImageOptions)options
{
    [self aweme_setImageWithURLArray:imageUrlArray
                         placeholder:nil
                             options:options
                          completion:nil];
}

- (void)aweme_setImageWithURLArray:(NSArray *)imageUrlArray
                       placeholder:(UIImage *)placeholder
                        completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_setImageWithURLArray:imageUrlArray
                         placeholder:placeholder
                             options:AWEWebImageOptionsSetImageWithFadeAnimation | AWEWebImageOptionsDefaultOptions
                          completion:completion];
}

- (void)aweme_setImageWithURLArray:(NSArray *)imageUrlArray
                       placeholder:(UIImage *)placeholder
                           options:(AWEWebImageOptions)options
                        completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_setImageWithURLArray:imageUrlArray
                         placeholder:placeholder
                             options:options
                            progress:nil
                         postProcess:nil
                          completion:completion];
}

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                         cacheName:(nullable NSString *)cacheName
                           options:(AWEWebImageOptions)options
                        completion:(nullable AWEWebImageCompletionBlock)completion
{
    [self aweme_setImageWithURLArray:imageUrlArray
                         placeholder:placeholder
                           cacheName:cacheName
                             options:options
                            progress:nil
                         postProcess:nil
                          completion:completion];
}

- (void)aweme_setImageWithURLArray:(NSArray *)imageUrlArray
                       placeholder:(UIImage *)placeholder
                           options:(AWEWebImageOptions)options
                          progress:(AWEWebImageProgressBlock)progress
                       postProcess:(UIImage *(^)(UIImage * _Nullable image))postProcessBlock
                        completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_setImageWithURLArray:imageUrlArray
                         placeholder:placeholder
                           cacheName:nil
                             options:options
                            progress:progress
                         postProcess:postProcessBlock
                          completion:completion];
}

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                         cacheName:(nullable NSString *)cacheName
                           options:(AWEWebImageOptions)options
                          progress:(nullable AWEWebImageProgressBlock)progress
                       postProcess:(nullable UIImage *(^)(UIImage * _Nullable image))postProcessBlock
                        completion:(nullable AWEWebImageCompletionBlock)completion
{
    [self _setImageWithURLArray:imageUrlArray
                    placeholder:placeholder
                      cacheName:cacheName
                        options:options
                       progress:progress
                    postProcess:postProcessBlock
                     completion:completion];
}

#pragma mark - tansformObject

- (void)aweme_setImageWithURLArray:(NSArray *)imageUrlArray
                       placeholder:(UIImage *)placeholder
                           options:(AWEWebImageOptions)options
                   transformObject:(id<AWEWebImageTransformProtocol>)transformObject
                        completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_setImageWithURLArray:imageUrlArray
                         placeholder:placeholder
                             options:options
                            progress:nil
                     transformObject:transformObject
                          completion:completion];
}

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                           options:(AWEWebImageOptions)options
                          progress:(nullable AWEWebImageProgressBlock)progress
                   transformObject:(nullable id<AWEWebImageTransformProtocol>)transformObject
                        completion:(nullable AWEWebImageCompletionBlock)completion
{
    [self aweme_setImageWithURLArray:imageUrlArray
                         placeholder:placeholder
                           cacheName:nil
                             options:options
                            progress:progress
                     transformObject:transformObject
                          completion:completion];
}

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                         cacheName:(nullable NSString *)cacheName
                           options:(AWEWebImageOptions)options
                          progress:(nullable AWEWebImageProgressBlock)progress
                   transformObject:(nullable id<AWEWebImageTransformProtocol>)transformObject
                        completion:(nullable AWEWebImageCompletionBlock)completion
{
    [self _setImageWithURLArray:imageUrlArray
                    placeholder:placeholder
                      cacheName:cacheName
                        options:options
                       progress:progress
                    transformObject:transformObject
                     completion:completion];
}

#pragma mark - downgradingUrlArray

- (void)aweme_setImageWithURLArray:(NSArray *)imageUrlArray
               downgradingURLArray:(NSArray *)downgradingUrlArray
                       placeholder:(UIImage *)placeholder
                           options:(AWEWebImageOptions)options
                        completion:(AWEWebImageCompletionBlock)completion
{
    @weakify(self);
    [self aweme_setImageWithURLArray:imageUrlArray
                         placeholder:placeholder
                             options:options
                          completion:^(UIImage *image, NSURL *url, NSError *error) {
                              @strongify(self);
                              if (error) {
                                  [self aweme_setImageWithURLArray:downgradingUrlArray placeholder:placeholder options:options completion:completion];
                                  return;
                              }
                              AWEBLOCK_INVOKE(completion, image, url, error);
                          }];
}

#pragma mark - Request image with URL

- (void)aweme_setImageWithURL:(NSURL *)imageUrl
{
    [self aweme_setImageWithURLArray:[UIImageView _safeURLArrayWitURL:imageUrl]];
}

- (void)aweme_setImageWithURL:(NSURL *)imageUrl
                  placeholder:(UIImage *)placeholder
{
    [self aweme_setImageWithURLArray:[UIImageView _safeURLArrayWitURL:imageUrl]
                         placeholder:placeholder];
}

- (void)aweme_setImageWithURL:(NSURL *)imageUrl
                      options:(AWEWebImageOptions)options
{
    [self aweme_setImageWithURLArray:[UIImageView _safeURLArrayWitURL:imageUrl]
                             options:options];
}

- (void)aweme_setImageWithURL:(NSURL *)imageUrl
                  placeholder:(UIImage *)placeholder
                   completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_setImageWithURL:imageUrl
                    placeholder:placeholder
                        options:AWEWebImageOptionsSetImageWithFadeAnimation | AWEWebImageOptionsDefaultOptions
                     completion:completion];
}

- (void)aweme_setImageWithURL:(NSURL *)imageUrl
                  placeholder:(UIImage *)placeholder
                      options:(AWEWebImageOptions)options
                   completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_setImageWithURLArray:[UIImageView _safeURLArrayWitURL:imageUrl]
                         placeholder:placeholder
                             options:options
                          completion:completion];
}

- (void)aweme_setImageWithURL:(NSURL *)imageUrl
                  placeholder:(UIImage *)placeholder
                      options:(AWEWebImageOptions)options
                     progress:(AWEWebImageProgressBlock)progress
                  postProcess:(UIImage *(^)(UIImage * image))postProcessBlock
                   completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_setImageWithURLArray:[UIImageView _safeURLArrayWitURL:imageUrl]
                         placeholder:placeholder
                             options:options
                            progress:progress
                         postProcess:postProcessBlock
                          completion:completion];
}

- (void)aweme_setImageWithURL:(NSURL *)imageUrl
                  placeholder:(UIImage *)placeholder
                    cacheName:(NSString *)cacheName
                      options:(AWEWebImageOptions)options
                     progress:(AWEWebImageProgressBlock)progress
                  postProcess:(UIImage *(^)(UIImage * image))postProcessBlock
                   completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_setImageWithURLArray:[UIImageView _safeURLArrayWitURL:imageUrl]
                         placeholder:placeholder
                           cacheName:cacheName
                             options:options
                            progress:progress
                         postProcess:postProcessBlock
                          completion:completion];
}

- (void)aweme_cancelImageRequest
{
    [self bd_cancelImageLoad];
}

#pragma mark - Class methods request image with URL array

+ (void)aweme_requestImageWithURLArray:(NSArray *)imageUrlArray
{
    [self aweme_requestImageWithURLArray:imageUrlArray
                              completion:nil];
}

+ (void)aweme_requestImageWithURLArray:(NSArray *)imageUrlArray
                            completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_requestImageWithURLArray:imageUrlArray
                                 options:AWEWebImageOptionsSetImageWithFadeAnimation | AWEWebImageOptionsDefaultOptions
                              completion:completion];
}

+ (void)aweme_requestImageWithURLArray:(nullable NSArray *)imageUrlArray
                             cacheName:(nullable NSString *)cacheName
                            completion:(nullable AWEWebImageCompletionBlock)completion
{
    [self aweme_requestImageWithURLArray:imageUrlArray
                                 options:AWEWebImageOptionsSetImageWithFadeAnimation | AWEWebImageOptionsDefaultOptions
                               cacheName:cacheName
                                progress:nil
                         transformObject:nil
                              completion:completion];
}

+ (void)aweme_requestImageWithURLArray:(NSArray *)imageUrlArray
                       transformObject:(id<AWEWebImageTransformProtocol>)transformObject
                            completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_requestImageWithURLArray:imageUrlArray
                                 options:AWEWebImageOptionsSetImageWithFadeAnimation | AWEWebImageOptionsDefaultOptions
                                progress:nil
                         transformObject:transformObject
                              completion:completion];
}

+ (void)aweme_requestImageWithURLArray:(NSArray *)imageUrlArray
                               options:(AWEWebImageOptions)options
                            completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_requestImageWithURLArray:imageUrlArray
                                 options:options
                                progress:nil
                              completion:completion];
}

+ (void)aweme_requestImageWithURLArray:(NSArray *)imageUrlArray
                               options:(AWEWebImageOptions)options
                              progress:(AWEWebImageProgressBlock)progress
                            completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_requestImageWithURLArray:imageUrlArray
                                 options:options
                                progress:progress
                         transformObject:nil
                              completion:completion];
}

+ (void)aweme_requestImageWithURLArray:(NSArray *)imageUrlArray
                               options:(AWEWebImageOptions)options
                              progress:(AWEWebImageProgressBlock)progress
                       transformObject:(id<AWEWebImageTransformProtocol>)transformObject
                            completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_requestImageWithURLArray:imageUrlArray
                                 options:options
                               cacheName:nil
                                progress:progress
                         transformObject:transformObject
                              completion:completion];
}

+ (void)aweme_requestImageWithURLArray:(NSArray *)imageUrlArray
                               options:(AWEWebImageOptions)options
                              cacheName:(NSString *)cacheName
                              progress:(AWEWebImageProgressBlock)progress
                       transformObject:(id<AWEWebImageTransformProtocol>)transformObject
                            completion:(AWEWebImageCompletionBlock)completion
{
    [self _requestImageWithURLArray:imageUrlArray
                            options:options
                          cacheName:cacheName
                           progress:progress
                    transformObject:transformObject
                         completion:completion];
}

#pragma mark - Class methods request image with URL

+ (void)aweme_requestImageWithURL:(NSURL *)imageUrl
{
    [self aweme_requestImageWithURL:imageUrl
                            options:AWEWebImageOptionsSetImageWithFadeAnimation | AWEWebImageOptionsDefaultOptions
                         completion:nil];
}

+ (void)aweme_requestImageWithURL:(NSURL *)imageUrl
                       completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_requestImageWithURL:imageUrl
                            options:AWEWebImageOptionsSetImageWithFadeAnimation | AWEWebImageOptionsDefaultOptions
                         completion:completion];
}

+ (void)aweme_requestImageWithURL:(NSURL *)imageUrl
                          options:(AWEWebImageOptions)options
                       completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_requestImageWithURL:imageUrl
                            options:options
                           progress:nil
                         completion:completion];
}

+ (void)aweme_requestImageWithURL:(NSURL *)imageUrl
                          options:(AWEWebImageOptions)options
                         progress:(AWEWebImageProgressBlock)progress
                       completion:(AWEWebImageCompletionBlock)completion
{
    [self aweme_requestImageWithURL:imageUrl
                            options:options
                          cacheName:nil
                           progress:progress
                         completion:completion];
}

+ (void)aweme_requestImageWithURL:(NSURL *)imageUrl
                          options:(AWEWebImageOptions)options
                        cacheName:(NSString *)cacheName
                         progress:(AWEWebImageProgressBlock)progress
                       completion:(AWEWebImageCompletionBlock)completion
{
    [self _requestImageWithURLArray:[UIImageView _safeURLArrayWitURL:imageUrl]
                            options:options
                          cacheName:cacheName
                           progress:progress
                         completion:completion];
}

#pragma mark - Deprecated

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                          imageURI:(nullable NSString *)uri
                      expectedSize:(CGSize)size
{
    [self aweme_setImageWithURLArray:imageUrlArray];
}

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                          imageURI:(nullable NSString *)uri
                      expectedSize:(CGSize)size
                           options:(AWEWebImageOptions)options
{
    [self aweme_setImageWithURLArray:imageUrlArray options:options];
}

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                          imageURI:(nullable NSString *)uri
                      expectedSize:(CGSize)size
                       placeholder:(nullable UIImage *)placeholder
                        completion:(nullable AWEWebImageCompletionBlock)completion
{
    [self aweme_setImageWithURLArray:imageUrlArray placeholder:placeholder completion:completion];
}

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                          imageURI:(nullable NSString *)uri
                      expectedSize:(CGSize)size
                       placeholder:(nullable UIImage *)placeholder
                           options:(AWEWebImageOptions)options
                        completion:(nullable AWEWebImageCompletionBlock)completion
{
    [self aweme_setImageWithURLArray:imageUrlArray placeholder:placeholder options:options completion:completion];
}


- (void)aweme_setImageWithURL:(nullable NSURL *)imageUrl
                     imageURI:(NSString *)uri
                 expectedSize:(CGSize)size
                  placeholder:(nullable UIImage *)placeholder
                      options:(AWEWebImageOptions)options
                   completion:(nullable AWEWebImageCompletionBlock)completion
{
    [self aweme_setImageWithURL:imageUrl placeholder:placeholder options:options completion:completion];
}

#pragma mark - Private

- (BOOL)confirmAnimatedKitIsBDWebImage
{
//    BOOL enable = [APPContextIMP(AWEResizableImageConfig) compatibleAnimatedImageView];
//    if (enable && [self isKindOfClass:[YYAnimatedImageView class]]) {
//        return NO;
//    }
    return YES;
}

- (void)_setImageWithURLArray:(NSArray *)imageUrlArray
                  placeholder:(UIImage *)placeholder
                    cacheName:(NSString *)cacheName
                      options:(AWEWebImageOptions)options
                     progress:(AWEWebImageProgressBlock)progress
                  postProcess:(UIImage *(^)(UIImage * image))postProcessBlock
                   completion:(AWEWebImageCompletionBlock)completion
{
    BOOL animationTypeReciprocating = imageUrlArray.animationTypeReciprocating;
    [self updateImageViewAnimationType:animationTypeReciprocating];
    [self _bd_fetchImageWithMonitorUpload:imageUrlArray
                              placeholder:placeholder
                                cacheName:cacheName
                                  options:options
                                 progress:progress
                              postProcess:postProcessBlock
                               completion:^(UIImage *image, NSURL *url, NSUInteger index, BDWebImageResultFrom from, NSError *error) {
        AWEBLOCK_INVOKE(completion, image, url, error);
    }];
}

// only BDWebImage supports custom transformer
- (void)_setImageWithURLArray:(NSArray *)imageUrlArray
                  placeholder:(UIImage *)placeholder
                    cacheName:(NSString *)cacheName
                      options:(AWEWebImageOptions)options
                     progress:(AWEWebImageProgressBlock)progress
              transformObject:(id<AWEWebImageTransformProtocol>)transformObject
                   completion:(AWEWebImageCompletionBlock)completion
{
    BOOL animationTypeReciprocating = imageUrlArray.animationTypeReciprocating;
    [self updateImageViewAnimationType:animationTypeReciprocating];
    [self _bd_fetchImageWithMonitorUpload:imageUrlArray
                              placeholder:placeholder
                                cacheName:cacheName
                                  options:options
                                 progress:progress
                          transformObject:transformObject
                               completion:^(UIImage *image, NSURL *url, NSUInteger index, BDWebImageResultFrom from, NSError *error) {
        AWEBLOCK_INVOKE(completion, image, url, error);
    }];
}

- (void)reDrawImage:(UIImage *)image inContainerSize:(CGSize)size
{
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @strongify(self);
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize containerSize = CGSizeMake(size.width * scale, size.height * scale);
        CGSize picSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate(nil, containerSize.width, containerSize.height, 8, containerSize.width * 4, colorSpaceRef, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpaceRef);
        CGRect imageRect = [self p_aspectFillModeFrameOfContentWithContentSize:picSize containerSize:containerSize];
        CGContextDrawImage(ctx, imageRect, image.CGImage);
        CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
        UIImage *finalImage = [UIImage imageWithCGImage:cgImage scale:scale orientation:UIImageOrientationUp];
        CGImageRelease(cgImage);
        CGContextRelease(ctx);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = finalImage;
        });
    });
}
- (CGRect)p_aspectFillModeFrameOfContentWithContentSize:(CGSize)contentSize
                                        containerSize:(CGSize)containerSize
{
    if (contentSize.width == 0 || contentSize.height == 0) {
        return CGRectMake(0, 0, containerSize.width, containerSize.height);
    }
    
    if (contentSize.width == contentSize.height &&
        containerSize.width == containerSize.height) {
        return CGRectMake(0, 0, containerSize.width, containerSize.height);
    }
    CGRect frameImage = CGRectMake(0.0, 0.0, contentSize.width, contentSize.height);
    CGFloat ratioW = containerSize.width/contentSize.width;
    CGFloat ratioH = containerSize.height/contentSize.height;
    CGFloat ratio = MAX(ratioW, ratioH);
    frameImage.size = CGSizeMake(floor(ratio * contentSize.width), floor(ratio * contentSize.height));
    frameImage.origin.x = containerSize.width/2 - frameImage.size.width/2;
    frameImage.origin.y = containerSize.height/2 - frameImage.size.height/2;
    return frameImage;
}

#pragma mark - BDWebImage private methods

- (void)_bd_fetchImageWithMonitorUpload:(NSArray *)imageUrlArray
                            placeholder:(UIImage *)placeholder
                              cacheName:(NSString *)cacheName
                                options:(AWEWebImageOptions)options
                               progress:(AWEWebImageProgressBlock)progress
                            postProcess:(UIImage *(^)(UIImage * image))postProcessBlock
                             completion:(_AWEBDImageRequestCompletionBlock)completion
{
    [self _bd_fetchImageWithURLArray:imageUrlArray placeholder:placeholder cacheName:cacheName index:0 options:options progress:progress postProcess:postProcessBlock completion:completion];
}

- (void)_bd_fetchImageWithMonitorUpload:(NSArray *)imageUrlArray
                            placeholder:(UIImage *)placeholder
                              cacheName:(NSString *)cacheName
                                options:(AWEWebImageOptions)options
                               progress:(AWEWebImageProgressBlock)progress
                        transformObject:(id <AWEWebImageTransformProtocol>)transformObject
                             completion:(_AWEBDImageRequestCompletionBlock)completion
{
    [self _bd_fetchImageWithURLArray:imageUrlArray placeholder:placeholder cacheName:cacheName index:0 options:options progress:progress transformObject:transformObject completion:completion];
}

- (void)_bd_fetchImageWithURLArray:(NSArray *)imageUrlArray
                       placeholder:(UIImage *)placeholder
                         cacheName:(NSString *)cacheName
                             index:(NSUInteger)index
                           options:(AWEWebImageOptions)options
                          progress:(AWEWebImageProgressBlock)progress
                       postProcess:(UIImage *(^)(UIImage * image))postProcessBlock
                        completion:(_AWEBDImageRequestCompletionBlock)completion
{
    [self _bd_fetchImageWithURLArray:imageUrlArray placeholder:placeholder cacheName:cacheName index:index options:options progress:progress transformer:!postProcessBlock ? nil : [BDBlockTransformer transformWithBlock:postProcessBlock] completion:completion];
}

- (void)_bd_fetchImageWithURLArray:(NSArray *)imageUrlArray
                       placeholder:(UIImage *)placeholder
                         cacheName:(NSString *)cacheName
                             index:(NSUInteger)index
                           options:(AWEWebImageOptions)options
                          progress:(AWEWebImageProgressBlock)progress
                 transformObject:(id <AWEWebImageTransformProtocol>)transformObject
                        completion:(_AWEBDImageRequestCompletionBlock)completion
{
    [self _bd_fetchImageWithURLArray:imageUrlArray placeholder:placeholder cacheName:cacheName index:index options:options progress:progress transformer:!transformObject ? nil : [AWEWebImageTransformer transformWithObject:transformObject] completion:completion];
    
}

- (void)_bd_fetchImageWithURLArray:(NSArray *)imageUrlArray
                       placeholder:(UIImage *)placeholder
                         cacheName:(NSString *)cacheName
                             index:(NSUInteger)index
                           options:(AWEWebImageOptions)options
                          progress:(AWEWebImageProgressBlock)progress
                       transformer:(BDBaseTransformer *)transformer
                        completion:(_AWEBDImageRequestCompletionBlock)completion
{
    if (BTD_isEmptyArray(imageUrlArray) || index >= imageUrlArray.count || ![UIImageView _validURL:imageUrlArray[index]]) {
        [self setImage:placeholder];
        AWEBLOCK_INVOKE(completion, nil, nil, index, BDWebImageResultFromNone, nil);
        return;
    }
    

    BDWebImageRequest *request =
    
    [self bd_setImageWithURL:imageUrlArray.firstObject
             alternativeURLs:imageUrlArray
                 placeholder:placeholder
                     options:AWE_BDWebImageOptions(options)
                   cacheName:!BTD_isEmptyString(cacheName) ? cacheName : [UIImageView customCacheName]
                 transformer:transformer
                    progress:!progress ? nil : ^(BDWebImageRequest *request, NSInteger receivedSize, NSInteger expectedSize) {
                         progress((double)receivedSize/expectedSize);
                     }
                   completion:!completion ? nil : ^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                       NSURL *currentURL = request.currentRequestURL;
                       completion(image, currentURL, request.currentIndex, from, error);
                   }];
    request.bizTag = @"image_view";
}

#pragma mark - Private class methods

+ (void)_requestImageWithURLArray:(NSArray *)imageUrlArray
                          options:(AWEWebImageOptions)options
                        cacheName:(NSString *)cacheName
                         progress:(AWEWebImageProgressBlock)progress
                       completion:(AWEWebImageCompletionBlock)completion
{
    [self _bd_requestImageWithMonitorUpload:imageUrlArray
                                    options:options
                                  cacheName:cacheName
                                   progress:progress
                                  transform:nil
                                 completion:^(UIImage *image, NSURL *url, NSUInteger index, BDWebImageResultFrom from, NSError *error) {
        AWEBLOCK_INVOKE(completion, image, url, error);
    }];
}

+ (void)_requestImageWithURLArray:(NSArray *)imageUrlArray
                          options:(AWEWebImageOptions)options
                          cacheName:(NSString *)cacheName
                         progress:(AWEWebImageProgressBlock)progress
                  transformObject:(id <AWEWebImageTransformProtocol>)transformObject
                       completion:(AWEWebImageCompletionBlock)completion
{
    [self _bd_requestImageWithMonitorUpload:imageUrlArray
                                    options:options
                                  cacheName:cacheName
                                   progress:progress
                                  transformObject:transformObject
                                 completion:^(UIImage *image, NSURL *url, NSUInteger index, BDWebImageResultFrom from, NSError *error) {
        AWEBLOCK_INVOKE(completion, image, url, error);
    }];
}

#pragma mark - BDWebImage private class methods

+ (void)_bd_requestImageWithMonitorUpload:(NSArray *)imageUrlArray
                                  options:(AWEWebImageOptions)options
                                cacheName:(NSString *)cacheName
                                 progress:(AWEWebImageProgressBlock)progress
                                transform:(AWEWebImageTransformBlock)transform
                               completion:(_AWEBDImageRequestCompletionBlock)completion
{
    [self _bd_requestImageWithURLArray:imageUrlArray
                               options:options
                             cacheName:nil
                                 index:0
                              progress:progress
                            completion:completion];
}

// only BDWebImage supports custom transformer
+ (void)_bd_requestImageWithMonitorUpload:(NSArray *)imageUrlArray
                                  options:(AWEWebImageOptions)options
                                cacheName:(NSString *)cacheName
                                 progress:(AWEWebImageProgressBlock)progress
                                transformObject:(id <AWEWebImageTransformProtocol> )transformObject
                               completion:(_AWEBDImageRequestCompletionBlock)completion
{
    [self _bd_requestImageWithURLArray:imageUrlArray
                               options:options
                             cacheName:cacheName
                                 index:0
                              progress:progress
                       transformObject:transformObject
                            completion:completion];
}

+ (void)_bd_requestImageWithURLArray:(NSArray *)imageUrlArray
                             options:(AWEWebImageOptions)options
                           cacheName:(NSString *)cacheName
                               index:(NSUInteger)index
                            progress:(AWEWebImageProgressBlock)progress
                          completion:(_AWEBDImageRequestCompletionBlock)completion
{
    if(BTD_isEmptyArray(imageUrlArray) || index >= imageUrlArray.count || ![self _validURL:imageUrlArray[index]]) {
        AWEBLOCK_INVOKE(completion, nil, nil, index, BDWebImageResultFromNone, nil);
        return;
    }
    NSURL *imageURL = imageUrlArray[index];
    imageURL = [self _safeURL:imageURL];
    
    @weakify(self);
    
    [[BDWebImageManager sharedManager] requestImage:imageURL
                                    alternativeURLs:nil
                                            options:BDImageRequestDefaultPriority
                                          cacheName:!BTD_isEmptyString(cacheName) ? cacheName : [UIImageView customCacheName]
                                           progress:^(BDWebImageRequest *request, NSInteger receivedSize, NSInteger expectedSize) {
        AWEBLOCK_INVOKE(progress, (double)receivedSize/expectedSize);
    } complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        NSURL *currentURL = request.currentRequestURL;
        if (image && !error) {
            AWEBLOCK_INVOKE(completion, image, currentURL, index, from, error);
            return;
        }

        NSUInteger next = index + 1;
        if (next >= imageUrlArray.count) {
            AWEBLOCK_INVOKE(completion, image, currentURL, index, from, error);
            return;
        }
        @strongify(self);
        [self _bd_requestImageWithURLArray:imageUrlArray
                                   options:options
                                 cacheName:cacheName
                                     index:next
                                  progress:progress
                                completion:completion];
    }];
    
}

+ (void)_bd_requestImageWithURLArray:(NSArray *)imageUrlArray
                             options:(AWEWebImageOptions)options
                           cacheName:(NSString *)cacheName
                               index:(NSUInteger)index
                            progress:(AWEWebImageProgressBlock)progress
                     transformObject:(id <AWEWebImageTransformProtocol> )transformObject
                          completion:(_AWEBDImageRequestCompletionBlock)completion
{
    if(BTD_isEmptyArray(imageUrlArray) || index >= imageUrlArray.count || ![self _validURL:imageUrlArray[index]]) {
        AWEBLOCK_INVOKE(completion, nil, nil, index, BDWebImageResultFromNone, nil);
        return;
    }
    NSURL *imageURL = imageUrlArray[index];
    imageURL = [self _safeURL:imageURL];
    
    @weakify(self);
    
    [[BDWebImageManager sharedManager] requestImage:imageURL
                                    alternativeURLs:nil
                                            options:AWE_BDWebImageOptions(options)
                                          cacheName:cacheName
                                        transformer:!transformObject ? nil : [AWEWebImageTransformer transformWithObject:transformObject]
                                           progress:^(BDWebImageRequest *request, NSInteger receivedSize, NSInteger expectedSize) {
        AWEBLOCK_INVOKE(progress, (double)receivedSize/expectedSize);
    }
                                           complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        NSURL *currentURL = request.currentRequestURL;
        if (image && !error) {
            AWEBLOCK_INVOKE(completion, image, currentURL, index, from, error);
            return;
        }
        
        NSUInteger next = index + 1;
        if (next >= imageUrlArray.count) {
            AWEBLOCK_INVOKE(completion, image, currentURL, index, from, error);
            return;
        }
        @strongify(self);
        [self _bd_requestImageWithURLArray:imageUrlArray
                                   options:options
                                 cacheName:cacheName
                                     index:next
                                  progress:progress
                           transformObject:transformObject
                                completion:completion];
    }];
}

#pragma mark - Utils

+ (BOOL)_validURL:(id)URL
{
    NSString *imageURLString = nil;
    if ([URL isKindOfClass:[NSURL class]]) {
        imageURLString = [NSString stringWithFormat:@"%@",URL];
    } else if ([URL isKindOfClass:[NSString class]]){
        imageURLString = URL;
    } else {
        return NO;
    }
    return imageURLString.length > 0;
}

+ (NSURL *)_safeURL:(id)URL
{
    if ([URL isKindOfClass:[NSString class]]) {
        return [NSURL URLWithString:URL];
    }
    return URL;
}

+ (NSArray *)_safeURLArrayWitURL:(id)URL
{
    NSURL *safeURL = [self _safeURL:URL];
    if (safeURL) {
        return @[safeURL];
    }
    return @[];
}

+ (CGSize)optimizeViewSize:(CGSize)originSize
{
    CGFloat width = originSize.width;
    CGFloat height = originSize.height;
    CGFloat optimizeWidth = width;
    CGFloat optimizeHeight = height;
    CGFloat normalWidthThreshold = 375;
    CGFloat normalHeightThreshold = 667;
    
    if (CGSizeEqualToSize(originSize, [UIScreen mainScreen].bounds.size)) {
        optimizeWidth = normalWidthThreshold;
        optimizeHeight = normalHeightThreshold;
    } else if (width == [UIScreen mainScreen].bounds.size.width) {
        optimizeWidth = 375;
        optimizeHeight = normalWidthThreshold * height / width;
    }
    return CGSizeMake(optimizeWidth, optimizeHeight);
}
@end

@implementation UIImageView (AWEAnimatedImageView)

+ (UIImageView *)aweme_animatedImageView
{
    return [[BDImageView alloc] init];
}

// 更新动图的播放样式
- (void)updateImageViewAnimationType:(BOOL)animationTypeReciprocating
{
    if (![self isKindOfClass:[BDImageView class]]) {
        return;
    }
    BDImageView *bdImageView = (BDImageView *)self;
    bdImageView.animationType =  !animationTypeReciprocating ? BDAnimatedImageAnimationTypeOrder : BDAnimatedImageAnimationTypeReciprocating;
}


@end

@implementation UIImage (AWEAnimatedImage)

+ (UIImage *)aweme_animatedImage
{
    return [[BDImage alloc] init];
}

@end
