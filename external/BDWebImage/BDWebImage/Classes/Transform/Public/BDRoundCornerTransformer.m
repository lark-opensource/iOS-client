//
//  BDRoundCornerTransformer.m
//  Pods
//
//  Created by jiangliancheng on 2017/4/19.
//
//

#import "BDRoundCornerTransformer.h"
//#import "BDWebImage.h"
#import "UIImage+BDImageTransform.h"
//#import "BDWebImageRequest.h"
//#import "BDWebImageRequest+TTMonitor.h"
#import "BDImagePerformanceRecoder.h"

@interface BDRoundCornerTransformer()
@property (nonatomic, assign) NSUInteger imageSize;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, strong) UIColor *borderColor;

@end

@implementation BDRoundCornerTransformer

+ (NSMutableDictionary*)transformerMap;
{
    static NSMutableDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = [NSMutableDictionary new];
    });
    return map;
}


+ (instancetype)transformerWithImageSize:(BDRoundCornerImageSizes)imageSize
{
    return [self transformerWithImageSize:imageSize borderWidth:0 borderColor:nil];
}

+ (instancetype)transformerWithImageSize:(BDRoundCornerImageSizes)imageSize borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor
{
    NSString *key = [NSString stringWithFormat:@"%td_%.0f_%@", imageSize, borderWidth, borderColor];
    BDRoundCornerTransformer *transformer = [self transformerMap][key];
    if (!transformer) {
        transformer = [BDRoundCornerTransformer new];
        transformer.imageSize = imageSize;
        transformer.borderColor = borderColor;
        transformer.borderWidth = borderWidth;
        [[self transformerMap] setValue:transformer forKey:key];
    }
    return transformer;
}

+ (instancetype)defaultTransformer;
{
    return [self transformerWithImageSize:BDRoundCornerImageSize100];
}

- (BOOL)isAppliedToThumbnail {
    return YES;
}

- (nonnull NSString *)appendingStringForCacheKey;
{
    return [NSString stringWithFormat:@"BDRoundCornerTransformer_%td_%.0f_%@",self.imageSize, self.borderWidth, self.borderColor];
}

- (nullable UIImage *)transformImageBeforeStoreWithImage:(nullable UIImage *)image;
{
    if (!image) {
        return nil;
    }
    
    //这里是为了不破坏gif的结构，同时这里处理的话只能将gif中的帧全部处理，比较耗内存
    BOOL isAnimatedImage = ([image isKindOfClass:BDImage.class] && ((BDImage *)image).frameCount > 1);
    if (image && !isAnimatedImage) {//非动图才 transform
        image = [image bd_imageByResizeToSize:CGSizeMake(self.imageSize, self.imageSize)];
        return [image bd_imageByRoundCornerRadius:image.size.width/2 borderWidth:self.borderWidth borderColor:self.borderColor];
    }
    return image;
}

@end
