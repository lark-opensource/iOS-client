//
//  ACCWebImageDefaultImpl.m
//  CameraClient-Pods-AwemeCore
//
//  Created by luwei on 2021/11/18.
//

#import "ACCWebImageDefaultImpl.h"
#import "UIImageView+ACCWebImage.h"
#import "UIButton+ACCAdditions.h"

@implementation ACCWebImageDefaultImpl

+ (UIImageView *)animatedImageView {
    return [UIImageView acc_animatedImageView];
}

+ (void)requestImageWithURLArray:(NSArray *)imageUrlArray completion:(ACCWebImageCompletionBlock)completion {
    [UIImageView acc_requestImageWithURLArray:imageUrlArray completion:completion];
}

+ (void)cancelImageViewRequest:(UIImageView *)imageView {
    [imageView acc_cancelImageRequest];
}

+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray {
    [imageView acc_setImageWithURLArray:imageUrlArray];
}

+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray placeholder:(UIImage *)placeholder {
    [imageView acc_setImageWithURLArray:imageUrlArray placeholder:placeholder];
}

+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray placeholder:(UIImage *)placeholder completion:(ACCWebImageCompletionBlock)completion {
    [imageView acc_setImageWithURLArray:imageUrlArray placeholder:placeholder completion:completion];
}

+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray placeholder:(UIImage *)placeholder options:(ACCWebImageOptions)options completion:(ACCWebImageCompletionBlock)completion
{
    [imageView acc_setImageWithURLArray:imageUrlArray placeholder:placeholder options:(ACCWebImageOptions)options completion:completion];
}

+ (void)imageView:(id)imageView setImageWithURLArray:(NSArray *)imageUrlArray options:(ACCWebImageOptions)options
{
    [imageView acc_setImageWithURLArray:imageUrlArray options:(ACCWebImageOptions)options];
}

+ (void)imageView:(UIImageView *)imageView setImageWithURL:(NSURL *)imageUrl options:(ACCWebImageOptions)options
{
    [imageView acc_setImageWithURL:imageUrl options:(ACCWebImageOptions)options];
}

+ (void)imageView:(UIImageView *)imageView setImageWithURLArray:(NSArray *)imageUrlArray placeholder:(UIImage *)placeholder progress:(ACCWebImageProgressBlock)progress postProcess:(UIImage *(^)(UIImage *))postProcessBlock completion:(ACCWebImageCompletionBlock)completion {
    [imageView acc_setImageWithURLArray:imageUrlArray placeholder:placeholder options:ACCWebImageOptionsSetImageWithFadeAnimation | ACCWebImageOptionsDefaultOptions progress:progress postProcess:postProcessBlock completion:completion];
}

+ (void)button:(id)button setImageWithURLArray:(id)imageUrlArray forState:(UIControlState)state placeholder:(UIImage *)placeholder completion:(ACCWebImageCompletionBlock)completion
{
    [button acc_setImageWithURLArray:imageUrlArray forState:state placeholder:placeholder options:0 completion:completion];
}


@end
