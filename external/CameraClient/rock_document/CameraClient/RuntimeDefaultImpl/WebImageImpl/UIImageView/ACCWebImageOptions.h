//
//  ACCWebImageOptions.h
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#ifndef ACCWebImageOptions_h
#define ACCWebImageOptions_h

#import <UIKit/UIKit.h>
#import <BDWebImage/BDWebImage.h>

#import "UIImageView+ACCWebImage.h"

typedef void (^_ACCBDImageRequestCompletionBlock)(UIImage * _Nullable image,
                                                  NSURL * _Nullable url,
                                                  NSUInteger index,
                                                  BDWebImageResultFrom from,
                                                  NSError * _Nullable error);

inline static BDImageRequestOptions ACC_BDWebImageOptions(ACCWebImageOptions options)
{
    BDImageRequestOptions convertedOptions = 0;
    
    if (options & ACCWebImageOptionsProgressive) {
        convertedOptions |= BDImageProgressiveDownload;
    }
    if (options & ACCWebImageOptionsSetImageWithFadeAnimation) {
        convertedOptions |= BDImageRequestSetAnimationFade;
    }
    if (options & ACCWebImageOptionsAllowBackgroundTask) {
        convertedOptions |= BDImageRequestContinueInBackground;
    }
    if (options & ACCWebImageOptionsAvoidSetImage) {
        convertedOptions |= BDImageRequestSetDelaySetImage;
    }
    if (options & ACCWebImageOptionsDefaultPriority) {
        convertedOptions |= BDImageRequestDefaultPriority;
    }
    if (options & ACCWebImageOptionsLowPriority) {
        convertedOptions |= BDImageRequestLowPriority;
    }
    if (options & ACCWebImageOptionsHighPriority) {
        convertedOptions |= BDImageRequestHighPriority;
    }
    if (options & ACCWebImageOptionsNotCacheToMemory) {
        convertedOptions |= BDImageRequestNotCacheToMemery;
    }
    if (options & ACCWebImageOptionsNotCacheToDisk) {
        convertedOptions |= BDImageRequestNotCacheToDisk;
    }
    if (options & ACCWebImageOptionsIgnoreMemoryCache) {
        convertedOptions |= BDImageRequestIgnoreMemoryCache;
    }
    if (options & ACCWebImageOptionsIgnoreDiskCache) {
        convertedOptions |= BDImageRequestIgnoreDiskCache;
    }
    if (options & ACCWebImageOptionsNeedCachePath) {
        convertedOptions |= BDImageRequestNeedCachePath;
    }
    if (options & ACCWebImageOptionsIgnoreImage) {
        convertedOptions |= BDImageRequestIgnoreImage;
    }
    if (options & ACCWebImageOptionsIgnoreQueue) {
        convertedOptions |= BDImageRequestIgnoreQueue;
    }
    if (options & ACCWebImageOptionsSetAnimationDefault) {
        convertedOptions |= BDImageRequestSetAnimationDefault;
    }
    if (options & ACCWebImageOptionsDefaultOptions) {
        convertedOptions |= BDImageRequestDefaultOptions;
    }
    if (options & ACCWebImageOptionsIgnoreCache) {
        convertedOptions |= BDImageRequestIgnoreCache;
    }
    return convertedOptions;
}

#endif /* ACCWebImageOptions_h */
