//
//  VEEditorSession+ACCSticker.h
//  CameraClient
//
//  Created by haoyipeng on 2020/8/18.
//

#import <TTVideoEditor/VEEditorSession.h>
#import <TTVideoEditor/VEEditorSession+Effect.h>

NS_ASSUME_NONNULL_BEGIN

@interface VEEditorSession (ACCSticker)

@property (nonatomic, strong, readonly) NSArray<IESInfoSticker *> *acc_infoStickers;

@property (nonatomic, assign) NSInteger acc_fixedTopInfoSticker;

- (NSNumber *)acc_filterMusicLyricStickerId;
- (NSString *)acc_filterMusicLyricEffectId;
- (UIColor *)acc_filterMusicLyricColor;

- (void)acc_setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY angle:(CGFloat)angle scale:(CGFloat)scale;

- (void)acc_setStickerAboveForInfoSticker:(NSInteger)stickerId;

@end

NS_ASSUME_NONNULL_END
