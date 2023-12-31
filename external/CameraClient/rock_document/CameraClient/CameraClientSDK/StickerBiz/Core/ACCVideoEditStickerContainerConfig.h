//
//  ACCVideoEditStickerContainerConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/10/7.
//

#import <CreativeKitSticker/ACCStickerContainerConfigProtocol.h>
#import <CreationKitRTProtocol/ACCEditStickerProtocol.h>

@protocol ACCMusicModelProtocol;
@protocol ACCEditServiceProtocol;

@interface ACCVideoEditStickerContainerConfig : NSObject<ACCStickerContainerConfigProtocol>

@property (nonatomic, strong, nullable) id<ACCEditStickerProtocol> editStickerService; /// Pin贴纸功能所需

- (void)addPlugin:(nonnull id<ACCStickerContainerPluginProtocol>)plugin;

- (void)updateMusicCoverWithMusicModel:(nullable id<ACCMusicModelProtocol>)model;

- (void)reomoveSafeAreaPlugin;
- (void)removeAdsorbingPlugin;
- (void)removePreviewViewPlugin;

// 移除除了编辑贴纸插件以外的插件
- (void)removePluginsExceptEditLyrics;

- (void)changeAlbumImagePluginsWithMaterialSize:(CGSize)size;

@end
