//
//  UIImageView+BDWebImage.h
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/29.
//

#import <UIKit/UIKit.h>
#import "BDWebImageManager.h"
#import "BDBaseTransformer.h"

NS_ASSUME_NONNULL_BEGIN
@interface UIImageView (BDWebImage)

@property (nonatomic, strong, nullable) BDWebImageRequest *imageRequest;

/**
 通过 UIImageView-Category 请求，按照 View 的大小进行下采样 default : NO
 如果用户通过BDWebImageRequestConfig自定义了size，同时也将bd_isOpenDownsample设置成了YES，
 那么优先使用用户自定义的size。
 */
@property (nonatomic, assign) BOOL bd_isOpenDownsample;

- (nullable BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)imageURL;

- (nullable BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)imageURL placeholder:(nullable UIImage *)placeholder;

- (nullable BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)imageURL options:(BDImageRequestOptions)options;

- (nullable BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)imageURL
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                               completion:(nullable BDImageRequestCompletedBlock)completion;

- (nullable BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)imageURL
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                                 progress:(nullable BDImageRequestProgressBlock)progress
                               completion:(nullable BDImageRequestCompletedBlock)completion;

- (nullable BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)imageURL
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                                cacheName:(nullable NSString *)cacheName
                                 progress:(nullable BDImageRequestProgressBlock)progress
                               completion:(nullable BDImageRequestCompletedBlock)completion;

- (nullable BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)imageURL
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                              transformer:(nullable BDBaseTransformer *)transformer
                                 progress:(nullable BDImageRequestProgressBlock)progress
                               completion:(nullable BDImageRequestCompletedBlock)completion;

- (nullable BDWebImageRequest *)bd_setImageWithURLs:(nonnull NSArray *)imageURLs
                               placeholder:(nullable UIImage *)placeholder
                                   options:(BDImageRequestOptions)options
                               transformer:(nullable BDBaseTransformer *)transformer
                                  progress:(nullable BDImageRequestProgressBlock)progress
                                completion:(nullable BDImageRequestCompletedBlock)completion;

- (nullable BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)imageURL
                          alternativeURLs:(nullable NSArray *)alternativeURLs
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                                cacheName:(nullable NSString *)cacheName
                              transformer:(nullable BDBaseTransformer *)transformer
                                 progress:(nullable BDImageRequestProgressBlock)progress
                               completion:(nullable BDImageRequestCompletedBlock)completion;

- (nullable BDWebImageRequest *)bd_setImageWithURL:(NSURL *)imageURL
                          alternativeURLs:(nullable NSArray *)alternativeURLs
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                          timeoutInterval:(CFTimeInterval)timeoutInterval
                                cacheName:(nullable NSString *)cacheName
                              transformer:(nullable BDBaseTransformer *)transformer
                                 progress:(nullable BDImageRequestProgressBlock)progress
                               completion:(nullable BDImageRequestCompletedBlock)completion;

- (nullable BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)imageURL
                          alternativeURLs:(nullable NSArray *)alternativeURLs
                              placeholder:(nullable UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                          timeoutInterval:(CFTimeInterval)timeoutInterval
                                cacheName:(nullable NSString *)cacheName
                              transformer:(nullable BDBaseTransformer *)transformer
                             decryptBlock:(nullable BDImageRequestDecryptBlock)decrypt
                                 progress:(nullable BDImageRequestProgressBlock)progress
                               completion:(nullable BDImageRequestCompletedBlock)completion;

/**
 通过URL、自定义options、自定义config来设置imageView
 @param imageURL    请求图片的URL，不能为空
 @param alternativeURLs     备选URL
 @param placeholder     设置初始图片，直到图片请求结束
 @param options     图片请求相关设置，详细参数见BDImageRequestOptions
 @param config      用户自定义请求配置
 @param blocks      请求的回调，不能为空
 
 @code
 BDWebImageRequestConfig *config = [BDWebImageRequestConfig new];
 config.size = CGSizeMake(width, height);
 BDWebImageRequestBlocks *blocks = [BDWebImageRequestBlocks new];
 [self.demoImageView bd_setImageWithURL:[NSURL URLWithString:url]
                        alternativeURLs:nil
                            placeholder:nil
                                options:0
                                 config:config
                                 blocks:blocks];
 @endcode
 */
- (nullable BDWebImageRequest *)bd_setImageWithURL:(nonnull NSURL *)imageURL
                                   alternativeURLs:(nullable NSArray *)alternativeURLs
                                       placeholder:(nullable UIImage *)placeholder
                                           options:(BDImageRequestOptions)options
                                            config:(nullable BDWebImageRequestConfig *)config
                                            blocks:(nonnull BDWebImageRequestBlocks *)blocks;

- (void)bd_cancelImageLoad;

- (nullable NSURL *)bd_imageURL;

NS_ASSUME_NONNULL_END

@end
