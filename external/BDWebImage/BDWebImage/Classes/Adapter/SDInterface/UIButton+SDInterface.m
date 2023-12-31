//
//  UIButton+SDInterface.m
//  BDWebImage
//
//  Created by 陈奕 on 2020/1/6.
//

#import "UIButton+SDInterface.h"

@implementation UIButton (SDInterface)

- (NSURL *)sdi_imageURLForState:(UIControlState)state {
    return [self bd_imageURLForState:state];
}

- (void)sdi_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
{
    [self sdi_setImageWithURL:url forState:state placeholderImage:nil];
}

- (void)sdi_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)placeholder
{
    [self sdi_setImageWithURL:url forState:state placeholderImage:placeholder options:0];
}

- (void)sdi_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)placeholder
                    options:(BDImageRequestOptions)options
{
    [self sdi_setImageWithURL:url forState:state placeholderImage:placeholder options:options completed:NULL];
}

- (void)sdi_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
                  completed:(nullable SDInterfaceExternalCompletionBlock)completedBlock
{
    [self sdi_setImageWithURL:url forState:state placeholderImage:nil completed:completedBlock];
}

- (void)sdi_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)placeholder
                  completed:(nullable SDInterfaceExternalCompletionBlock)completedBlock
{
    [self sdi_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)sdi_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)placeholder
                    options:(BDImageRequestOptions)options
                  completed:(nullable SDInterfaceExternalCompletionBlock)completedBlock
{
     [self bd_setImageWithURL:url
                     forState:state
             placeholderImage:placeholder
                      options:options
                    cacheName:nil
                     progress:NULL
                    completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                        if (completedBlock) {
                            BDImageCacheType cacheType = BDImageCacheTypeNone;
                            if (from == BDWebImageResultFromDiskCache) {
                                cacheType = BDImageCacheTypeDisk;
                            } else if (from == BDWebImageResultFromMemoryCache){
                                cacheType = BDImageCacheTypeMemory;
                            }
                            completedBlock(image,error,cacheType,request.currentRequestURL);
                        }
                    }];
}

- (void)sdi_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
{
    [self sdi_setBackgroundImageWithURL:url forState:state placeholderImage:nil];
}

- (void)sdi_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)placeholder
{
    [self sdi_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0];
}

- (void)sdi_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)placeholder
                              options:(BDImageRequestOptions)options
{
    [self sdi_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options completed:NULL];
}

- (void)sdi_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                            completed:(nullable SDInterfaceExternalCompletionBlock)completedBlock
{
    [self sdi_setBackgroundImageWithURL:url forState:state placeholderImage:nil completed:completedBlock];
}

- (void)sdi_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)placeholder
                            completed:(nullable SDInterfaceExternalCompletionBlock)completedBlock
{
    [self sdi_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)sdi_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)placeholder
                              options:(BDImageRequestOptions)options
                            completed:(nullable SDInterfaceExternalCompletionBlock)completedBlock
{
     [self bd_setBackgroundImageWithURL:url
                               forState:state
                       placeholderImage:placeholder
                                options:options
                              cacheName:nil
                               progress:NULL
                              completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                  if (completedBlock) {
                                      BDImageCacheType cacheType = BDImageCacheTypeNone;
                                      if (from == BDWebImageResultFromDiskCache) {
                                          cacheType = BDImageCacheTypeDisk;
                                          
                                      } else if (from == BDWebImageResultFromMemoryCache) {
                                          cacheType = BDImageCacheTypeMemory;
                                      }
                                      completedBlock(image,error,cacheType,request.currentRequestURL);
                                  }
                              }];
}

- (void)sdi_cancelImageLoadForState:(UIControlState)state
{
    [self bd_cancelImageLoadForState:state];
}

- (void)sdi_cancelBackgroundImageLoadForState:(UIControlState)state
{
    [self bd_cancelBackgroundImageLoadForState:state];
}

@end
