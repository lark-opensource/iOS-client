//
//  ACCInfoStickerPinPlugin.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/9/30.
//

#import <CreativeKitSticker/ACCStickerPluginProtocol.h>

@protocol ACCEditStickerProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface ACCInfoStickerPinPlugin : NSObject<ACCStickerOverAheadGesturePluginProtocol>

@property (nonatomic, strong) id<ACCEditStickerProtocol> editStickerService; /// Pin贴纸功能所需

- (void)cancelAllPinnedSticker;

@end

NS_ASSUME_NONNULL_END
