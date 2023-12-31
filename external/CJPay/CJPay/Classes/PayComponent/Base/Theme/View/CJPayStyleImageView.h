//
//  CJPayStyleImageView.h
//  CJPay-Example
//
//  Created by wangxinhua on 2020/9/23.
//

#import <Foundation/Foundation.h>
#import <BDWebImage/BDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayStyleImageView : BDImageView

/**
 *  跟随宿主主题的图片
 *
 *  @param imageName 图片名称
 */
- (void)setStyleImage:(NSString *)imageName;

/**
 *  可指定图片的背景色
 *
 *  @param imageName 图片名称
 *  @param color 背景色，默认为宿主颜色，若加载失败为透明
 */
- (void)setImage:(NSString *)imageName backgroundColor:(UIColor * _Nullable)color;

//网络加载图片支持主题色背景
- (void)setImageWithURL:(NSURL *)imageURL;

@end

NS_ASSUME_NONNULL_END
