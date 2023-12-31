//
//  UIButton+AWEAdditions.m
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import "UIButton+ACCAdditions.h"
#import <objc/runtime.h>
#import "ACCWebImageOptions.h"
#import <ByteDanceKit/BTDMacros.h>
#import <AWEBaseLib/AWEMacros.h>
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <RSSwizzle/RSSwizzle.h>
#import <Masonry/View+MASAdditions.h>

@implementation UIButton (ACCWebImage)

- (void)acc_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                          forState:(UIControlState)state
                       placeholder:(nullable UIImage *)placeholder
                           options:(ACCWebImageOptions)options
                        completion:(nullable ACCWebImageCompletionBlock)completion
{
    [self _bd_setImageWithURLArray:imageUrlArray forState:state placeholder:placeholder options:options completion:completion];
}

- (void)acc_setBackgroundImageWithURLArray:(nullable NSArray *)imageUrlArray
                                    forState:(UIControlState)state
                                 placeholder:(nullable UIImage *)placeholder
{
    
}


#pragma mark - BDWebImage Private Methods

- (void)_bd_setImageWithURLArray:(NSArray *)imageUrlArray
                        forState:(UIControlState)state
                     placeholder:(UIImage *)placeholder
                         options:(ACCWebImageOptions)options
                      completion:(ACCWebImageCompletionBlock)completion
{
    [self _bd_fetchImageWithMonitorUpload:imageUrlArray forState:state placeholder:placeholder options:options completion:^(UIImage *image, NSURL *url, NSUInteger index, BDWebImageResultFrom from, NSError *error) {
        AWEBLOCK_INVOKE(completion, image, url, error);
    }];
}

- (void)_bd_fetchImageWithMonitorUpload:(NSArray *)imageUrlArray
                               forState:(UIControlState)state
                            placeholder:(UIImage *)placeholder
                                options:(ACCWebImageOptions)options
                             completion:(_ACCBDImageRequestCompletionBlock)completion
{
    [self _bd_fetchImageWithUrlArray:imageUrlArray
                               index:0
                            forState:state
                         placeholder:placeholder
                             options:options
                          completion:completion];
}

- (void)_bd_fetchImageWithUrlArray:(NSArray *)imageUrlArray
                             index:(NSInteger)index
                          forState:(UIControlState)state
                       placeholder:(UIImage *)placeholder
                           options:(ACCWebImageOptions)options
                        completion:(_ACCBDImageRequestCompletionBlock)completion
{
    if(BTD_isEmptyArray(imageUrlArray)){
        [self setImage:placeholder forState:state];
        return;
    }

    NSURL *imageURL = imageUrlArray[index];

    if ([imageURL isKindOfClass:[NSString class]]){
        imageURL = [NSURL URLWithString:(id)imageURL];
    }

    @weakify(self);
    [self bd_setImageWithURL:imageURL
                    forState:state
            placeholderImage:placeholder
                     options:ACC_BDWebImageOptions(options)
                   cacheName:[UIImageView customCacheName]
                    progress:nil
                   completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                       if (image && !error) {
                           AWEBLOCK_INVOKE(completion, image, imageURL, index, from, error);
                           return;
                       }

                       // 图片最后拉取失败打点
                       NSUInteger next = index + 1;
                       if (next >= imageUrlArray.count) {
                           AWEBLOCK_INVOKE(completion, image, imageURL, index, from, error);
                           return;
                       }

                       @strongify(self);
                       [self _bd_fetchImageWithUrlArray:imageUrlArray
                                                  index:next
                                               forState:state
                                            placeholder:placeholder
                                                options:options
                                             completion:completion];
                   }];
}

- (void)_bd_setBackgroundImageWithURLArray:(NSArray *)imageUrlArray
                                  forState:(UIControlState)state
                               placeholder:(UIImage *)placeholder
{
    [self _bd_fetchBackgroundImageWithMontiorUpload:imageUrlArray
                                           forState:state
                                        placeholder:placeholder
                                         completion:nil];
}

- (void)_bd_fetchBackgroundImageWithMontiorUpload:(NSArray *)imageUrlArray
                                         forState:(UIControlState)state
                                      placeholder:(UIImage *)placeholder
                                       completion:(_ACCBDImageRequestCompletionBlock)completion
{
    [self _bd_fetchBackgroundImageWithURLArray:imageUrlArray
                                      forState:state
                                   placeholder:placeholder
                                       options:ACCWebImageOptionsDefaultOptions
                                         index:0
                                    completion:completion];
}
- (void)_bd_fetchBackgroundImageWithURLArray:(NSArray *)imageUrlArray
                                    forState:(UIControlState)state
                                 placeholder:(UIImage *)placeholder
                                     options:(ACCWebImageOptions)options
                                       index:(NSUInteger)index
                                  completion:(_ACCBDImageRequestCompletionBlock)completion
{
    if(BTD_isEmptyArray(imageUrlArray)){
        [self setBackgroundImage:placeholder forState:state];
        return;
    }

    NSURL *imageURL = imageUrlArray[index];

    if ([imageURL isKindOfClass:[NSString class]]){
        imageURL = [NSURL URLWithString:(id)imageURL];
    }

    @weakify(self);
    [self bd_setBackgroundImageWithURL:imageURL
                              forState:state
                      placeholderImage:placeholder
                               options:ACC_BDWebImageOptions(options)
                             cacheName:[UIImageView customCacheName]
                              progress:nil
                             completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                 if (image && !error) {
                                     AWEBLOCK_INVOKE(completion, image, request.currentRequestURL, index, from, error);
                                     return;
                                 }

                                 NSUInteger next = index + 1;
                                 if (next >= imageUrlArray.count) {
                                     AWEBLOCK_INVOKE(completion, image, request.currentRequestURL, index, from, error);
                                     return;
                                 }

                                 @strongify(self);
                                 [self _bd_fetchBackgroundImageWithURLArray:imageUrlArray
                                                                   forState:state
                                                                placeholder:placeholder
                                                                    options:options
                                                                      index:next
                                                                 completion:completion];
                             }];
}

@end
