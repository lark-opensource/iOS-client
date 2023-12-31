//
//  AVAssetImageGenerator+LV.h
//  VideoTemplate
//
//  Created by luochaojing on 2020/3/18.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAssetImageGenerator (LV)

+ (UIImage *_Nullable)lv_generateImageWithAsset:(AVAsset *)asset size:(CGSize)size time:(CMTime)time;

@end


@interface LVAssetImageGenerator : NSObject

@property (nonatomic, strong, readonly) AVAssetImageGenerator *generator;

- (instancetype)initWithAsset:(AVAsset *)asset size:(CGSize)size;

/// 生成预览图
/// @param edgeInset 四周的裁剪区域，归一化值。
/// @param time  时间点，内部会做时间判断
- (UIImage *_Nullable)generaImageWithEdgeInset:(UIEdgeInsets)edgeInset atTime:(CMTime)time;

@end

NS_ASSUME_NONNULL_END
