//
//  ACCStickerPreviewView.h
//  CameraClient
//
//  Created by guocheng on 2020/5/28.
//

#import <CreativeKitSticker/ACCStickerContainerPluginProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;

@interface ACCStickerPreviewView : UIView <ACCStickerGestureResponsiblePluginProtocol>

- (void)updateMusicCoverWithMusicModel:(id<ACCMusicModelProtocol>)model;

@end

NS_ASSUME_NONNULL_END
