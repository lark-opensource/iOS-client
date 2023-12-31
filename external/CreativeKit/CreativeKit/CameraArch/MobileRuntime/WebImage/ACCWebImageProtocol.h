//
//  ACCWebImageProtocol.h
//  CameraClient
//
//  Created by lxp on 2019/11/17.
//

#import <UIKit/UIKit.h>
#import "ACCServiceLocator.h"

typedef void (^ACCWebImageCompletionBlock)(UIImage * image, NSURL *url, NSError * error);
typedef void(^ACCWebImageProgressBlock)(double progressValue);

typedef NS_OPTIONS(NSUInteger, ACCWebImageOptions) {
    // General
    ACCWebImageOptionsSetImageWithFadeAnimation = 1<<0,
    ACCWebImageOptionsAllowBackgroundTask = 1<<1,
    ACCWebImageOptionsAvoidSetImage = 1<<2,
    
    // Only valid when using bdwebimage
    ACCWebImageOptionsDefaultPriority = 1<<3, ///< if the task is in the waiting queue, it will be sorted by priority, and the priority of the task in download corresponds to operationpriority
    ACCWebImageOptionsLowPriority = 1<<4,
    ACCWebImageOptionsHighPriority = 1<<5,
    
    ACCWebImageOptionsNotCacheToMemory = 1<<6,///< ignore cache to memory after download, default cache
    ACCWebImageOptionsNotCacheToDisk = 1<<7,///< ignore cache to disk after download, default cache
    
    ACCWebImageOptionsIgnoreMemoryCache = 1<<8,
    
    ACCWebImageOptionsIgnoreDiskCache = 1<<9,
    
    ACCWebImageOptionsNeedCachePath = 1<<10,///< is the file cache path required in the result
    ACCWebImageOptionsIgnoreImage = 1<<11,///< result ignored
    
    ACCWebImageOptionsIgnoreQueue = 1<<12,///< ignore the queue and start the request directly
    
    ACCWebImageOptionsSetAnimationDefault = 1<<13,
    
    ACCWebImageOptionsDefaultOptions = 1<<14,
    ACCWebImageOptionsIgnoreCache = 1<<15,
    
    // Valid only when using yywebimage
    /// Show network activity on status bar when download image.
    ACCWebImageOptionsShowNetworkActivity = 1<<16,
    
    /// Display progressive/interlaced/baseline image during download (same as web browser).
    ACCWebImageOptionsProgressive = 1<<17,
    
    /// Display blurred progressive JPEG or interlaced PNG image during download.
    /// This will ignore baseline image for better user experience.
    ACCWebImageOptionsProgressiveBlur = 1<<18,
    
    /// Use NSURLCache instead of YYImageCache.
    ACCWebImageOptionsUseNSURLCache = 1<<19,
    
    /// Allows untrusted SSL ceriticates.
    ACCWebImageOptionsAllowInvalidSSLCertificates = 1<<20,
    
    /// Handles cookies stored in NSHTTPCookieStore.
    ACCWebImageOptionsHandleCookies = 1<<21,
    
    /// Load the image from remote and refresh the image cache.
    ACCWebImageOptionsRefreshImageCache = 1<<22,
    
    /// Do not change the view's image before set a new URL to it.
    ACCWebImageOptionsIgnorePlaceHolder = 1<<23,
    
    /// Ignore image decoding.
    /// This may used for image downloading without display.
    ACCWebImageOptionsIgnoreImageDecoding = 1<<24,
    
    /// Ignore multi-frame image decoding.
    /// This will handle the GIF/APNG/WebP/ICO image as single frame image.
    ACCWebImageOptionsIgnoreAnimatedImage = 1<<25,
    
    ACCWebImageOptionsIgnoreFailedURL = 1<<26,
};


@protocol ACCWebImageProtocol <NSObject>

/// get imageView.image by imageUrlArray
/// @param imageView the imageView of webimage needs to be displayed
/// @param imageUrlArray get webImage by imageUrlArray
+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray;

/// get imageView.image by imageUrlArray
/// @param imageView the imageView of webimage needs to be displayed
/// @param imageUrlArray get webImage by imageUrlArray
/// @param placeholder display placeholder before getting webImage or display placeholder when occurring error
+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray placeholder:(UIImage *)placeholder;

/// get imageView.image by imageUrlArray
/// @param imageView the imageView of webimage needs to be displayed
/// @param imageUrlArray get webImage by imageUrlArray
/// @param placeholder display placeholder before getting webImage or display placeholder when occurring error
/// @param completion  will be executed after completion
+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray placeholder:(UIImage *)placeholder completion:(ACCWebImageCompletionBlock)completion;

/// get imageView.image by imageUrlArray
/// @param imageView the imageView of webimage needs to be displayed
/// @param imageUrlArray get webImage by imageUrlArray
/// @param placeholder display placeholder before getting webImage or display placeholder when occurring error
/// @param progress get image download progress
/// @param postProcessBlock transform image
/// @param completion  will be executed after completion
+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray placeholder:(UIImage *)placeholder progress:(ACCWebImageProgressBlock)progress postProcess:(UIImage *(^)(UIImage * image))postProcessBlock completion:(ACCWebImageCompletionBlock)completion;

/// get imageView.image by imageUrlArray
/// @param imageView the imageView of webimage needs to be displayed
/// @param imageUrlArray get webImage by imageUrlArray
/// @param placeholder display placeholder before getting webImage or display placeholder when occurring error
/// @param options to configure image
/// @param completion  will be executed after completion
+ (void)imageView:(id)imageView setImageWithURLArray:(NSArray *)imageUrlArray placeholder:(UIImage *)placeholder options:(ACCWebImageOptions)options completion:(ACCWebImageCompletionBlock)completion;

/// get imageView.image by imageUrlArray
/// @param imageView the imageView of webimage needs to be displayed
/// @param imageUrlArray get webImage by imageUrlArray
/// @param options to configure image
+ (void)imageView:(id)imageView setImageWithURLArray:(NSArray *)imageUrlArray options:(ACCWebImageOptions)options;

/// get imageView.image by imageUrlArray
/// @param imageView the imageView of webimage needs to be displayed
/// @param imageUrl get webImage by imageUrl
/// @param options to configure image
+ (void)imageView:(UIImageView *)imageView setImageWithURL:(nullable NSURL *)imageUrl options:(ACCWebImageOptions)options;

// cancel imageView request
+ (void)cancelImageViewRequest:(UIImageView *)imageView;

// request image with urlArray
+ (void)requestImageWithURLArray:(NSArray *)imageUrlArray completion:(ACCWebImageCompletionBlock)completion;

+ (UIImageView *)animatedImageView;

/// get button.imageView.image by imageUrlArray
/// @param button  button.imageView of webimage needs to be displayed
/// @param state button.state
/// @param placeholder display placeholder before getting webImage or display placeholder when occurring error
/// @param completion  will be executed after completion
+ (void)button:(UIButton *)button
setImageWithURLArray:(NSArray *)imageUrlArray
      forState:(UIControlState)state
   placeholder:(UIImage *)placeholder
    completion:(ACCWebImageCompletionBlock)completion;

@end


FOUNDATION_STATIC_INLINE Class<ACCWebImageProtocol> ACCWebImage() {
    return [[ACCBaseServiceProvider() resolveObject:@protocol(ACCWebImageProtocol)] class];
}
