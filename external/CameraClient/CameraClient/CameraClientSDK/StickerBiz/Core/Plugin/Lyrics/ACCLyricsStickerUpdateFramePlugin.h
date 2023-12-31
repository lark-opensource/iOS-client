//
//  ACCLyricsStickerUpdateFramePlugin.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2020/12/6.
//

#import <Foundation/Foundation.h>
#import <CreativeKitSticker/ACCStickerPluginProtocol.h>
#import <CreationKitRTProtocol/ACCEditStickerProtocol.h>

@class VEEditorSession;

NS_ASSUME_NONNULL_BEGIN

// 歌词贴纸更新 Frame 插件
@interface ACCLyricsStickerUpdateFramePlugin : NSObject<ACCStickerOverAheadGesturePluginProtocol>

// 用来更新贴纸大小
@property (nonatomic, strong) id<ACCEditStickerProtocol> editStickerService;

@end

NS_ASSUME_NONNULL_END
