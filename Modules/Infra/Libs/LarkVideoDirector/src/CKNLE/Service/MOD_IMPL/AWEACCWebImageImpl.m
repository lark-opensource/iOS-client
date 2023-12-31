//
//  AWEACCWebImageImpl.m
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import "AWEACCWebImageImpl.h"
#import "UIImageView+AWEWebImage.h"
#import "UIButton+AWEAdditions.h"

@implementation AWEACCWebImageImpl

+ (UIImageView *)animatedImageView {
    return [UIImageView aweme_animatedImageView];
}

+ (void)requestImageWithURLArray:(NSArray *)imageUrlArray completion:(ACCWebImageCompletionBlock)completion {
    [UIImageView aweme_requestImageWithURLArray:imageUrlArray completion:completion];
}

+ (void)cancelImageViewRequest:(UIImageView *)imageView {
    [imageView aweme_cancelImageRequest];
}

+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray {
    [imageView aweme_setImageWithURLArray:imageUrlArray];
}

+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray placeholder:(UIImage *)placeholder {
    [imageView aweme_setImageWithURLArray:imageUrlArray placeholder:placeholder];
}

+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray placeholder:(UIImage *)placeholder completion:(ACCWebImageCompletionBlock)completion {
    [imageView aweme_setImageWithURLArray:imageUrlArray placeholder:placeholder completion:completion];
}

+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray placeholder:(UIImage *)placeholder options:(ACCWebImageOptions)options completion:(ACCWebImageCompletionBlock)completion
{
    [imageView aweme_setImageWithURLArray:imageUrlArray placeholder:placeholder options:(AWEWebImageOptions)options completion:completion];
}

+ (void)imageView:(id)imageView setImageWithURLArray:(NSArray *)imageUrlArray options:(ACCWebImageOptions)options
{
    [imageView aweme_setImageWithURLArray:imageUrlArray options:(AWEWebImageOptions)options];
}

+ (void)imageView:(UIImageView *)imageView setImageWithURL:(NSURL *)imageUrl options:(ACCWebImageOptions)options
{
    [imageView aweme_setImageWithURL:imageUrl options:(AWEWebImageOptions)options];
}

+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray placeholder:(UIImage *)placeholder progress:(ACCWebImageProgressBlock)progress postProcess:(UIImage *(^)(UIImage *))postProcessBlock completion:(ACCWebImageCompletionBlock)completion {
    [imageView aweme_setImageWithURLArray:imageUrlArray placeholder:placeholder options:AWEWebImageOptionsSetImageWithFadeAnimation | AWEWebImageOptionsDefaultOptions progress:progress postProcess:postProcessBlock completion:completion];
}

+ (void)button:(id)button setImageWithURLArray:(id)imageUrlArray forState:(UIControlState)state placeholder:(UIImage *)placeholder completion:(ACCWebImageCompletionBlock)completion
{
    [button aweme_setImageWithURLArray:imageUrlArray forState:state placeholder:placeholder options:0 completion:completion];
}


@end
