//
//  AWEWebImageOptions.h
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#ifndef AWEWebImageOptions_h
#define AWEWebImageOptions_h

#import <UIKit/UIKit.h>
#import <BDWebImage/BDWebImage.h>

#import "UIImageView+AWEWebImage.h"

typedef void (^_AWEBDImageRequestCompletionBlock)(UIImage *image,
                                                  NSURL *url,
                                                  NSUInteger index,
                                                  BDWebImageResultFrom from,
                                                  NSError *error);

inline static BDImageRequestOptions AWE_BDWebImageOptions(AWEWebImageOptions options)
{
    BDImageRequestOptions convertedOptions = 0;
    
    if (options & AWEWebImageOptionsProgressive) {
        convertedOptions |= BDImageProgressiveDownload;
    }
    if (options & AWEWebImageOptionsSetImageWithFadeAnimation) {
        convertedOptions |= BDImageRequestSetAnimationFade;
    }
    if (options & AWEWebImageOptionsAllowBackgroundTask) {
        convertedOptions |= BDImageRequestContinueInBackground;
    }
    if (options & AWEWebImageOptionsAvoidSetImage) {
        convertedOptions |= BDImageRequestSetDelaySetImage;
    }
    if (options & AWEWebImageOptionsDefaultPriority) {
        convertedOptions |= BDImageRequestDefaultPriority;
    }
    if (options & AWEWebImageOptionsLowPriority) {
        convertedOptions |= BDImageRequestLowPriority;
    }
    if (options & AWEWebImageOptionsHighPriority) {
        convertedOptions |= BDImageRequestHighPriority;
    }
    if (options & AWEWebImageOptionsNotCacheToMemory) {
        convertedOptions |= BDImageRequestNotCacheToMemery;
    }
    if (options & AWEWebImageOptionsNotCacheToDisk) {
        convertedOptions |= BDImageRequestNotCacheToDisk;
    }
    if (options & AWEWebImageOptionsIgnoreMemoryCache) {
        convertedOptions |= BDImageRequestIgnoreMemoryCache;
    }
    if (options & AWEWebImageOptionsIgnoreDiskCache) {
        convertedOptions |= BDImageRequestIgnoreDiskCache;
    }
    if (options & AWEWebImageOptionsNeedCachePath) {
        convertedOptions |= BDImageRequestNeedCachePath;
    }
    if (options & AWEWebImageOptionsIgnoreImage) {
        convertedOptions |= BDImageRequestIgnoreImage;
    }
    if (options & AWEWebImageOptionsIgnoreQueue) {
        convertedOptions |= BDImageRequestIgnoreQueue;
    }
    if (options & AWEWebImageOptionsSetAnimationDefault) {
        convertedOptions |= BDImageRequestSetAnimationDefault;
    }
    if (options & AWEWebImageOptionsDefaultOptions) {
        convertedOptions |= BDImageRequestDefaultOptions;
    }
    if (options & AWEWebImageOptionsIgnoreCache) {
        convertedOptions |= BDImageRequestIgnoreCache;
    }
    return convertedOptions;
}

#endif /* AWEWebImageOptions_h */
