//
//  ACCImageAlbumEditorDefine.h
//  CameraClient
//
//  Created by imqiuhang on 2020/12/31.
//

#ifndef ACCImageAlbumEditorDefine_h
#define ACCImageAlbumEditorDefine_h

// 在一次创作流程中是否已经展示过气泡...
static NSString *const ACCImageAlbumSessionSwitchModeBubbleShowenKey = @"ACCImageAlbumSessionSwitchModeBubbleShowenKey";

@class ACCImageAlbumItemModel;

#define  ACCImageEditModeObjUsingCustomerInitOnly \
- (instancetype)init NS_UNAVAILABLE; \
+ (instancetype)new  NS_UNAVAILABLE;


#define ACCImageEditInvaildStickerId (INT32_MIN)
#define ACCImageEditFakeStickerId (-1)

NS_INLINE BOOL ACCIImageEditIsInvaildSticker(NSInteger stickerId) {
    return (stickerId == ACCImageEditInvaildStickerId);
}

typedef NS_OPTIONS(NSUInteger, ACCImageAlbumEditorEffectUpdateType) {
    ACCImageAlbumEditorEffectUpdateTypeNone   = 1 << 0,
    ACCImageAlbumEditorEffectUpdateTypeHDR    = 1 << 1,
    ACCImageAlbumEditorEffectUpdateTypeFilter = 1 << 2,
    ACCImageAlbumEditorEffectUpdateTypeAll    = (ACCImageAlbumEditorEffectUpdateTypeHDR |
                                                 ACCImageAlbumEditorEffectUpdateTypeFilter)
};

typedef NS_OPTIONS(NSUInteger, ACCImageAlbumEditorStickerUpdateType) {
    //                                                       // type        |   props.value
    ACCImageAlbumEditorStickerUpdateTypeNone     = 0,        // none        |   none
    ACCImageAlbumEditorStickerUpdateTypeRotation = 1 << 0,   // Rotation    |   props.angle
    ACCImageAlbumEditorStickerUpdateTypeScale    = 1 << 1,   // Scale       |   props.scale
    ACCImageAlbumEditorStickerUpdateTypeAlpha    = 1 << 2,   // Alpha       |   props.alpha
    ACCImageAlbumEditorStickerUpdateTypeOffset   = 1 << 3,   // Offset      |   props.offsetX && props.offsetY
    ACCImageAlbumEditorStickerUpdateTypeAbove    = 1 << 4,   // set Above   |   nil
};

typedef NS_OPTIONS(NSUInteger, ACCImageAlbumEditorExportTypes) {
    AACCImageAlbumEditorExportTypeImage   = 1 << 0, // 如果批量导出高清尺寸，建议使用filePath方式来减少内存压力
    ACCImageAlbumEditorExportTypeFilePath = 1 << 1,
    ACCImageAlbumEditorExportTypeBoth     = (AACCImageAlbumEditorExportTypeImage |
                                             ACCImageAlbumEditorExportTypeFilePath)
};

typedef NS_ENUM(NSUInteger,  ACCImageAlbumEditorExportResult) {
    ACCImageAlbumEditorExportResultSucceed              = 0,
    ACCImageAlbumEditorExportResultInvaildOriginalImage = 1,
    ACCImageAlbumEditorExportResultInvaildImageData     = 2,
    ACCImageAlbumEditorExportResultRenderError          = 3,
    ACCImageAlbumEditorExportResultWriteToFileError     = 4
};

typedef NS_ENUM(NSUInteger,  ACCImageAlbumEditorPageControlStyle) {
    ACCImageAlbumEditorPageControlStylePageCotrol  = 0,          // 默认样式            ==>  1/4
    ACCImageAlbumEditorPageControlStyleProgress = 1,             // 日常进度条样式，带动画 ==>  ━ ═ ═ ═
    ACCImageAlbumEditorPageControlStyleProgressAsPageCotrol = 2, // 同Progress样式，无切换动画
    ACCImageAlbumEditorPageControlStyleHiddenAll = 3,            // 不展示进度条，兼容以后，暂未使用
};

// 图文图片裁切比例选项
typedef NS_ENUM(NSUInteger, ACCImageAlbumItemCropRatio) {
    ACCImageAlbumItemCropRatioOriginal  = 0,
    ACCImageAlbumItemCropRatio9_16,
    ACCImageAlbumItemCropRatio3_4,
    ACCImageAlbumItemCropRatio1_1,
    ACCImageAlbumItemCropRatio4_3,
    ACCImageAlbumItemCropRatio16_9
};

typedef void(^ACCImageAlbumEditorContentViewRecoveredHandler)(UIView *contentView,
                                                       ACCImageAlbumItemModel *imageItemModel,
                                                       NSInteger index,
                                                       CGSize imageLayerSize,
                                                              CGSize originalImageLayerSize);
typedef void(^ACCImageAlbumEditorPreviewModeHandler)(UIView *contentView,
                                                       BOOL isPreviewMode);
         
#endif /* ACCImageAlbumEditorDefine_h */
