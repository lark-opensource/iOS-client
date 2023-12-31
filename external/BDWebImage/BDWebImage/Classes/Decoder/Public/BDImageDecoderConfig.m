//
//  BDImageDecoderConfig.m
//  BDWebImage
//
//  Created by 陈奕 on 2021/3/30.
//

#import "BDImageDecoderConfig.h"

@implementation BDImageDecoderConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.decodeForDisplay = YES;
        self.shouldScaleDown = NO;
        self.scale = 1;
        self.downsampleSize = CGSizeZero;
        self.cropRect = CGRectZero;
    }
    return self;
}

- (CGSize)imageCanvasSize:(CGSize)originSize {
    if (!CGRectEqualToRect(self.cropRect, CGRectZero) && CGRectContainsRect(CGRectMake(0, 0, originSize.width, originSize.height), self.cropRect)) {
        return self.cropRect.size;
    }
    
    CGFloat downsampleWidth = self.downsampleSize.width;
    CGFloat downsampleHeight = self.downsampleSize.height;
    CGFloat canvasWidth = originSize.width;
    CGFloat canvasHeight = originSize.height;
    if ((downsampleWidth > 0 || downsampleHeight > 0) && !CGSizeEqualToSize(originSize, CGSizeZero) && downsampleWidth < canvasWidth && downsampleHeight < canvasHeight) {
        if (canvasWidth * downsampleHeight > downsampleWidth * canvasHeight) {
            downsampleWidth = downsampleHeight * canvasWidth / canvasHeight;
        } else {
            downsampleHeight = downsampleWidth * canvasHeight / canvasWidth;
        }
        return CGSizeMake(downsampleWidth, downsampleHeight);
    }
    
    return originSize;
}

- (BDImageDecoderSizeType)imageSizeType:(CGSize)originSize {
    if (!CGRectEqualToRect(self.cropRect, CGRectZero) && CGRectContainsRect(CGRectMake(0, 0, originSize.width, originSize.height), self.cropRect)) {
        return BDImageDecoderCroppedSize;
    }
    
    CGFloat downsampleWidth = self.downsampleSize.width;
    CGFloat downsampleHeight = self.downsampleSize.height;
    if ((downsampleWidth > 0 || downsampleHeight > 0) && !CGSizeEqualToSize(originSize, CGSizeZero) && downsampleWidth < originSize.width && downsampleHeight < originSize.height) {
        return BDImageDecoderDownsampledSize;
    }
    
    if (self.shouldScaleDown) {
        return BDImageDecoderScaleDownSize;
    }
    
    return BDImageDecoderOriginSize;
}

- (id)copyWithZone:(NSZone *)zone
{
    BDImageDecoderConfig *config = [[self class] allocWithZone:zone];
    config.decodeForDisplay = self.decodeForDisplay;
    config.shouldScaleDown = self.shouldScaleDown;
    config.scale = self.scale;
    config.downsampleSize = self.downsampleSize;
    config.cropRect = self.cropRect;
    return config;
}

@end
