//
//  ACCLyricsStickerContentView.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2020/12/1.
//

#import <UIKit/UIKit.h>
#import "ACCStickerEditContentProtocol.h"
#import "ACCLyricsStickerConfig.h"

@class IESInfoStickerProps;

NS_ASSUME_NONNULL_BEGIN

/// 歌词贴纸是由 VE 渲染，这里的视图是个透明视图，用来处理手势操作
@interface ACCLyricsStickerContentView : UIView<ACCStickerEditContentProtocol>

@property (nonatomic, assign) NSInteger stickerId;

@property (nonatomic, strong) ACCLyricsStickerConfig *config;

@property (nonatomic, strong) IESInfoStickerProps *stickerInfos;

// 记录开始的时候的初始坐标，用于坐标恢复
@property (nonatomic, assign) CGPoint beginOrigin;
// 不需要在有手势时额外进行Frame计算
@property (nonatomic, assign) BOOL ignoreUpdateFrameWithGesture;

// 设置透明度实现
@property (nonatomic, copy, nullable) void (^transparentChanged)(BOOL);

/// 更新歌词贴纸大小
/// @param size 歌词贴纸大小
- (void)updateSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
