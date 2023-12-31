//
//  ACCImageAlbumEditor.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/14.
//

#import "ACCImageAlbumEditor.h"
#import <TTVideoEditor/VEImage.h>
#import "ACCImageAlbumItemModel.h"
#import "ACCImageAlbumEditorExportData.h"
#import <CreativeKit/ACCMacros.h>
#import <TTVideoEditor/TECommandID.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <AVFoundation/AVFoundation.h>
#import "ACCImageAlbumEditorGeometry.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import "ACCConfigKeyDefines.h"

@interface ACCImageAlbumEditor ()

/// --------- init value
@property (nonatomic, assign) CGSize containerSize;
@property (nonatomic, assign) CGPoint previewCenter;

/// --------- flag
@property (nonatomic, assign) BOOL isLoadingImageLayer;
@property (nonatomic, assign) NSInteger batchUpdateReferenceCount;
@property (nonatomic, assign, readwrite) BOOL didAddImage;
@property (nonatomic, assign) BOOL didInitHDREngine;
@property (nonatomic, assign) BOOL didRendered;
@property (nonatomic, copy) NSString *lastApplyedFilterPath;
@property (nonatomic, assign) CGSize imageLayerSize;
@property (nonatomic, assign) CGSize originalImageLayerSize;
@property (nonatomic, assign) CGSize targetRenderSize;
@property (nonatomic, assign) BOOL hasBeenReleased;

/// --------- context
@property (nonatomic, strong, readwrite) ACCImageAlbumItemModel *imageItemModel;
@property (nonatomic, strong) VEImage *imageEditor;

/// --------- other
@property (nonatomic, strong) dispatch_queue_t operationQueue;
@property (nonatomic, strong) ACCImageAlbumEditorRuntimeInfo *runtimeInfo;

@end

@implementation ACCImageAlbumEditor

- (instancetype)initWithContainerSize:(CGSize)containerSize
{
    if (self = [super init]) {
        _operationQueue = dispatch_queue_create("com.aweme.image.album.edior.update", DISPATCH_QUEUE_SERIAL);
        _containerSize = containerSize;
        [self p_setupBase];
        [self onDidCreat];
        AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumEditor lifecycle:%s", __func__);
    }
    return self;
}

- (void)dealloc
{
    [self onWillDestroy];
    AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumEditor lifecycle:%s", __func__);
}

- (void)markAsReleased
{
    self.hasBeenReleased = YES;
}

- (void)onWillDestroy{}
- (void)onDidCreat{}

#pragma mark - setup
- (void)p_setupBase
{
    if (![NSThread mainThread]) {
        NSAssert(NO, @"must be on main thread");
        AWELogToolError(AWELogToolTagEdit, @"ImageAlbumEditor : setup base view not on main thread");
    }

    _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.containerSize.width, self.containerSize.height)];
    self.containerView.clipsToBounds = YES;

    // VE提供的线程优化方案，解决线上偶现VE本身内存问题
    if (ACCConfigBool(kConfigBool_enable_image_album_ve_image_thread_opt)) {
        self.imageEditor = [[VEImage alloc] initWithNewLooper:YES];
    } else {
        self.imageEditor = [[VEImage alloc] init];
    }
    /// @seealso p_doEditorRenderIfEnable, 客户端统一自己调用effect，不采用内部自动调用
    /// 因为自动调用会有很多effect的重复调用，例如恢复多张贴纸，滤镜等 每个效果内部都会去调用effect相关
    /// 客户端在render之前统一调用一次就可以了
    [self.imageEditor enableRenderAutomation:NO];
    [self.containerView addSubview:self.imageEditor.preview];
    self.imageEditor.preview.frame = self.containerView.bounds;
    
    self.previewCenter = self.imageEditor.preview.center;
}

#pragma mark - reload task
- (void)reloadWithImageItem:(ACCImageAlbumItemModel *)imageItemModel
                      index:(NSInteger)index
{
    
    [self reloadWithImageItem:imageItemModel index:index isExportMode:NO complete:nil];
}

- (void)reloadWithImageItem:(ACCImageAlbumItemModel *)imageItemModel
                      index:(NSInteger)index
                   complete:(void(^)(BOOL didAddImage))completeBlock;
{
    [self reloadWithImageItem:imageItemModel index:index isExportMode:NO complete:completeBlock];
}

- (void)reloadWithImageItem:(ACCImageAlbumItemModel *)imageItemModel
                      index:(NSInteger)index
               isExportMode:(BOOL)isExportMode
                   complete:(void(^)(BOOL didAddImage))completeBlock
{
    
    void(^doLogInfo)(BOOL isError, NSString *info) = ^(BOOL isError, NSString *info) {
        
        NSString *logString = [NSString stringWithFormat:@"\nImageAlbumEditor : %@ at index:%@, isExport:%@\n", info,@(index),@(isExportMode)];
        
        if (isError) {
            AWELogToolError(AWELogToolTagEdit, logString);
        } else {
            AWELogToolInfo(AWELogToolTagEdit, logString);
        }
    };
    
    if (self.hasBeenReleased) {
        doLogInfo(NO, @"ignore reload because of has been released");
        return;
    }

    /// @warning 任何的return都必须callback，因为 有可能是导出的时候共用的editor，会阻塞operation queue
    if (imageItemModel == self.imageItemModel && !self.needForceReloadOnceFlag) {
        
        // 直接可以复用了
        if (self.didAddImage) {
            ACCBLOCK_INVOKE(doLogInfo, NO, @"reuse image layer when reload");
            ACCBLOCK_INVOKE(completeBlock, YES);
            return;
        }
        
        // 这里比较关键
        // 如果是导出模式 那么 必须往下走，因为上一次的流程还没走完，但是不能直接return!!BLOCK!!后续流程
        // 不会出现多线程问题，因为操作的queue都是串行的，等后续流程走完可以继续回调
        // 可以在优化一次 在队列开始任务的时候判断didAddImage直接回调，但个人感觉没必要 因为任务本身不是特别哈耗时，做优化反而容易引发问题
        // 如果不是导出模式那没必要往下走了，因为只是展示的话 没必要重新reload layer
        if (!isExportMode) {
            ACCBLOCK_INVOKE(doLogInfo, NO, @"begin same item reload");
            ACCBLOCK_INVOKE(completeBlock, YES);
            return;
        }
    }
    
    self.needForceReloadOnceFlag = NO;

    if (!imageItemModel) {
        ACCBLOCK_INVOKE(doLogInfo, YES, @"faild reload because of null image item");
        ACCBLOCK_INVOKE(completeBlock, NO);
        return;
    }

    self.imageItemModel = imageItemModel;
    _currentIndex = index;
    self.lastApplyedFilterPath = nil;

    self.isLoadingImageLayer = YES;
    self.didRendered = NO;
    self.batchUpdateReferenceCount = 0;
    
    @weakify(self);
    
    void (^doRecoverCustomerContentViewTask)(void) = ^(void) {
        
        @strongify(self);
        [self.customerContentView removeFromSuperview];
         UIView *customerContentView = [[UIView alloc] initWithFrame:self.containerView.bounds];
        [self p_replaceCustomerContentView:customerContentView];
        [self.containerView addSubview:customerContentView];
    };
    
    BOOL(^doAddImageLayerTask)(void) = ^(void) {
        
        @strongify(self);
        @autoreleasepool {
            
            UIImage *image = [self getOriginalImage];
            if (!self.hasBeenReleased) {
                NSParameterAssert(image != nil);
            }
            if (!image || (imageItemModel != self.imageItemModel)) {
                if (!image) {
                    ACCBLOCK_INVOKE(doLogInfo, YES, @"faild reload because of null original image");
                }
                if (imageItemModel != self.imageItemModel) {
                    ACCBLOCK_INVOKE(doLogInfo, NO, @"cancel reload because of image item changed");
                }
                return NO;
            }
            
            if (!ACCImageEditSizeIsValid(image.size)) {
                ACCBLOCK_INVOKE(doLogInfo, YES, @"image size is invaild");
            }
            
            ACCImageAlbumItemOriginalImageInfo *imageInfo = imageItemModel.originalImageInfo;
            
            if (!ACCImageEditSizeIsValid(CGSizeMake(imageInfo.width, imageInfo.height))) {
                // 理论上不会出现这种情况，预防一下可能iOS 安卓迁机带来的case
                NSAssert(NO, @"invalid parameter");
                ACCBLOCK_INVOKE(doLogInfo, YES, @"invalid image item size parameter");
                imageInfo.width = image.size.width;
                imageInfo.height = image.size.height;
                imageInfo.scale = image.scale;
            }
            
            self.targetRenderSize = ACCImageEditorMakeRectWithAspectRatio16To9(self.containerSize, image.size).size;
            
            self.imageLayerSize = [ACCImageAlbumEditor calculateImageLayerSizeWithContainerSize:self.targetRenderSize
                                                                                      imageSize:image.size
                                                                                       needClip:YES];
            
            self.originalImageLayerSize = [ACCImageAlbumEditor calculateImageLayerSizeWithContainerSize:self.targetRenderSize imageSize:image.size needClip:NO];
            
            if (!self.didAddImage) {
                // new image layer
                [self.imageEditor addImageLayerWithImage:image setupBlock:nil];
                ACCBLOCK_INVOKE(doLogInfo, NO, @"add Image layer with new image finished");
            } else {
                // VE已经把这个方法挪到内部自己去调用了，这里Mark一下 如果后续有复用效果重复的问题
                // 先试试加上这行看能不能work，仍然不能work可能是客户端自己逻辑问题，加上能work那就是VE内部没清理干净
                // [self.imageEditor clearEffect];
                
                // reuse image layer
                [self.imageEditor replaceImageLayerWithImage:image setupBlock:nil];
                ACCBLOCK_INVOKE(doLogInfo, NO, @"replace Image Layer finished");
            }
            self.didAddImage = YES;
            self.isLoadingImageLayer = NO;
            return YES;
        }
    };
    
    void(^doAdjustAspectFitWidthTask)(void) = ^(void) {
        
        @strongify(self);
        /// @warning : !!! not on main thread !!! do not use any UIKIT， e.g. view.frame
        VEImageLayerInfo frameInfo = [self.imageEditor queryCurrentLayerFrame];
        CGFloat layerWidth = ABS(frameInfo.ru.x - frameInfo.lu.x);
        
        CGFloat targetScale = 1.f;
        
        if (ACCImageEditWidthIsValid(layerWidth) && ACCImageEditWidthIsValid(self.targetRenderSize.width)) {
            targetScale = self.targetRenderSize.width / layerWidth;
        }

        ACCBLOCK_INVOKE(doLogInfo, NO, [NSString stringWithFormat:@"image layer scale with value:%@",@(targetScale)]);
        
        [self.imageEditor scaleWithScale:CGSizeMake(targetScale, targetScale) anchor:self.previewCenter];
    };
    
    void(^doRecoverEditEffectTask)(void) = ^(void) {
        @strongify(self);
        [self p_recoverAllEdits];
        [self p_recoverAllStickers];
    };
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    acc_dispatch_queue_async_safe(self.operationQueue, ^{
        
        @strongify(self);
        if (!self || self.hasBeenReleased) {
            ACCBLOCK_INVOKE(completeBlock, NO);
            return; // released
        }
        
        BOOL didAddImageLayer = doAddImageLayerTask();
        if (!self || !didAddImageLayer) {
            self.isLoadingImageLayer = NO;
            ACCBLOCK_INVOKE(completeBlock, NO);
            return;
        }
        
        doAdjustAspectFitWidthTask();
        
        [self beginCurrentImageEditorBatchUpdate];
    
        doRecoverEditEffectTask();

        [self endCurrentImageEditorBatchUpdate];
        
        ACCBLOCK_INVOKE(doLogInfo, NO, @"image editor reload succeed");
        
        // 导出模式下 回调下就可以了
        ACCBLOCK_INVOKE(completeBlock, YES);
        
        if (isExportMode) {
  
        } else {
            
            acc_dispatch_main_async_safe(^{
                
                @strongify(self);
                // VE重构后有自己的逻辑
                if (!ACCConfigBool(kConfigBool_enable_image_album_ve_editor_cache_opt)) {
                    doRecoverCustomerContentViewTask();
                    ACCBLOCK_INVOKE(self.onCustomerContentViewRecovered, self.customerContentView, self.imageItemModel, self.currentIndex, self.imageLayerSize, self.originalImageLayerSize);
                }
                [self p_updateRuntimeStatus];
                ACCBLOCK_INVOKE(self.onRenderedComplete);
            });
        }

    });
}

- (void)reloadRuntimeInfo:(ACCImageAlbumEditorRuntimeInfo *)runtimeinfo
{
    _runtimeInfo = runtimeinfo;
    [self p_updateRuntimeStatus];
}

- (void)updateEditWithTypes:(ACCImageAlbumEditorEffectUpdateType)updateTypes
{
    if (self.hasBeenReleased) {
        return;
    }
    
    if (self.isLoadingImageLayer || !self.didAddImage) {
        return;
    }
    
    BOOL hasUpdate = NO;
    
    if (updateTypes & ACCImageAlbumEditorEffectUpdateTypeHDR) {
        hasUpdate = YES;
        [self p_updateHDRInfo];
    }
    
    if (updateTypes & ACCImageAlbumEditorEffectUpdateTypeFilter) {
        hasUpdate = YES;
        [self p_updateFilter];
    }
    
    if (hasUpdate) {
        [self p_doEditorRenderIfEnable];
    }
}

- (void)beginCurrentImageEditorBatchUpdate
{
    @synchronized (self) {
        self.batchUpdateReferenceCount ++;
    }
    
    AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumEditor :%s,%@", __func__, @(self.batchUpdateReferenceCount));
}

- (void)endCurrentImageEditorBatchUpdate
{
    @synchronized (self) {
        self.batchUpdateReferenceCount --;
        [self p_doEditorRenderIfEnable];
    }
    
    AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumEditor :%s,%@", __func__,@(self.batchUpdateReferenceCount));
}

#pragma mark - update
- (void)p_updateRuntimeStatus
{
    self.containerView.userInteractionEnabled = !self.runtimeInfo.isPreviewMode;
    if (self.customerContentView) {
        ACCBLOCK_INVOKE(self.onPreviewModeChanged, self.customerContentView, self.runtimeInfo.isPreviewMode);
    }
}

- (void)p_recoverAllEdits
{
    if (self.hasBeenReleased) {
        return;
    }
    ACCImageAlbumEditorEffectUpdateType updateTypes = ACCImageAlbumEditorEffectUpdateTypeNone;
    
    if (self.imageItemModel.HDRInfo.enableHDRNet) {
        updateTypes |= ACCImageAlbumEditorEffectUpdateTypeHDR;
    }
    
    if ([self.imageItemModel.filterInfo isValidFilter]) {
        updateTypes |= ACCImageAlbumEditorEffectUpdateTypeFilter;
    }
    
    [self updateEditWithTypes:updateTypes];
}

- (void)p_recoverAllStickers
{
    NSArray<ACCImageAlbumStickerModel *> * stickers = [[self.imageItemModel.stickerInfo orderAscendingStickers] copy];
    __block NSInteger order = 0;
    [stickers enumerateObjectsUsingBlock:^(ACCImageAlbumStickerModel * _Nonnull sticker, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!ACC_isEmptyString([sticker getAbsoluteFilePath])) {
            [self p_recoverStickerWithSticker:sticker effectInfo:sticker.effectInfo order:(++order)];
        }
    }];
}

- (void)p_recoverStickerWithSticker:(ACCImageAlbumStickerModel *)sticker effectInfo:(NSArray *)effectInfo order:(NSInteger)order
{
    if (self.hasBeenReleased) {
        return;
    }
    NSInteger stickerId = [self addInfoStickerWithPath:[sticker getAbsoluteFilePath] effectInfo:effectInfo orderIndex:order];
    sticker.param.order = order;
    
    if (ACCIImageEditIsInvaildSticker(stickerId)) {
        return;
    }
    
    ACCBLOCK_INVOKE(self.onStickerRecovered, sticker.uniqueId, stickerId);
    
    ACCImageAlbumEditorStickerUpdateType updateTypes = ACCImageAlbumEditorStickerUpdateTypeNone;
    
    if (sticker.param.alpha != 1.f) {
        updateTypes |= ACCImageAlbumEditorStickerUpdateTypeAlpha;
    }
    
    if (sticker.param.absoluteScale != 1.f) {
        updateTypes |= ACCImageAlbumEditorStickerUpdateTypeScale;
        sticker.param.scale = sticker.param.absoluteScale;
    }
    
    if (sticker.param.angle != 0.f) {
        updateTypes |= ACCImageAlbumEditorStickerUpdateTypeRotation;
    }
    
    // 本身就是居中的话没必要在设置一次
    if (!CGPointEqualToPoint(sticker.param.offset, [ACCImageAlbumStickerProps centerOffset])) {
        updateTypes |= ACCImageAlbumEditorStickerUpdateTypeOffset;
    }
    
    [self updateInfoStickerWithStickerId:stickerId updateTypes:updateTypes props:sticker.param];
}

- (void)p_updateHDRInfo
{
    if (self.hasBeenReleased) {
        return;
    }
    if (!self.didInitHDREngine) {
        NSString *lensHDRFilePath = [self.imageItemModel.HDRInfo lensHDRModelFilePath];
        if (!ACC_isEmptyString(lensHDRFilePath)) {
            [self.imageEditor initLensHdrEngine:@[lensHDRFilePath] count:0 infoBuffer:@[]];
            self.didInitHDREngine = YES;
        }
    }
    
    if (!self.didInitHDREngine) {
        return;
    }

    [self.imageEditor enableLensHdr:self.imageItemModel.HDRInfo.enableHDRNet];
}

- (void)p_updateFilter
{
    if (self.hasBeenReleased) {
        return;
    }
    ACCImageAlbumItemFilterInfo *filterInfo =  self.imageItemModel.filterInfo;
    
    BOOL isValidFilter = self.imageItemModel.filterInfo.isValidFilter;
    
    NSString *filterFilePath = isValidFilter ? [filterInfo getAbsoluteFilePath] : @"";
    float filterIntensityRatio = isValidFilter ? filterInfo.filterIntensityRatio.floatValue : 0.f;
    
    BOOL hasApplyedFilter = !ACC_isEmptyString(self.lastApplyedFilterPath);
    
    BOOL isSameFilterAsApplyed = (hasApplyedFilter &&
                                  isValidFilter &&
                                  [self.lastApplyedFilterPath isEqualToString:filterFilePath]);
    
    /// 逻辑：更新走update接口，新增走set接口，替换或者删除先走remove在走set接口...
    
    if (hasApplyedFilter && !isSameFilterAsApplyed) {
        [self.imageEditor removeComposerWithoutUndoWithPath:self.lastApplyedFilterPath tagName:[NSString stringWithUTF8String:COMPOSER_SLIDE_FILTER]];
    }
    
    if (isValidFilter) {
        [self.imageEditor setComposerSlideFilter:filterFilePath pathTwo:@"" intensity:filterIntensityRatio progress:1.f];
    }

    self.lastApplyedFilterPath = filterFilePath;
}

- (void)p_replaceCustomerContentView:(UIView *)customerContentView
{
    _customerContentView = customerContentView;
}

#pragma mark - render
- (void)p_doEditorRenderIfEnable
{
    if (self.hasBeenReleased) {
        return;
    }
    BOOL isBatchUpdating = (self.batchUpdateReferenceCount > 0 );
    if (self.isLoadingImageLayer || isBatchUpdating || !self.didAddImage) {
        
        AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumEditor : disable render with info: loadingLayer:%@, batchUpdateReferenceCount:%@, didAddImage:%@, at index:%@", @(self.isLoadingImageLayer),@(self.batchUpdateReferenceCount),@(self.didAddImage),@(self.currentIndex));
        return;
    }
    AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumEditor : begin render at index:%@",@(self.currentIndex));
    
    // 我们取消了VEImage的enableRenderAutomation，所以需要在render layer之前调用effect
    [self.imageEditor renderEffect];
    [self.imageEditor renderLayerQueue];
    self.didRendered = YES;
}

#pragma mark - utility
+ (CGSize)calculateImageLayerSizeWithContainerSize:(CGSize)containerSize
                                         imageSize:(CGSize)imageSize
                                          needClip:(BOOL)needClip
{
    if (ACCImageEditRatioIs16To9(imageSize)) {
        return ACCImageEditGetHeightFitImageDisplaySize(imageSize, containerSize, needClip);
    }

    return ACCImageEditGetWidthFitImageDisplaySize(imageSize, containerSize, needClip);
}

@end


@implementation  ACCImageAlbumEditor (Sticker)

- (NSInteger)addInfoStickerWithPath:(NSString *)path effectInfo:(NSArray *)effectInfo orderIndex:(NSInteger)orderIndex
{
    if (!self.didAddImage) {
        NSAssert(NO, @"no image layer added, check");
        AWELogToolError(AWELogToolTagEdit, @"ImageAlbumEditor : no image layer added when add sticker");
        return ACCImageEditInvaildStickerId;
    }
    
    if (ACC_isEmptyString(path)) {
        NSAssert(NO, @"path == nil");
        AWELogToolError(AWELogToolTagEdit, @"ImageAlbumEditor : no sticker path when add sticker");
        return ACCImageEditInvaildStickerId;
    }
    
    NSInteger stickerId =  [self.imageEditor addStickerWithPath:path param:effectInfo?:@[]];
    [self.imageEditor stickerSetOrderInLayer:(int)stickerId order:(int)orderIndex];
    
    [self p_doEditorRenderIfEnable];
    return stickerId;
}

- (void)removeInfoStickerWithStickerId:(NSInteger)stickerId
{
    if (!self.didAddImage) {
        NSAssert(NO, @"no image layer added, check");
        return;
    }
    [self.imageEditor removeStickerWithIndex:stickerId];
    [self p_doEditorRenderIfEnable];
}

- (UIEdgeInsets)getInfoStickerBoundingBoxWithStickerId:(NSInteger)stickerId
{
    TEInfoStickerBoundingBox veBox = [self.imageEditor getStickerBoundingBoxWitnIndex:(int)stickerId needScale:NO];
    return UIEdgeInsetsMake(veBox.top, veBox.left, veBox.bottom, veBox.right);
}

- (void)updateInfoStickerWithStickerId:(NSInteger)stickerId
                          updateTypes:(ACCImageAlbumEditorStickerUpdateType)updateTypes
                                props:(ACCImageAlbumStickerProps *)props
{
    
    if (!props) {
        NSParameterAssert(props != nil);
        AWELogToolError(AWELogToolTagEdit, @"ImageAlbumEditor : no props when update sticker");
        return;
    }

    BOOL hasUpdate = NO;
    
    if (updateTypes & ACCImageAlbumEditorStickerUpdateTypeRotation) {
        [self.imageEditor stickerSetRotationWithIndex:(int)stickerId rotation:props.angle];
        hasUpdate = YES;
    }
    
    if (updateTypes & ACCImageAlbumEditorStickerUpdateTypeScale) {
        [self.imageEditor stickerSetScaleWithIndex:(int)stickerId scale:CGSizeMake(props.scale, props.scale)];
        hasUpdate = YES;
    }
    
    if (updateTypes & ACCImageAlbumEditorStickerUpdateTypeAlpha) {
        [self.imageEditor stickerSetAlphaWithIndex:(int)stickerId alpha:props.alpha];
        hasUpdate = YES;
    }
    
    if (updateTypes & ACCImageAlbumEditorStickerUpdateTypeOffset) {
        [self.imageEditor stickerSetPositonWithIndex:(int)stickerId point:props.offset];
        hasUpdate = YES;
    }
    
    if (updateTypes & ACCImageAlbumEditorStickerUpdateTypeAbove) {
        [self.imageEditor stickerSetOrderInLayer:(int)stickerId order:(int)props.order];
        hasUpdate = YES;
    }
    
    if (hasUpdate) {
        [self p_doEditorRenderIfEnable];
    }
    
    [props updateBoundingBox:[self getInfoStickerBoundingBoxWithStickerId:stickerId]];
}

@end


@implementation ACCImageAlbumEditor (Export)

- (void)runExportWithInputData:(ACCImageAlbumEditorExportInputData *)inputData
                      complete:(nonnull void (^)(ACCImageAlbumEditorExportOutputData * _Nullable,
                                                 ACCImageAlbumEditorExportResult))completeBlock
{
    
    ACCImageAlbumEditorExportResult exportResultType = ACCImageAlbumEditorExportResultSucceed;
    
    if (ACC_isEmptyString([inputData.imageItem.originalImageInfo getAbsoluteFilePath])) {
        NSAssert(NO, @"no image file, check");
        exportResultType = ACCImageAlbumEditorExportResultInvaildOriginalImage;
        AWELogToolError(AWELogToolTagEdit, @"ImageAlbumEditor : no image file when export");
    } else if ((inputData.exportTypes & ACCImageAlbumEditorExportTypeFilePath) && ACC_isEmptyString(inputData.savePath)) {
        NSAssert(NO, @"no save path, check");
        AWELogToolError(AWELogToolTagEdit, @"ImageAlbumEditor : no save file path when export");
        exportResultType = ACCImageAlbumEditorExportResultWriteToFileError;
    }
    
    if (exportResultType != ACCImageAlbumEditorExportResultSucceed) {
        ACCBLOCK_INVOKE(completeBlock, nil, exportResultType);
        return;
    }
    
    @weakify(self);
    
    if (inputData.usingOriginalImage) {
        AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumEditor : begin original image export");
        [self p_doExportWithInputData:inputData complete:completeBlock];
    } else {
        [self reloadWithImageItem:inputData.imageItem index:inputData.index isExportMode:YES complete:^(BOOL didAddImage){
            @strongify(self);
            if (!didAddImage) {
                acc_dispatch_main_async_safe(^{
                    AWELogToolError(AWELogToolTagEdit, @"ImageAlbumEditor : faild image export because of add image layer error");
                    ACCBLOCK_INVOKE(completeBlock, nil, ACCImageAlbumEditorExportResultRenderError);
                });
                return;
            }
            AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumEditor : begin eidt image export");
            [self p_doExportWithInputData:inputData complete:completeBlock];
        }];
    }
}

- (void)p_doExportWithInputData:(ACCImageAlbumEditorExportInputData *)inputData
                       complete:(nonnull void (^)(ACCImageAlbumEditorExportOutputData * _Nullable,
                                                  ACCImageAlbumEditorExportResult))completeBlock
{

    void(^callbackFaildOnMainThread)(ACCImageAlbumEditorExportResult) = ^(ACCImageAlbumEditorExportResult exportResult) {
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(completeBlock, nil, exportResult);
        });
    };
    
    acc_dispatch_queue_async_safe(self.operationQueue, ^{
        
        @autoreleasepool {
            
            UIImage *image = nil;

            if (inputData.usingOriginalImage) {
                image = [self getOriginalImageWithImageItemModel:inputData.imageItem];
            } else {
                if (!self.didRendered) {
                    [self.imageEditor renderEffect];
                    [self.imageEditor renderLayerQueue];
                }
                image = [self getRenderingImage];
            }
            
            if (!image) {
                AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumEditor : faild image export because of get image faild");
                callbackFaildOnMainThread(inputData.usingOriginalImage ? ACCImageAlbumEditorExportResultInvaildOriginalImage : ACCImageAlbumEditorExportResultRenderError);
                return;
            }
            
            if (ACCImageEditSizeIsValid(inputData.targetSize)) {
                image = [self p_scaleAspectFillmageWithImage:image size:inputData.targetSize];
            }
            
            ACCImageAlbumEditorExportOutputData *outputData = [[ACCImageAlbumEditorExportOutputData alloc] init];
            outputData.index = inputData.index;
            outputData.imageSize = image.size;
            outputData.imageScale = image.scale;
            
            if (inputData.exportTypes & AACCImageAlbumEditorExportTypeImage) {
                outputData.image = image;
            }
            
            if (inputData.exportTypes & ACCImageAlbumEditorExportTypeFilePath) {
                
                NSData *imageData = UIImageJPEGRepresentation(image, 1.f);

                if (!imageData) {
                    AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumEditor : faild image export because of get image data faild");
                    callbackFaildOnMainThread(ACCImageAlbumEditorExportResultInvaildImageData);
                    return;
                }
                
                NSError *writeError = nil;
                BOOL imageDataWriteSuccess = [imageData acc_writeToFile:inputData.savePath options:NSDataWritingAtomic error:&writeError];
                
                if (!imageDataWriteSuccess || writeError) {
                    AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumEditor : faild image export because of save image data to file faild");
                    ACCBLOCK_INVOKE(callbackFaildOnMainThread, ACCImageAlbumEditorExportResultWriteToFileError);
                    return;
                }
                
                outputData.filePath = inputData.savePath;
            }

            acc_dispatch_main_async_safe(^{
                ACCBLOCK_INVOKE(completeBlock, outputData, ACCImageAlbumEditorExportResultSucceed);
            });
        }
    });
}

/// 获取 将图片等比缩放至刚好填充满targetSize以后的图片，裁剪多余的宽或者高的部分
- (UIImage *)p_scaleAspectFillmageWithImage:(UIImage *)image size:(CGSize)targetSize
{
    CGSize imageSize = image.size;
    
    if (!image || !ACCImageEditSizeIsValid(targetSize) || !ACCImageEditSizeIsValid(imageSize)) {
        return image;
    }
    
    UIImage* scaledImage;
    
    @autoreleasepool {
        
        UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0);
        
        CGRect drawRect = ACCImageEditorMakeRectWithAspectRatioOutsideRect(imageSize, CGRectMake(0, 0, targetSize.width, targetSize.height));
        [image drawInRect:drawRect];
        scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return scaledImage;
}

@end


@implementation ACCImageAlbumEditor (Capture)

/// 导出复用的同一个接口，如果需要处理返回的图片请注意
- (UIImage *)getRenderingImage
{
    if (!self.didAddImage) {
        return nil;
    }
    return [self.imageEditor getCurrentImage:NO isPanoramic:NO];
}

- (UIImage *)getOriginalImage
{
    return [self getOriginalImageWithImageItemModel:self.imageItemModel];
}

- (UIImage *)getOriginalImageWithImageItemModel:(ACCImageAlbumItemModel *)itemModel
{
    if (ACC_isEmptyString([itemModel.originalImageInfo getAbsoluteFilePath])) {
        return nil;
    }
    
    return [UIImage imageWithContentsOfFile:[itemModel.originalImageInfo getAbsoluteFilePath]];
}

@end


@implementation ACCImageAlbumEditorRuntimeInfo

@end


