//
//  UIImage+CJPay.h
//  CJPay
//
//  Created by 王新华 on 2/24/20.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage(CJPay)

+ (nullable UIImage *)cj_imageWithName:(NSString *)imageName;

+ (UIImage *)cj_imageWithColor: (UIColor *)color;

+ (UIImage *)cj_roundImageWithColor: (UIColor *)color;

+ (UIImage *)cj_rightAngleImageWithColor:(UIColor *)color width:(CGFloat)lineWidth rect:(CGRect)rect;

- (UIImage *)cj_imageWithAnotherImage:(UIImage *)anotherImage;

- (UIImage *)cj_scaleToSize:(CGSize)size;

+ (UIImage *)cj_imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (UIImage *)cj_changeWithColor:(UIColor *)color;


@end

NS_ASSUME_NONNULL_END
