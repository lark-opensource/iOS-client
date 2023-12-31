//
//  ACCRepoImageAlbumInfoModel+ACCStickerLogic.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2021/3/3.
//

#import "ACCRepoImageAlbumInfoModel+ACCStickerLogic.h"
#import "ACCImageAlbumData.h"
#import "IESInfoSticker+ACCAdditions.h"

@implementation ACCRepoImageAlbumInfoModel (ACCStickerLogic)

- (BOOL)isHaveAnySticker
{
    return self.isHaveAnyInfoSticker || self.isHaveAnyTextSticker || self.isHaveAnyInteractionSticker;
}

- (BOOL)isHaveAnyCustomSticker
{
    BOOL __block flag = NO;
    
    [self.imageAlbumData.imageAlbumItems.copy enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.stickerInfo.stickers.copy enumerateObjectsUsingBlock:^(ACCImageAlbumStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isCustomerSticker]) {
                flag = YES;
                *stop = YES;
            }
        }];

        *stop = flag;
    }];

    return flag;
}

- (BOOL)isHaveAnyInfoSticker
{
    BOOL __block flag = NO;
    
    [self.imageAlbumData.imageAlbumItems.copy enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stickerInfo.stickers.count > 0) {
            *stop = YES;
            flag  = YES;
        }
    }];
    
    return flag;
}

- (BOOL)isHaveAnyTextSticker
{
    BOOL __block flag = NO;
    
    [self.imageAlbumData.imageAlbumItems.copy enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stickerInfo.textStickers.count > 0) {
            *stop = YES;
            flag = YES;
        }
    }];
    
    return flag;
}

- (BOOL)isHaveAnyInteractionSticker
{
    BOOL __block flag = NO;
    
    [self.imageAlbumData.imageAlbumItems.copy enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stickerInfo.interactionStickers.count > 0) {
            *stop = YES;
            flag = YES;
        }
    }];
    
    return flag;
}

- (NSInteger)numberOfStickers
{
    NSInteger ret = 0;
    for (ACCImageAlbumItemModel *item in [self.imageAlbumData.imageAlbumItems copy]) {
        ret += item.stickerInfo.stickers.count + item.stickerInfo.textStickers.count + item.stickerInfo.interactionStickers.count;
        if (item.stickerInfo.textStickers.count > 0) {
            for (ACCImageAlbumStickerModel *sticker in item.stickerInfo.stickers) {
                if (sticker.userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeText) {
                    ret -= 1; // remove duplicate stickers
                }
            }
        }
    }
    return ret;
}

@end
