//
//  UIImageView+AWEWebImage.h
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCWebImageProtocol.h>

typedef void (^ACCWebImageCompletionBlock)(UIImage * _Nullable image,
                                           NSURL * _Nullable url,
                                           NSError * _Nullable error);

typedef void(^ACCWebImageProgressBlock)(double progressValue);

typedef UIImage * (^ACCWebImageTransformBlock)(UIImage *_Nullable image , NSURL *_Nullable url);

@interface UIImageView (ACCWebImageRequest)

#pragma mark - Normal

- (void)acc_setImageWithURLArray:(nullable NSArray *)imageUrlArray;

- (void)acc_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder;

- (void)acc_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                           options:(ACCWebImageOptions)options;

- (void)acc_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                        completion:(nullable ACCWebImageCompletionBlock)completion;

- (void)acc_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                           options:(ACCWebImageOptions)options
                        completion:(nullable ACCWebImageCompletionBlock)completion;

- (void)acc_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                         cacheName:(nullable NSString *)cacheName
                           options:(ACCWebImageOptions)options
                        completion:(nullable ACCWebImageCompletionBlock)completion;

- (void)acc_setImageWithURLArray:(nullable NSArray *)imageUrlArray
               downgradingURLArray:(nullable NSArray *)downgradingUrlArray
                       placeholder:(nullable UIImage *)placeholder
                           options:(ACCWebImageOptions)options
                        completion:(nullable ACCWebImageCompletionBlock)completion;

- (void)acc_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                           options:(ACCWebImageOptions)options
                          progress:(nullable ACCWebImageProgressBlock)progress
                       postProcess:(nullable UIImage *(^)(UIImage * image))postProcessBlock
                        completion:(nullable ACCWebImageCompletionBlock)completion;

- (void)acc_setImageWithURLArray:(nullable NSArray *)imageUrlArray
                       placeholder:(nullable UIImage *)placeholder
                         cacheName:(nullable NSString *)cacheName
                           options:(ACCWebImageOptions)options
                          progress:(nullable ACCWebImageProgressBlock)progress
                       postProcess:(nullable UIImage *(^)(UIImage * _Nullable image))postProcessBlock
                        completion:(nullable ACCWebImageCompletionBlock)completion;

- (void)acc_setImageWithURL:(nullable NSURL *)imageUrl;

- (void)acc_setImageWithURL:(nullable NSURL *)imageUrl
                  placeholder:(nullable UIImage *)placeholder;

- (void)acc_setImageWithURL:(nullable NSURL *)imageUrl
                      options:(ACCWebImageOptions)options;

- (void)acc_setImageWithURL:(nullable NSURL *)imageUrl
                  placeholder:(nullable UIImage *)placeholder
                   completion:(nullable ACCWebImageCompletionBlock)completion;

- (void)acc_setImageWithURL:(nullable NSURL *)imageUrl
                  placeholder:(nullable UIImage *)placeholder
                      options:(ACCWebImageOptions)options
                   completion:(nullable ACCWebImageCompletionBlock)completion;

- (void)acc_setImageWithURL:(nullable NSURL *)imageUrl
                  placeholder:(nullable UIImage *)placeholder
                      options:(ACCWebImageOptions)options
                     progress:(nullable ACCWebImageProgressBlock)progress
                  postProcess:(nullable UIImage *(^)(UIImage *_Nullable image))postProcessBlock
                   completion:(nullable ACCWebImageCompletionBlock)completion;

- (void)acc_setImageWithURL:(nullable NSURL *)imageUrl
                  placeholder:(nullable UIImage *)placeholder
                    cacheName:(nullable NSString *)cacheName
                      options:(ACCWebImageOptions)options
                     progress:(nullable ACCWebImageProgressBlock)progress
                  postProcess:(nullable UIImage *(^)(UIImage * image))postProcessBlock
                   completion:(nullable ACCWebImageCompletionBlock)completion;

- (void)reDrawImage:(nullable UIImage *)image inContainerSize:(CGSize)size;
//
- (void)acc_cancelImageRequest;

+ (void)acc_requestImageWithURLArray:(nullable NSArray *)imageUrlArray
                               options:(ACCWebImageOptions)options
                              progress:(nullable ACCWebImageProgressBlock)progress
                            completion:(nullable ACCWebImageCompletionBlock)completion;

+ (void)acc_requestImageWithURLArray:(nullable NSArray *)imageUrlArray
                               options:(ACCWebImageOptions)options
                            completion:(nullable ACCWebImageCompletionBlock)completion;
//
+ (void)acc_requestImageWithURLArray:(nullable NSArray *)imageUrlArray
                            completion:(nullable ACCWebImageCompletionBlock)completion;

+ (void)acc_requestImageWithURLArray:(nullable NSArray *)imageUrlArray
                             cacheName:(nullable NSString *)cacheName
                            completion:(nullable ACCWebImageCompletionBlock)completion;

+ (void)acc_requestImageWithURLArray:(nullable NSArray *)imageUrlArray;

+ (void)acc_requestImageWithURL:(nullable NSURL *)imageUrl;

+ (void)acc_requestImageWithURL:(nullable NSURL *)imageUrl
                       completion:(nullable ACCWebImageCompletionBlock)completion;

+ (void)acc_requestImageWithURL:(nullable NSURL *)imageUrl
                          options:(ACCWebImageOptions)options
                       completion:(nullable ACCWebImageCompletionBlock)completion;

+ (void)acc_requestImageWithURL:(nullable NSURL *)imageUrl
                          options:(ACCWebImageOptions)options
                         progress:(nullable ACCWebImageProgressBlock)progress
                       completion:(nullable ACCWebImageCompletionBlock)completion;

+ (void)acc_requestImageWithURL:(nullable NSURL *)imageUrl
                          options:(ACCWebImageOptions)options
                        cacheName:(nullable NSString *)cacheName
                         progress:(nullable ACCWebImageProgressBlock)progress
                       completion:(nullable ACCWebImageCompletionBlock)completion;

+ (NSString *)customCacheName;
@end

@interface UIImageView (ACCAnimatedImageView)

+ (nullable UIImageView *)acc_animatedImageView;

- (void)updateImageViewAnimationType:(BOOL)animationTypeReciprocating;

@end

@interface UIImage (ACCAnimatedImage)

+ (nullable UIImage *)acc_animatedImage;

@end
