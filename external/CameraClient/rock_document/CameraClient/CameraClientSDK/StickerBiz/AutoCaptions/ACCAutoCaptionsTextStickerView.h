//
//  ACCAutoCaptionsTextStickerView.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/27.
//

#import "ACCTextStickerView.h"
#import "ACCStickerEditContentProtocol.h"

NS_ASSUME_NONNULL_BEGIN

// 自动字幕由客户端生成图片交给 VE 渲染，容器这边的视图是个空壳
@interface ACCAutoCaptionsTextStickerView : UIView<ACCStickerEditContentProtocol>

// 设置透明度实现
@property (nonatomic, copy, nullable) void (^transparentChanged)(BOOL);

/// 更新歌词贴纸大小
/// @param size 歌词贴纸大小
- (void)updateSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
