//
//  BDWebImageUtil.h
//  BDWebImage
//
//  Created by Lin Yong on 2019/2/11.
//

#import <Foundation/Foundation.h>

@interface BDWebImageUtil : NSObject

+ (UIImage * _Nullable)decodeImageData:(NSData * _Nullable)data
                            imageClass:(__unsafe_unretained Class _Nonnull )imageClass
                                 scale:(CGFloat)scale
                      decodeForDisplay:(BOOL)decode
                       shouldScaleDown:(BOOL)scaleDown;

+ (UIImage * _Nullable)decodeImageData:(NSData * _Nullable)data
                            imageClass:(__unsafe_unretained Class _Nonnull)imageClass
                                 scale:(CGFloat)scale
                      decodeForDisplay:(BOOL)decode
                       shouldScaleDown:(BOOL)scaleDown
                        downsampleSize:(CGSize)size
                              cropRect:(CGRect)cropRect
                                 error:(NSError * _Nullable __autoreleasing *_Nullable)error;

/**
 判断当前解码出来的图是否出现白屏/黑屏的现象
 @param image       解码后的图片
 @param samplingPoint       自定义采样点数，默认为30
 @return 正常：0 ，black：1，white：2，transparent：3
 */
+ (NSInteger)isWhiteOrBlackImage:(UIImage *_Nonnull)image samplingPoint:(NSInteger)samplingPoint;

/**
 this is a func to get maximum common divisor from an array

 @param n array size
 @param a array to be calculate
 @return Maximum common divisor of the array
 */
int gcdArray(int n,  int a[_Nonnull n]);

BOOL isAnimatedImageData(NSData *_Nonnull data);

@end
