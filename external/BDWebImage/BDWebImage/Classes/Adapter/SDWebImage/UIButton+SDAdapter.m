//
//  UIButton+SDAdapter.m
//  BDWebImage
//
//  Created by lizhuoli on 2017/12/11.
//

#import "UIButton+SDAdapter.h"
#import "UIButton+BDWebImage.h"
#import "SDWebImageAdapter.h"

@implementation UIButton (SDAdapter)

- (NSURL *)sda_imageURLForState:(UIControlState)state {
    if ([SDWebImageAdapter useBDWebImage]) {
        return [self bd_imageURLForState:state];
    } else {
        return [self sd_imageURLForState:state];
    }
}

- (void)sda_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
{
    [self sda_setImageWithURL:url forState:state placeholderImage:nil];
}

- (void)sda_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)placeholder
{
    [self sda_setImageWithURL:url forState:state placeholderImage:placeholder options:0];
}

- (void)sda_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)placeholder
                    options:(SDWebImageOptions)options
{
    [self sda_setImageWithURL:url forState:state placeholderImage:placeholder options:options completed:NULL];
}

- (void)sda_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
                  completed:(nullable SDExternalCompletionBlock)completedBlock
{
    [self sda_setImageWithURL:url forState:state placeholderImage:nil completed:completedBlock];
}

- (void)sda_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)placeholder
                  completed:(nullable SDExternalCompletionBlock)completedBlock
{
    [self sda_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)sda_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)placeholder
                    options:(SDWebImageOptions)options
                  completed:(nullable SDExternalCompletionBlock)completedBlock
{
    if ([SDWebImageAdapter useBDWebImage]) {
         [self bd_setImageWithURL:url
                         forState:state
                 placeholderImage:placeholder
                          options:BDOptionsWithSDManagerOptions(options)
                        cacheName:nil
                         progress:NULL
                        completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                            if (completedBlock) {
                                SDImageCacheType cacheType = SDImageCacheTypeNone;
                                if (from == BDWebImageResultFromDiskCache) {
                                    cacheType = SDImageCacheTypeDisk;
                                } else if (from == BDWebImageResultFromMemoryCache){
                                    cacheType = SDImageCacheTypeMemory;
                                }
                                completedBlock(image,error,cacheType,request.currentRequestURL);
                            }
                        }];
    } else {
        [self sd_setImageWithURL:url forState:state placeholderImage:placeholder options:options completed:completedBlock];
    }
}

- (void)sda_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
{
    [self sda_setBackgroundImageWithURL:url forState:state placeholderImage:nil];
}

- (void)sda_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)placeholder
{
    [self sda_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0];
}

- (void)sda_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)placeholder
                              options:(SDWebImageOptions)options
{
    [self sda_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options completed:NULL];
}

- (void)sda_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                            completed:(nullable SDExternalCompletionBlock)completedBlock
{
    [self sda_setBackgroundImageWithURL:url forState:state placeholderImage:nil completed:completedBlock];
}

- (void)sda_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)placeholder
                            completed:(nullable SDExternalCompletionBlock)completedBlock
{
    [self sda_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)sda_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)placeholder
                              options:(SDWebImageOptions)options
                            completed:(nullable SDExternalCompletionBlock)completedBlock
{
    if ([SDWebImageAdapter useBDWebImage]) {
         [self bd_setBackgroundImageWithURL:url
                                   forState:state
                           placeholderImage:placeholder
                                    options:BDOptionsWithSDManagerOptions(options)
                                  cacheName:nil
                                   progress:NULL
                                  completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
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
        [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options completed:completedBlock];
    }
}

- (void)sda_cancelImageLoadForState:(UIControlState)state
{
    if ([SDWebImageAdapter useBDWebImage]) {
        [self bd_cancelImageLoadForState:state];
    } else {
        [self sd_cancelImageLoadForState:state];
    }
}

- (void)sda_cancelBackgroundImageLoadForState:(UIControlState)state
{
    if ([SDWebImageAdapter useBDWebImage]) {
        [self bd_cancelBackgroundImageLoadForState:state];
    } else {
        [self sd_cancelBackgroundImageLoadForState:state];
    }
}

@end
