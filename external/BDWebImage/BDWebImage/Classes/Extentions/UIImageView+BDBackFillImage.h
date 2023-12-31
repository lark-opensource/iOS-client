//
//  UIImageView+BDBackFillImage.h
//  BDWebImage
//
//  Created by qiuyang on 2018/12/20.
//

#import <UIKit/UIKit.h>
#import "BDWebImageManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDImageResolutionType) {
    BDImageResolutionTypeThumb = 0,   ///< 小图
    BDImageResolutionTypePreview = 1, ///< 中图，预览图
    BDImageResolutionTypeOrigin = 2,  ///< 大图
};


@interface BDBackFill : NSObject

@property (nonatomic, assign) BDImageResolutionType imageType;

@property (nonatomic, strong) NSURL *thumbImageURL;
@property (nonatomic, strong) NSURL *previewImageURL;
@property (nonatomic, strong) NSURL *originalImageURL;

@end


@interface UIImageView (BDBackFillImage)

/**
 *  对setImage的封装。设置UIImageView的image。
 *  使用回填功能时，一定要使用此方法设置image，否则会导致复用问题
 */
- (void)bd_backFillSetImage:(UIImage *)image;

@property (nonatomic, strong, nullable) NSURL *bd_backfillRequestURL;

/**
 *  将BDWebImage cache到回填对象。
 */
- (void)bd_setImageViewToBackFill:(NSURL *)imageURL;

/**
 *  对BDWebImage的封装。
 *  此方法支持回填功能。
 *  当小or中图请求失败时，会缓存小or中图imageview对象，当请求相应的中图，大图时，会回填之前失败的imageview。
 */
- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill;

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                                   placeholder:(nullable UIImage *)placeholder;

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                                       options:(BDImageRequestOptions)options;

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                                   placeholder:(nullable UIImage *)placeholder
                                       options:(BDImageRequestOptions)options
                                    completion:(nullable BDImageRequestCompletedBlock)completion;

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                                   placeholder:(nullable UIImage *)placeholder
                                       options:(BDImageRequestOptions)options
                                      progress:(nullable BDImageRequestProgressBlock)progress
                                    completion:(nullable BDImageRequestCompletedBlock)completion;

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                                   placeholder:(nullable UIImage *)placeholder
                                       options:(BDImageRequestOptions)options
                                     cacheName:(nullable NSString *)cacheName
                                      progress:(nullable BDImageRequestProgressBlock)progress
                                    completion:(nullable BDImageRequestCompletedBlock)completion;

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                                   placeholder:(nullable UIImage *)placeholder
                                       options:(BDImageRequestOptions)options
                                   transformer:(nullable BDBaseTransformer *)transformer
                                      progress:(nullable BDImageRequestProgressBlock)progress
                                    completion:(nullable BDImageRequestCompletedBlock)completion;

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                               alternativeURLs:(nullable NSArray *)alternativeURLs
                                   placeholder:(nullable UIImage *)placeholder
                                       options:(BDImageRequestOptions)options
                                     cacheName:(nullable NSString *)cacheName
                                   transformer:(nullable BDBaseTransformer *)transformer
                                      progress:(nullable BDImageRequestProgressBlock)progress
                                    completion:(nullable BDImageRequestCompletedBlock)completion;

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                               alternativeURLs:(nullable NSArray *)alternativeURLs
                                   placeholder:(nullable UIImage *)placeholder
                                       options:(BDImageRequestOptions)options
                               timeoutInterval:(CFTimeInterval)timeoutInterval
                                     cacheName:(nullable NSString *)cacheName
                                   transformer:(nullable BDBaseTransformer *)transformer
                                      progress:(nullable BDImageRequestProgressBlock)progress
                                    completion:(nullable BDImageRequestCompletedBlock)completion;

@end

NS_ASSUME_NONNULL_END
