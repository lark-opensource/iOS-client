//
//  ACCLyricsStickerHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/5/6.
//

#import <Foundation/Foundation.h>
#import "ACCStickerHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCLyricsStickerHandler : ACCStickerHandler

/// @todo @qiuhang 临时方案，后续提把component的实现移入
@property (nonatomic, copy) void (^onExpressLyricsSticker)(ACCEditorLyricsStickerConfig *stickerConfig);

@end

NS_ASSUME_NONNULL_END
