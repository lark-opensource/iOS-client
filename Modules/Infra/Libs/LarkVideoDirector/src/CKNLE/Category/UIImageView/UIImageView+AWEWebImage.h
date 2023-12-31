//
//  UIImageView+AWEWebImage.h
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import <UIKit/UIKit.h>


typedef NS_OPTIONS(NSUInteger, AWEWebImageOptions) {
    // 通用
    AWEWebImageOptionsSetImageWithFadeAnimation = 1<<0,
    AWEWebImageOptionsAllowBackgroundTask = 1<<1,
    AWEWebImageOptionsAvoidSetImage = 1<<2,
    
    // 仅在使用BDWebImage时生效
    AWEWebImageOptionsDefaultPriority = 1<<3, ///<如果在等待队列中，任务会以优先级排序，下载中的任务优先级对应operationPriority
    AWEWebImageOptionsLowPriority = 1<<4,
    AWEWebImageOptionsHighPriority = 1<<5,
    
    AWEWebImageOptionsNotCacheToMemory = 1<<6,///<下载后是否忽略缓存到内存，默认缓存
    AWEWebImageOptionsNotCacheToDisk = 1<<7,///<下载后是否忽略缓存到磁盘，默认缓存
    
    AWEWebImageOptionsIgnoreMemoryCache = 1<<8,
    
    AWEWebImageOptionsIgnoreDiskCache = 1<<9,
    
    AWEWebImageOptionsNeedCachePath = 1<<10,///<结果中文件缓存路径是否为必须
    AWEWebImageOptionsIgnoreImage = 1<<11,///<结果是否忽略image
    
    AWEWebImageOptionsIgnoreQueue = 1<<12,///<是否忽略队列，直接开始请求
    
    AWEWebImageOptionsSetAnimationDefault = 1<<13,
    
    AWEWebImageOptionsDefaultOptions = 1<<14,
    AWEWebImageOptionsIgnoreCache = 1<<15,
    
    // 仅在使用YYWebImage时生效
    /// Show network activity on status bar when download image.
    AWEWebImageOptionsShowNetworkActivity = 1<<16,
    
    /// Display progressive/interlaced/baseline image during download (same as web browser).
    AWEWebImageOptionsProgressive = 1<<17,
    
    /// Display blurred progressive JPEG or interlaced PNG image during download.
    /// This will ignore baseline image for better user experience.
    AWEWebImageOptionsProgressiveBlur = 1<<18,
    
    /// Use NSURLCache instead of YYImageCache.
    AWEWebImageOptionsUseNSURLCache = 1<<19,
    
    /// Allows untrusted SSL ceriticates.
    AWEWebImageOptionsAllowInvalidSSLCertificates = 1<<20,
    
    /// Handles cookies stored in NSHTTPCookieStore.
    AWEWebImageOptionsHandleCookies = 1<<21,
    
    /// Load the image from remote and refresh the image cache.
    AWEWebImageOptionsRefreshImageCache = 1<<22,
    
    /// Do not change the view's image before set a new URL to it.
    AWEWebImageOptionsIgnorePlaceHolder = 1<<23,
    
    /// Ignore image decoding.
    /// This may used for image downloading without display.
    AWEWebImageOptionsIgnoreImageDecoding = 1<<24,
    
    /// Ignore multi-frame image decoding.
    /// This will handle the GIF/APNG/WebP/ICO image as single frame image.
    AWEWebImageOptionsIgnoreAnimatedImage = 1<<25,
    
    /// This flag will add the URL to a list (in memory) when the URL fail to be downloaded,
    /// so the library won't keep trying.
    AWEWebImageOptionsIgnoreFailedURL = 1<<26,
};

NS_ASSUME_NONNULL_BEGIN


typedef void (^AWEWebImageCompletionBlock)(UIImage * _Nullable image,
                                           NSURL * _Nullable url,
                                           NSError * _Nullable error);

typedef void(^AWEWebImageProgressBlock)(double progressValue);

typedef UIImage * (^AWEWebImageTransformBlock)(UIImage *_Nullable image , NSURL *_Nullable url);

@interface UIImageView (AWEWebImageRequest)

#pragma mark - Normal

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray;

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder;

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                           options:(AWEWebImageOptions)options;

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                        completion:(nullable AWEWebImageCompletionBlock)completion;

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                           options:(AWEWebImageOptions)options
                        completion:(nullable AWEWebImageCompletionBlock)completion;

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                         cacheName:(nullable NSString *)cacheName
                           options:(AWEWebImageOptions)options
                        completion:(nullable AWEWebImageCompletionBlock)completion;

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
               downgradingURLArray:(nullable NSArray *)downgradingUrlArray
                       placeholder:(nullable UIImage *)placeholder
                           options:(AWEWebImageOptions)options
                        completion:(nullable AWEWebImageCompletionBlock)completion;

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                           options:(AWEWebImageOptions)options
                          progress:(nullable AWEWebImageProgressBlock)progress
                       postProcess:(nullable UIImage *(^)(UIImage * image))postProcessBlock
                        completion:(nullable AWEWebImageCompletionBlock)completion;

- (void)aweme_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                         cacheName:(nullable NSString *)cacheName
                           options:(AWEWebImageOptions)options
                          progress:(nullable AWEWebImageProgressBlock)progress
                       postProcess:(nullable UIImage *(^)(UIImage * _Nullable image))postProcessBlock
                        completion:(nullable AWEWebImageCompletionBlock)completion;

- (void)aweme_setImageWithURL:(nullable NSURL *)imageUrl;

- (void)aweme_setImageWithURL:(nullable NSURL *)imageUrl
                  placeholder:(nullable UIImage *)placeholder;

- (void)aweme_setImageWithURL:(nullable NSURL *)imageUrl
                      options:(AWEWebImageOptions)options;

- (void)aweme_setImageWithURL:(nullable NSURL *)imageUrl
                  placeholder:(nullable UIImage *)placeholder
                   completion:(nullable AWEWebImageCompletionBlock)completion;

- (void)aweme_setImageWithURL:(nullable NSURL *)imageUrl
                  placeholder:(nullable UIImage *)placeholder
                      options:(AWEWebImageOptions)options
                   completion:(nullable AWEWebImageCompletionBlock)completion;

- (void)aweme_setImageWithURL:(nullable NSURL *)imageUrl
                  placeholder:(nullable UIImage *)placeholder
                      options:(AWEWebImageOptions)options
                     progress:(nullable AWEWebImageProgressBlock)progress
                  postProcess:(nullable UIImage *(^)(UIImage *_Nullable image))postProcessBlock
                   completion:(nullable AWEWebImageCompletionBlock)completion;

- (void)aweme_setImageWithURL:(nullable NSURL *)imageUrl
                  placeholder:(nullable UIImage *)placeholder
                    cacheName:(nullable NSString *)cacheName
                      options:(AWEWebImageOptions)options
                     progress:(nullable AWEWebImageProgressBlock)progress
                  postProcess:(nullable UIImage *(^)(UIImage * image))postProcessBlock
                   completion:(nullable AWEWebImageCompletionBlock)completion;

- (void)reDrawImage:(nullable UIImage *)image inContainerSize:(CGSize)size;
//
- (void)aweme_cancelImageRequest;

+ (void)aweme_requestImageWithURLArray:(nullable NSArray *)imageUrlArray
                               options:(AWEWebImageOptions)options
                              progress:(nullable AWEWebImageProgressBlock)progress
                            completion:(nullable AWEWebImageCompletionBlock)completion;

+ (void)aweme_requestImageWithURLArray:(nullable NSArray *)imageUrlArray
                               options:(AWEWebImageOptions)options
                            completion:(nullable AWEWebImageCompletionBlock)completion;
//
+ (void)aweme_requestImageWithURLArray:(nullable NSArray *)imageUrlArray
                            completion:(nullable AWEWebImageCompletionBlock)completion;

+ (void)aweme_requestImageWithURLArray:(nullable NSArray *)imageUrlArray
                             cacheName:(nullable NSString *)cacheName
                            completion:(nullable AWEWebImageCompletionBlock)completion;

+ (void)aweme_requestImageWithURLArray:(nullable NSArray *)imageUrlArray;

+ (void)aweme_requestImageWithURL:(nullable NSURL *)imageUrl;

+ (void)aweme_requestImageWithURL:(nullable NSURL *)imageUrl
                       completion:(nullable AWEWebImageCompletionBlock)completion;

+ (void)aweme_requestImageWithURL:(nullable NSURL *)imageUrl
                          options:(AWEWebImageOptions)options
                       completion:(nullable AWEWebImageCompletionBlock)completion;

+ (void)aweme_requestImageWithURL:(nullable NSURL *)imageUrl
                          options:(AWEWebImageOptions)options
                         progress:(nullable AWEWebImageProgressBlock)progress
                       completion:(nullable AWEWebImageCompletionBlock)completion;

+ (void)aweme_requestImageWithURL:(nullable NSURL *)imageUrl
                          options:(AWEWebImageOptions)options
                        cacheName:(nullable NSString *)cacheName
                         progress:(nullable AWEWebImageProgressBlock)progress
                       completion:(nullable AWEWebImageCompletionBlock)completion;

+ (NSString *)customCacheName;
@end

@interface UIImageView (AWEAnimatedImageView)

+ (nullable UIImageView *)aweme_animatedImageView;

- (void)updateImageViewAnimationType:(BOOL)animationTypeReciprocating;

@end

@interface UIImage (AWEAnimatedImage)

+ (nullable UIImage *)aweme_animatedImage;

@end
NS_ASSUME_NONNULL_END
