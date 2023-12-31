//
//  UIImageView+SDAdapter.h
//  BDWebImage
//
//  Created by lizhuoli on 2017/12/11.
//

#import <SDWebImage/UIImageView+WebCache.h>

@interface UIImageView (SDAdapter)

- (nullable NSURL *)sda_imageURL;

- (void)sda_setImageWithURL:(nullable NSURL *)url;

- (void)sda_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder;

- (void)sda_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
                    options:(SDWebImageOptions)options;

- (void)sda_setImageWithURL:(nullable NSURL *)url
                  completed:(nullable SDExternalCompletionBlock)completedBlock;

- (void)sda_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
                  completed:(nullable SDExternalCompletionBlock)completedBlock;

- (void)sda_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
                    options:(SDWebImageOptions)options
                  completed:(nullable SDExternalCompletionBlock)completedBlock;

- (void)sda_setImageWithURL:(nullable NSURL *)url
           placeholderImage:(nullable UIImage *)placeholder
                    options:(SDWebImageOptions)options
                   progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                  completed:(nullable SDExternalCompletionBlock)completedBlock;

- (void)sda_cancelCurrentImageLoad;

@end
