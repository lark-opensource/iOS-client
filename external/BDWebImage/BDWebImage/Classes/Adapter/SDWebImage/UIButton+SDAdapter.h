//
//  UIButton+SDAdapter.h
//  BDWebImage
//
//  Created by lizhuoli on 2017/12/11.
//

#import <SDWebImage/UIButton+WebCache.h>

@interface UIButton (SDAdapter)

- (nullable NSURL *)sda_imageURLForState:(UIControlState)state;

- (void)sda_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state;

- (void)sda_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)placeholder;

- (void)sda_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)placeholder
                    options:(SDWebImageOptions)options;

- (void)sda_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
                  completed:(nullable SDExternalCompletionBlock)completedBlock;

- (void)sda_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)placeholder
                  completed:(nullable SDExternalCompletionBlock)completedBlock;

- (void)sda_setImageWithURL:(nullable NSURL *)url
                   forState:(UIControlState)state
           placeholderImage:(nullable UIImage *)placeholder
                    options:(SDWebImageOptions)options
                  completed:(nullable SDExternalCompletionBlock)completedBlock;

- (void)sda_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state;

- (void)sda_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)placeholder;

- (void)sda_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)placeholder
                              options:(SDWebImageOptions)options;

- (void)sda_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                            completed:(nullable SDExternalCompletionBlock)completedBlock;

- (void)sda_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)placeholder
                            completed:(nullable SDExternalCompletionBlock)completedBlock;

- (void)sda_setBackgroundImageWithURL:(nullable NSURL *)url
                             forState:(UIControlState)state
                     placeholderImage:(nullable UIImage *)placeholder
                              options:(SDWebImageOptions)options
                            completed:(nullable SDExternalCompletionBlock)completedBlock;

- (void)sda_cancelImageLoadForState:(UIControlState)state;

- (void)sda_cancelBackgroundImageLoadForState:(UIControlState)state;

@end
