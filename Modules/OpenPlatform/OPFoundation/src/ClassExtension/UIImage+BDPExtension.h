//
//  UIImage+BDPExtension.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/29.
//

#import <UIKit/UIKit.h>

@interface UIImage (BDPExtension)


/// Creates an image object from the specified named asset in TimorAsset bundle
/// @param name image name
+ (instancetype)bdp_imageNamed:(NSString *)name;
- (UIImage *)scaledToSize:(CGSize)newSize;
+ (UIImage *)imageWithWebPData:(NSData *)data;
+ (UIImage *)bdp_imageWithUIColor:(UIColor *)color;
+ (UIImage *)bdp_fixOrientation:(UIImage *)srcImg;

/// 通过 gif的data 生成 _UIAnimatedImage
/// @param theData  gif data
+ (UIImage * _Nullable)bdp_animatedImageWithGIFData:(NSData * _Nonnull)theData;

/// 通过 gif的url 生成 _UIAnimatedImage
/// @param theURL gif url
+ (UIImage * _Nullable)bdp_animatedImageWithGIFURL:(NSURL * _Nonnull)theURL;

@end

FOUNDATION_EXTERN NSData * _Nullable BDPImageAnimatedGIFRepresentation(UIImage *image, NSTimeInterval duration, NSUInteger loopCount, NSError * __autoreleasing *error);
