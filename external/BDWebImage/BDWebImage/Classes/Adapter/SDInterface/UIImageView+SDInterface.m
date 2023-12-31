//
//  UIImageView+SDInterface.m
//  BDWebImage
//
//  Created by 陈奕 on 2020/1/6.
//

#import "UIImageView+SDInterface.h"

@implementation UIImageView (SDInterface)

- (NSURL *)sdi_imageURL {
    return self.bd_imageURL;
}

- (void)sdi_setImageWithURL:(NSURL *)url {
    [self sdi_setImageWithURL:url placeholderImage:nil];
}

- (void)sdi_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
{
    [self sdi_setImageWithURL:url placeholderImage:placeholder options:0];
}

- (void)sdi_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
                    options:(BDImageRequestOptions)options
{
    [self sdi_setImageWithURL:url placeholderImage:placeholder options:options completed:NULL];
}

- (void)sdi_setImageWithURL:(nullable NSURL *)url
                  completed:(nullable SDInterfaceExternalCompletionBlock)completedBlock
{
    [self sdi_setImageWithURL:url placeholderImage:nil completed:completedBlock];
}

- (void)sdi_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
                  completed:(nullable SDInterfaceExternalCompletionBlock)completedBlock
{
    [self sdi_setImageWithURL:url placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)sdi_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
                    options:(BDImageRequestOptions)options
                  completed:(nullable SDInterfaceExternalCompletionBlock)completedBlock
{
    [self sdi_setImageWithURL:url placeholderImage:placeholder options:options progress:NULL completed:completedBlock];
}

- (void)sdi_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
                    options:(BDImageRequestOptions)options
                   progress:(nullable SDInterfaceDownloaderProgressBlock)progressBlock
                  completed:(nullable SDInterfaceExternalCompletionBlock)completedBlock
{
    [self bd_setImageWithURL:url
                 placeholder:placeholder
                     options:options
                   cacheName:nil
                    progress:progressBlock ? ^(BDWebImageRequest *request, NSInteger receivedSize, NSInteger expectedSize) {
                        progressBlock(receivedSize, expectedSize, request.currentRequestURL);
                    } : nil
                  completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                      if (completedBlock) {
                          BDImageCacheType cacheType = BDImageCacheTypeNone;
                          if (from == BDWebImageResultFromDiskCache) {
                              cacheType = BDImageCacheTypeDisk;
                          } else if (from == BDWebImageResultFromMemoryCache) {
                              cacheType = BDImageCacheTypeMemory;
                          }
                          completedBlock(image, error, cacheType, request.currentRequestURL);
                      }
                  }];
}

- (void)sdi_cancelCurrentImageLoad
{
    [self bd_cancelImageLoad];
}

@end
