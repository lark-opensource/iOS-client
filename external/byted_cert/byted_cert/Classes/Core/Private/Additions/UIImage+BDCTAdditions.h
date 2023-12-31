//
//  UIImage+BDBCAdditions.h
//  byted_cert-byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2020/12/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface UIImage (BDBCAdditions)

+ (UIImage *)bdct_holdSampleImage;

+ (UIImage *)bdct_loadingImage;

+ (UIImage *)bdct_imageWithName:(NSString *)name;

+ (NSData *)bdct_compressImage:(UIImage *)image compressRatio:(CGFloat)ratio;

- (UIImage *)bdct_cropToRect:(CGRect)rect;

- (UIImage *)bdct_transforCapturedImageWithMaxResoulution:(int)maxResolution isFrontCamera:(BOOL)isFrontCamera;

- (UIImage *)bdct_resizeWithMaxSide:(CGFloat)maxSide;

@end

NS_ASSUME_NONNULL_END
