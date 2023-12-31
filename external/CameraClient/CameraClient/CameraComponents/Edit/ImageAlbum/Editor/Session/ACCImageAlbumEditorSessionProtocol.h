//
//  ACCImageAlbumEditorSessionProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/8/17.
//

#import <Foundation/Foundation.h>
#import "ACCImageAlbumEditorDefine.h"


@protocol ACCMusicModelProtocol;
@class ACCImageAlbumData, ACCImageAlbumItemModel;
@class ACCImageAlbumEditor, ACCImageAlbumStickerProps;
@class ACCImageAlbumStickerModel, ACCImageAlbumStickerSearchResult;
@class ACCImageAlbumExportItemModel;

@protocol ACCImageAlbumEditorSessionProtocolMix;
@protocol ACCImageAlbumEditorSessionProtocolSubPlayer;
@protocol ACCImageAlbumEditorSessionProtocolSubAudioControl;
@protocol ACCImageAlbumEditorSessionProtocolSubHDR;
@protocol ACCImageAlbumEditorSessionProtocolSubFilter;
@protocol ACCImageAlbumEditorSessionProtocolSubSticker;
@protocol ACCImageAlbumEditorSessionProtocolSubExport;


/// =============================================================
///              ACCImageAlbumEditorSessionProtocol
/// =============================================================

@protocol ACCImageAlbumEditorSessionProtocol
<
ACCImageAlbumEditorSessionProtocolMix,
ACCImageAlbumEditorSessionProtocolSubPlayer,
ACCImageAlbumEditorSessionProtocolSubAudioControl,
ACCImageAlbumEditorSessionProtocolSubHDR,
ACCImageAlbumEditorSessionProtocolSubFilter,
ACCImageAlbumEditorSessionProtocolSubSticker,
ACCImageAlbumEditorSessionProtocolSubExport
>

@end

/// =============================================================
///                           Mix
/// =============================================================

@protocol ACCImageAlbumEditorSessionProtocolMix

/// @param containerSize  max display size for image player
- (instancetype)initWithImageAlbumData:(ACCImageAlbumData *_Nonnull)albumData containerSize:(CGSize)containerSize;

@property (nonatomic, strong, readonly) ACCImageAlbumData *_Nullable albumData;

- (ACCImageAlbumItemModel *)imageItemAtIndex:(NSInteger)index;

/// @seealso onCustomerContentViewRecovered, is same imageLayerSize
/// calculate according to the original image size, so always return to the correct size，even is not rendering
- (CGSize)imageLayerSizeAtIndex:(NSInteger)imageIndex
                       needClip:(BOOL)needClip;

/// size of original image(px, not dp)
- (CGSize)imageOriginalSizeAtIndex:(NSInteger)index;

/// total  image item count in image data
/// like 'the number of frames in  video'
- (NSInteger)totalImageItemCount;

/// begin render transaction, will increase transaction's reference count
/// rendering service is disabled during this time(blocked util reference count is zero)
/// @WARNING using reference count, so calling 'endCurrentImageEditorBatchUpdate'  in pairs！ in pairs！ in pairs！
- (void)beginCurrentImageEditorBatchUpdate;

/// end render transaction
/// will do render if needed(if current reference count is zero)
- (void)endCurrentImageEditorBatchUpdate;

/// call back after the first image is rendered (include all effects/stickers, etc)successfully
/// @discussion It may be called more than once
/// @seealso resetWithContainerView:
@property (nonatomic, copy) void(^onFirstImageEditorRendered)(void);

@end


/// =============================================================
///                           Player
/// =============================================================

@protocol ACCImageAlbumEditorSessionProtocolSubPlayer

/// activate image player with 'container view'
/// will rebuild all cached editors, and reset all status
/// @seealso onFirstImageEditorRendered, will re callback this block after first image rendered
- (void)resetWithContainerView:(UIView *_Nullable)view;

/// reload data  if image album data is changed
- (void)reloadData;

/// scroll image page to target index
- (void)scrollToIndex:(NSInteger)index;

/// mark current image to need reload
- (void)markCurrentImageNeedReload;

- (void)startAutoPlay;

- (void)stopAutoPlay;

/// release all edit editors, pageview, exclude export editors
- (void)releasePlayer;

// 进度条等交互区域的container，animationable
- (void)updateInteractionContainerAlpha:(CGFloat)alpha;

/// @seealso onCustomerContentViewRecovered, is same content view
/// nil if index out of cache bounce
- (UIView *_Nullable)customerContentViewAtIndex:(NSInteger)imageIndex;

@property (nonatomic, assign, readonly) CGSize containerSize;

/// @seealso 'onCurrentImageEditorChanged'
@property (nonatomic, assign, readonly) NSInteger currentIndex;

/// setters
- (void)setBottomOffset:(CGFloat)bottomOffset;
- (void)setScrollEnable:(BOOL)scrollEnable;
- (void)setIsPreviewMode:(BOOL)isPreviewMode;
- (void)setPreviewSize:(CGSize)previewSize;
- (void)setPageControlStyle:(ACCImageAlbumEditorPageControlStyle)pageControlStyle;
- (void)setAutoPlayInterval:(NSTimeInterval)autoPlayInterval;

/// on image editor reused at 'index'
/// @param contentView can add customer subviews on 'contentView', will rebuild after reload, so is no need to clean up
/// @param imageLayerSize the actual rendering size of the image, width fit to 'containerSize'
@property (nonatomic, copy) ACCImageAlbumEditorContentViewRecoveredHandler onCustomerContentViewRecovered;
@property (nonatomic, copy) ACCImageAlbumEditorPreviewModeHandler onPreviewModeChanged;

@property (nonatomic, copy) void(^onCurrentImageEditorChanged)(NSInteger currentIndex, BOOL isByAutoTimer);

@property (nonatomic, copy) void(^onPlayerDraggingStatusChangedHandler)(BOOL isDragging);

@property (nonatomic, copy) void(^willScrollToIndexHandler)(NSInteger targetIndex, BOOL withAnimation, BOOL isByAutoTimer);

/// 初始化时图集数据还未ready的，用此接口更新, ADDED BY: larry.lai
/// eg. 发布后编辑需求是在进入发布页后才生成图集数据
/// @param albumData albumData
- (void)updateAlbumData:(ACCImageAlbumData *_Nonnull)albumData;

@end


/// =============================================================
///                           Audio
/// =============================================================

@protocol ACCImageAlbumEditorSessionProtocolSubAudioControl

// play from the beginning
- (void)replayMusic;

// play from the current time
- (void)continuePlayMusic;

// pause
- (void)pauseMusic;

/// will auto play if player is playing when replace
- (void)replaceMusic:(id<ACCMusicModelProtocol>_Nullable)music;

@end


/// =============================================================
///                           HDR
/// =============================================================

@protocol ACCImageAlbumEditorSessionProtocolSubHDR

/// init lens HDR Engine, init with absolute file paths
- (void)setupLensHDRModelWithFilePath:(NSString *_Nullable)filePath;

/// it didn't work if lens HDR engine is not init @see setupHDREngineWithPaths:
- (void)setHDREnable:(BOOL)enable;

@end


/// =============================================================
///                           Filter
/// =============================================================

@protocol ACCImageAlbumEditorSessionProtocolSubFilter

/// @WARNING only composer filters is supported
- (void)updateComposerFilterWithFilterId:(NSString *_Nullable)filterId
                                filePath:(NSString *_Nullable)filePath
                               intensity:(float)intensity;

@end


/// =============================================================
///                           Sticker
/// =============================================================

@protocol ACCImageAlbumEditorSessionProtocolSubSticker

/// add info sticker
/// @param path effect path or image path
/// @param effectInfo such as temperature info
/// @param userInfo customer infos, will copy to sticker model
/// @param imageIndex  imageIndex
/// @return sticker uniqueId, 有别于视频模式，这个不是VE视频的stickerId
///         是内部自行维护的sticker标识，内部会建立一个key-value映射到VE的stickerId
///         当然上层业务仍然可以当做stickerId去用，因为player层已经做了隔离，图片编辑的player内会自动维护映射关系
///         这么做的原因是图片编辑的贴纸是基于恢复模式，stickerId随时会变
///         所以只能通过player内维护了映射关系，这样业务可以根据id找到准确的贴纸
- (NSInteger)addInfoStickerWithPath:(NSString *_Nonnull)path
                         effectInfo:(NSArray *_Nullable)effectInfo
                           userInfo:(NSDictionary *_Nullable)userInfo
                         imageIndex:(NSInteger)imageIndex;

- (void)removeInfoStickerWithUniqueId:(NSInteger)uniqueId;

- (void)removeInfoStickerWithUniqueId:(NSInteger)uniqueId
              traverseAllEditorIfNeed:(BOOL)traverseAllEditorIfNeed;

/// update sticker info, options,  muti update is supported @see ACCImageAlbumEditorStickerUpdateType
- (void)updateInfoStickerWithUniqueId:(NSInteger)uniqueId
                          updateTypes:(ACCImageAlbumEditorStickerUpdateType)updateTypes
                                props:(ACCImageAlbumStickerProps *_Nullable)props;

/// get info sticker, find it in all  image item
- (ACCImageAlbumStickerSearchResult *)stickerWithUniqueId:(NSInteger)uniqueId;

/// get info sticker's bounding
/// @WARNING return zero is image editor is not rendering
- (UIEdgeInsets)getInfoStickerBoundingBoxWithUniqueId:(NSInteger)uniqueId;

@end


/// =============================================================
///                           Export
/// =============================================================

@protocol ACCImageAlbumEditorSessionProtocolSubExport

- (UIImage *_Nullable)capturePreviewUIImage;

- (void)getProcessedPreviewImageAtIndex:(NSInteger)index
                          preferredSize:(CGSize)size
                            compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSInteger index))compeletion;

- (void)getSourcePreviewImageAtIndex:(NSInteger)index
                       preferredSize:(CGSize)size
                         compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSInteger index))compeletion;

- (void)exportImagesWithProgress:(void(^_Nullable)(NSInteger finishedCount, NSInteger totalCount))progressBlock
                       onSucceed:(void(^_Nullable)(NSArray<ACCImageAlbumExportItemModel *> *_Nonnull exportedItems))succeedBlock
                         onFaild:(void(^_Nullable)(NSInteger faildIndex))faildBlock;

/// 开启导出图片持有复用一个editor(即后续所有任务复用同一个，任务结束后也不会释放)
- (void)beginImageAlbumPreviewTaskExportItemRetainAndReuse;

/// 关闭导出图片复用一个editor(任务结束会释放当前导出的editor)
- (void)endImageAlbumPreviewTaskExportItemRetainAndReuse;


@end

