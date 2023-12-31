//
//  IESInfoSticker+ACCAdditions.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/5/18.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/IESInfoSticker.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCEditEmbeddedStickerType) {
    // 信息化贴纸
    ACCEditEmbeddedStickerTypeInfo,
    // 文字贴纸，使用图片信息化贴纸实现
    ACCEditEmbeddedStickerTypeText,
    // 新 POI 贴纸，使用 VE 文字贴纸实现
    ACCEditEmbeddedStickerTypeModrenPOI,
    // Mention Hashtag 贴纸，使用图片信息化贴纸实现
    ACCEditEmbeddedStickerTypeSocial,
    // 视频评论贴纸，使用图片信息化贴纸实现
    ACCEditEmbeddedStickerTypeVideoComment,
    // 歌词贴纸，使用歌词信息化贴纸实现
    ACCEditEmbeddedStickerTypeLyrics,
    // 放大镜贴纸，使用图片信息化贴纸实现
    ACCEditEmbeddedStickerTypeMagnifier,
    ACCEditEmbeddedStickerTypeNearbyHashtag,
    // 日常贴纸，使用信息化贴纸实现
    ACCEditEmbeddedStickerTypeDaily,
    // 自定义贴纸，使用图片信息化贴纸实现
    ACCEditEmbeddedStickerTypeCustom,
    // 自动字幕贴纸，不存储草稿
    ACCEditEmbeddedStickerTypeCaption,
    // 通过 UIImage 创建的贴纸，不存储草稿
    ACCEditEmbeddedStickerTypeUIImage,
    // K 歌贴纸
    ACCEditEmbeddedStickerTypeKaraoke,
    // 物种识别
    ACCEditEmbeddedStickerTypeGroot,
    // 心愿
    ACCEditEmbeddedStickerTypeWish
};

// K 歌子类型
typedef NS_ENUM(NSUInteger, ACCKaraokeStickerType) {
    ACCKaraokeStickerTypeLyric = 0,
    ACCKaraokeStickerTypeLyricTitle = 1,
    ACCKaraokeStickerTypeLyricSubTitle = 2
};

@interface IESInfoSticker(ACCAddtions)

@property (nonatomic, assign, readonly) ACCEditEmbeddedStickerType acc_stickerType;
@property (nonatomic, assign, readonly) ACCKaraokeStickerType acc_karaokeType;
@property (nonatomic, assign, readonly) BOOL acc_isNotNormalInfoSticker;
@property (nonatomic, assign, readonly) BOOL acc_isImageSticker;
// 对应 ACCInfoStickerComponent 处理的贴纸类型
@property (nonatomic, assign, readonly) BOOL acc_isBizInfoSticker;

@end

@interface NSDictionary(ACCSticker)

@property (nonatomic, assign, readonly) ACCEditEmbeddedStickerType acc_stickerType;
@property (nonatomic, assign, readonly) ACCKaraokeStickerType acc_karaokeType;
@property (nonatomic, assign, readonly) BOOL acc_isNotNormalInfoSticker;
@property (nonatomic, assign, readonly) BOOL acc_isImageSticker;
// 对应 ACCInfoStickerComponent 处理的贴纸类型
@property (nonatomic, assign, readonly) BOOL acc_isBizInfoSticker;

@end

@interface NSMutableDictionary(ACCSticker)

@property (nonatomic, assign) ACCEditEmbeddedStickerType acc_stickerType;
@property (nonatomic, assign) ACCKaraokeStickerType acc_karaokeType;

@end

NS_ASSUME_NONNULL_END
