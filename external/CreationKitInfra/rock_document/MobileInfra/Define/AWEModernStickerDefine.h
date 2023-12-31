//
//  AWEModernStickerDefine.h
//  AWEStudio
//
// Created by Hao Yipeng on April 17, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#ifndef AWEModernStickerDefine_h
#define AWEModernStickerDefine_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AWEStickerPanelType) {
    AWEStickerPanelTypeRecord,
    AWEStickerPanelTypeLive,
    AWEStickerPanelTypeStory,
    AWEStickerPanelTypeZoom,
    AWEStickerPanelTypeCreatorPreview // Creator Preview Sticker Panel.
};

typedef NS_ENUM(NSInteger, AWEModernStickerCollectionViewTag) {
	AWEModernStickerCollectionViewTagTitle = 1,
	AWEModernStickerCollectionViewTagContent,
	AWEModernStickerCollectionViewTagSticker,
};

typedef NS_ENUM(NSInteger, AWEEffectDownloadStatus) {
    AWEEffectDownloadStatusUndownloaded = 1,
    AWEEffectDownloadStatusDownloaded,
    AWEEffectDownloadStatusDownloading,
    AWEEffectDownloadStatusDownloadFail
};

typedef NSString *AWEModernStickerMonitorKey;

static AWEModernStickerMonitorKey const AWE_STICKER_DOWNLOAD_KEY =  @"aweme_sticker_platform_download_error";

#endif /* AWEModernStickerDefine_h */
