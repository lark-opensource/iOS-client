//
//  BDImageDecoderConfig.h
//  BDWebImage
//
//  Created by 陈奕 on 2021/3/30.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BDImageDecoderSizeType) {
    BDImageDecoderOriginSize = 0, ///原图尺寸
    BDImageDecoderDownsampledSize,///降采样尺寸
    BDImageDecoderCroppedSize,    ///裁剪尺寸
    BDImageDecoderScaleDownSize,  ///缩放尺寸
};

NS_ASSUME_NONNULL_BEGIN

@interface BDImageDecoderConfig : NSObject

@property (nonatomic, assign) BOOL decodeForDisplay;
@property (nonatomic, assign) BOOL shouldScaleDown;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) CGSize downsampleSize;
@property (nonatomic, assign) CGRect cropRect;

- (CGSize)imageCanvasSize:(CGSize)originSize;

- (BDImageDecoderSizeType)imageSizeType:(CGSize)originSize;

@end

NS_ASSUME_NONNULL_END
