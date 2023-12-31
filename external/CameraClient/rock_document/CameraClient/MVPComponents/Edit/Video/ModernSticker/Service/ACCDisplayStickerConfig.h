//
//  ACCDisplayStickerConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/6/1.
//

#import <CreativeKitSticker/ACCStickerConfig.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCDisplayStickerConfig : ACCStickerConfig
// alignPoint是归一化的点，在此基础上允许加上一个额外的绝对值offset
@property (nonatomic, assign) CGPoint alignPointOffset;
// 是否自动设置alignPosition，默认的alignPosition就是通过alignPoint计算出来的点
@property (nonatomic, assign) BOOL syncAlignPosition;
// 是否自动同步大小
@property (nonatomic, assign) BOOL syncCoordinateChange;

@end

NS_ASSUME_NONNULL_END
