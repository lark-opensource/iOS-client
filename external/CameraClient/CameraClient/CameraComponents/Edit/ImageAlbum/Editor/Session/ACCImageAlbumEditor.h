//
//  ACCImageAlbumEditor.h
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/14.
//

#import <Foundation/Foundation.h>
#import "ACCImageAlbumEditorDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCImageAlbumItemModel, ACCImageAlbumStickerProps, ACCImageAlbumEditorRuntimeInfo;
@class ACCImageAlbumEditorExportInputData, ACCImageAlbumEditorExportOutputData;

@interface ACCImageAlbumEditor : NSObject

ACCImageEditModeObjUsingCustomerInitOnly;

- (instancetype)initWithContainerSize:(CGSize)containerSize;

/// reload all, incloud image data, image layer and all edits
/// @param index  used only for log or track
- (void)reloadWithImageItem:(ACCImageAlbumItemModel *)imageItemModel
                      index:(NSInteger)index;

- (void)reloadWithImageItem:(ACCImageAlbumItemModel *)imageItemModel
                      index:(NSInteger)index
                   complete:(void(^)(BOOL didAddImage))completeBlock;

@property (nonatomic, strong, readonly) ACCImageAlbumItemModel *_Nullable imageItemModel;

/// used only for log or track
@property (nonatomic, assign, readonly) NSInteger currentIndex;

/// force to reload
@property (nonatomic, assign) BOOL needForceReloadOnceFlag;

@property (nonatomic, assign, readonly) BOOL didAddImage;

- (void)reloadRuntimeInfo:(ACCImageAlbumEditorRuntimeInfo *)runtimeinfo;

/// render at  this view,  will reuse when reload image item
@property (nonatomic, strong, readonly) UIView *containerView;

/// update  edits
- (void)updateEditWithTypes:(ACCImageAlbumEditorEffectUpdateType)updateTypes;

/// add subviews at this view, !! will replace with a new  view instance after reload image item !!
/// so, if you want to reuse your  view, hold your own view instead of 'customerContentView'
@property (nonatomic, strong, readonly) UIView *_Nullable customerContentView;

/// on main thread, after reload task
@property (nonatomic, copy) ACCImageAlbumEditorContentViewRecoveredHandler onCustomerContentViewRecovered;
@property (nonatomic, copy) ACCImageAlbumEditorPreviewModeHandler onPreviewModeChanged;

@property (nonatomic, copy) void(^onStickerRecovered)(NSInteger uniqueId, NSInteger stickerId);

@property (nonatomic, copy) void(^onRenderedComplete)(void);

/// begin batch update transaction, will forbidden layer's render service
- (void)beginCurrentImageEditorBatchUpdate;

/// end batch update transaction, will auto render once if needed
- (void)endCurrentImageEditorBatchUpdate;

/// image size ----> real render size
+ (CGSize)calculateImageLayerSizeWithContainerSize:(CGSize)containerSize
                                         imageSize:(CGSize)imageSize
                                          needClip:(BOOL)needClip;

// 低端机有时候导出队列过慢又已经进行了的直接可以return
- (void)markAsReleased;

/// debug hook
- (void)onDidCreat;
- (void)onWillDestroy;

@end

/// 关于uniqueId和stickerId
/// session是和业务打交道的 所以中间包了层uniqueId,
/// editor是和VE打交道的 所以session调用editor的时候需要拿到真正的stickerId传入
@interface ACCImageAlbumEditor (Sticker)

- (NSInteger)addInfoStickerWithPath:(NSString *)path effectInfo:(NSArray *_Nullable)effectInfo orderIndex:(NSInteger)orderIndex;

- (void)removeInfoStickerWithStickerId:(NSInteger)stickerId;

- (void)updateInfoStickerWithStickerId:(NSInteger)stickerId
                           updateTypes:(ACCImageAlbumEditorStickerUpdateType)updateTypes
                                 props:(ACCImageAlbumStickerProps *_Nullable)props;

- (UIEdgeInsets)getInfoStickerBoundingBoxWithStickerId:(NSInteger)stickerId;

@end

@interface ACCImageAlbumEditor (Export)

/// @see ACCImageAlbumEditorExportInputData
- (void)runExportWithInputData:(ACCImageAlbumEditorExportInputData *)inputData
                      complete:(void (^)(ACCImageAlbumEditorExportOutputData *_Nullable outputData,
                                         ACCImageAlbumEditorExportResult exportResult))completeBlock;

@end

@interface ACCImageAlbumEditor (Capture)

/// return nil if no image layer added, so  try to get after first image render completion callbacked
/// may block current thread for a short time
- (UIImage *_Nullable)getRenderingImage;

/// get current original image;
- (UIImage *_Nullable)getOriginalImage;

- (UIImage *)getOriginalImageWithImageItemModel:(ACCImageAlbumItemModel *)itemModel;

@end

#pragma mark - models
@interface ACCImageAlbumEditorRuntimeInfo : NSObject

@property (nonatomic, assign) BOOL isPreviewMode;

@end


NS_ASSUME_NONNULL_END
