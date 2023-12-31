//
//  CAKToast.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CAKToastStyle){
  CAKToastStyleNormal,
  CAKToastStyleSuccess,
  CAKToastStyleError,
};

@interface CAKToast : NSObject

+ (void)showToast:(nullable NSString *)content;

+ (void)showToast:(nullable NSString *)content withStyle:(CAKToastStyle)style;

+ (void)showToast:(nullable NSString *)content onView:(UIView *)view withStyle:(CAKToastStyle)style;

+ (void)showToast:(nullable NSString *)content withImage:(nullable UIImage *)image;

+ (void)dismissToast;

@end

NS_ASSUME_NONNULL_END
