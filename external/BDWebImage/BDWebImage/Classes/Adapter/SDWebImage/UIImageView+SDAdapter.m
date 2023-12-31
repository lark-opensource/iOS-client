//
//  UIImageView+SDAdapter.m
//  BDWebImage
//
//  Created by lizhuoli on 2017/12/11.
//

#import "UIImageView+SDAdapter.h"
#import "UIImageView+BDWebImage.h"
#import "SDWebImageAdapter.h"
#import "UIView+WebCache.h"


@implementation UIImageView (SDAdapter)

- (NSURL *)sda_imageURL {
    if ([SDWebImageAdapter useBDWebImage]) {
        return self.bd_imageURL;
    } else {
        return self.sd_imageURL;
    }
}

- (void)sda_setImageWithURL:(nullable NSURL *)url
{
    [self sda_setImageWithURL:url placeholderImage:nil];
}

- (void)sda_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
{
    [self sda_setImageWithURL:url placeholderImage:placeholder options:0];
}

- (void)sda_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
                    options:(SDWebImageOptions)options
{
    [self sda_setImageWithURL:url placeholderImage:placeholder options:options completed:NULL];
}

- (void)sda_setImageWithURL:(nullable NSURL *)url
                  completed:(nullable SDExternalCompletionBlock)completedBlock
{
    [self sda_setImageWithURL:url placeholderImage:nil completed:completedBlock];
}

- (void)sda_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
                  completed:(nullable SDExternalCompletionBlock)completedBlock
{
    [self sda_setImageWithURL:url placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)sda_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
                    options:(SDWebImageOptions)options
                  completed:(nullable SDExternalCompletionBlock)completedBlock
{
    [self sda_setImageWithURL:url placeholderImage:placeholder options:options progress:NULL completed:completedBlock];
}

- (void)sda_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
                    options:(SDWebImageOptions)options
                   progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                  completed:(nullable SDExternalCompletionBlock)completedBlock
{
    if ([SDWebImageAdapter useBDWebImage]) {
        [self bd_setImageWithURL:url
                     placeholder:placeholder
                         options:BDOptionsWithSDManagerOptions(options)
                       cacheName:nil
                        progress:progressBlock? ^(BDWebImageRequest *request, NSInteger receivedSize, NSInteger expectedSize) {
                            progressBlock(receivedSize, expectedSize, request.currentRequestURL);
                        }:nil
                      completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                          if (completedBlock) {
                              SDImageCacheType cacheType = SDImageCacheTypeNone;
                              if (from == BDWebImageResultFromDiskCache) {
                                  cacheType = SDImageCacheTypeDisk;
                              } else if (from == BDWebImageResultFromMemoryCache) {
                                  cacheType = SDImageCacheTypeMemory;
                              }
                              completedBlock(image,error,cacheType,request.currentRequestURL);
                          }
                      }];
    } else {
        [self sd_setImageWithURL:url
                placeholderImage:placeholder
                         options:options
                        progress:progressBlock
                       completed:completedBlock];
    }
}

- (void)sda_cancelCurrentImageLoad
{
    if ([SDWebImageAdapter useBDWebImage]) {
        [self bd_cancelImageLoad];
    } else {
        [self sd_cancelCurrentImageLoad];
    }
}

@end
