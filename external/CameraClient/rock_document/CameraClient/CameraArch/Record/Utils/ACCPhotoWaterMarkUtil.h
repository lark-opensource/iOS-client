//
//  ACCPhotoWaterMarkUtil.h
//  Pods
//
//  Created by chengfei xiao on 2019/9/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCPhotoWateMarkCompletionBlock)(UIImage * _Nullable combinedImage);

@interface ACCPhotoWaterMarkUtil : NSObject

//给下载的图片加水印可以直接调用这个方法,会加一个默认的水印
+ (void)acc_addWaterMarkForSourceImage:(UIImage *)sourceImage completion:(ACCPhotoWateMarkCompletionBlock)completionBlock;

+ (void)acc_addWaterMarkForSourceImage:(UIImage *)sourceImage waterMarkImageName:(NSString *)waterMarkImageName completion:(ACCPhotoWateMarkCompletionBlock)completionBlock;

+ (void)acc_addWaterMarkForSourceImage:(UIImage *)sourceImage waterMarkImage:(UIImage *)waterMarkImage completion:(ACCPhotoWateMarkCompletionBlock)completionBlock;

+ (void)acc_addWatermarkForEffectSourceImage:(UIImage *)sourceImage userName:(nullable NSString *)userName watermarkImage:(nullable UIImage *)waterMarkImage completion:(void(^)(UIImage * _Nullable))completionBlock;


@end

NS_ASSUME_NONNULL_END
