//
//  UIImageView+CJPay.h
//  CJPay
//
//  Created by 王新华 on 2019/6/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class BDWebImageRequest;

@interface UIImageView(CJPay)

@property (nonatomic, strong) UIImage *silentImage;
/**
 *  设置URL图片
 *
 *  @param imageURL 图片名称
 */
- (nullable BDWebImageRequest *)cj_setImageWithURL:(nonnull NSURL *)imageURL;
/**
 *  设置URL图片
 *
 *  @param imageURL 图片链接
 *  @param placeholder 兜底图片
 */
- (nullable BDWebImageRequest *)cj_setImageWithURL:(nonnull NSURL *)imageURL
                                   placeholder:(nullable UIImage *)placeholder;
/**
 *  设置URL图片
 *
 *  @param imageURL 图片链接
 *  @param placeholder 兜底图片
 *  @param completion 完成时回调
 */
- (BDWebImageRequest *)cj_setImageWithURL:(NSURL *)imageURL
                           placeholder:(nullable UIImage *)placeholder
                            completion:(nullable void (^)(UIImage * _Nonnull, NSData * _Nonnull, NSError * _Nonnull))completion;
/**
 *  设置普通图片
 *
 *  @param imageName 图片名称
 */
- (void)cj_setImage:(NSString *)imageName;
/**
 *  设置普通图片
 *
 *  @param imageName 图片名称
 *  @param completion 完成时回调
 */
- (void)cj_setImage:(NSString *)imageName
         completion:(nullable void (^)(BOOL isSuccess))completion;

- (void)cj_startLoading;
- (void)cj_stopLoading;

@end

NS_ASSUME_NONNULL_END
