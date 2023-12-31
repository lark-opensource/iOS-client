//
//  ACCLyricsStickerUtils.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2020/12/2.
//

#import <Foundation/Foundation.h>
#import <CreativeKitSticker/ACCStickerContentProtocol.h>
#import <CreationKitRTProtocol/ACCEditStickerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;
@class VEEditorSession;

// 歌词贴纸工具方法
@interface ACCLyricsStickerUtils : NSObject

/// 更新歌词贴纸位置
/// @note 歌词贴纸是由 VE 渲染，这里的视图是个透明视图，用来处理手势操作
/// @param wrapperView 歌词贴纸视图
/// @param editStickerService 贴纸服务
+ (void)updateFrameForLyricsStickerWrapperView:(ACCStickerViewType)wrapperView
                            editStickerService:(id<ACCEditStickerProtocol>)editStickerService;


/// 格式化歌词贴纸
/// @param musicModel 歌曲 model
/// @param completion 回调格式化的歌词信息
+ (void)formatMusicLyricWithACCMusicModel:(id<ACCMusicModelProtocol>)musicModel
                               completion:(nullable void (^)(NSString *lyricStr, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
