//
//  VEEditorSession+ACCSticker.m
//  CameraClient
//
//  Created by haoyipeng on 2020/8/18.
//

#import "VEEditorSession+ACCSticker.h"
#import <objc/runtime.h>

@implementation VEEditorSession (ACCSticker)

- (NSArray<IESInfoSticker *> *)acc_infoStickers
{
    return [self getInfoStickers];
}

- (NSNumber *)acc_filterMusicLyricStickerId
{
    __block NSNumber *musicStickerId;
    [self.acc_infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isSrtInfoSticker) {
            musicStickerId = @(obj.stickerId);
            *stop = YES;
        }
    }];
    return musicStickerId;
}

- (NSString *)acc_filterMusicLyricEffectId
{
    __block NSString *musicEffectId;
    [self.acc_infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isSrtInfoSticker) {
            NSDictionary *userInfo = obj.userinfo;
            musicEffectId = userInfo[@"stickerID"];
            *stop = YES;
        }
    }];
    return musicEffectId;
}

- (UIColor *)acc_filterMusicLyricColor
{
    __block UIColor *musicLyricColor;
    [self.acc_infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isSrtInfoSticker && obj.param.srtColor) {
            SrtColor *srtColor = obj.param.srtColor;
            musicLyricColor = [UIColor colorWithRed:srtColor.red green:srtColor.green blue:srtColor.blue alpha:srtColor.alpha];
            *stop = YES;
        }
    }];
    return musicLyricColor;
}

- (void)acc_setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY angle:(CGFloat)angle scale:(CGFloat)scale
{
    [self setSticker:stickerId offsetX:offsetX offsetY:offsetY];
    [self setStickerRelativeScale:stickerId scale:scale];
    [self setStickerAngle:stickerId angle:angle];
}

- (void)acc_setStickerAboveForInfoSticker:(NSInteger)stickerId
{
    [self setStickerAbove:stickerId];
    if (self.acc_fixedTopInfoSticker != -1) {
        [self setStickerAbove:self.acc_fixedTopInfoSticker];
    }
}

- (void)setAcc_fixedTopInfoSticker:(NSInteger)acc_topInfoSticker
{
    objc_setAssociatedObject(self, @selector(acc_fixedTopInfoSticker), @(acc_topInfoSticker), OBJC_ASSOCIATION_RETAIN);
}

- (NSInteger)acc_fixedTopInfoSticker
{
    NSNumber *stickerId = objc_getAssociatedObject(self, @selector(acc_fixedTopInfoSticker));
    if (!stickerId) {
        return -1;
    }
    return stickerId.integerValue;
}

@end
