//
//  ACCImageAlbumModernEditorSession.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/14.
//

#import "ACCImageAlbumModernEditorSession.h"

#import "ACCImageAlbumData.h"
#import "ACCImageAlbumItemModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCImageAlbumEditor.h"
#import "ACCImageAlbumAudioPlayer.h"
#import "ACCImageAlbumItemBaseResourceModel.h"
#import "ACCImageAlbumExportManager.h"
#import "ACCImageAlbumEditorGeometry.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import "ACCImageAlbumSessionPlayerViewModel.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

#define kStickerIdWithUniqueId(uniqueId) [self p_getVEStickerIdWithUniqueId:uniqueId]

@interface ACCImageAlbumModernEditorSession ()

#pragma mark - flags
@property (nonatomic, assign) BOOL didFirstRenderedCallbacked;

#pragma mark - audio
@property (nonatomic, strong) ACCImageAlbumAudioPlayer *audioPlayer;

#pragma mark - container
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSNumber *> *stickerUniqueIdStcikerIdMapping;

#pragma mark - export
@property (nonatomic, strong) ACCImageAlbumExportManager *exportManager;
@property (nonatomic, strong) ACCImageAlbumExportManager *captureManager;
@property (nonatomic, strong) ACCImageAlbumSessionPlayerViewModel *playerViewModel;

@end

@implementation ACCImageAlbumModernEditorSession
@synthesize albumData = _albumData;
@synthesize containerSize = _containerSize;
@synthesize onFirstImageEditorRendered;
@synthesize onCustomerContentViewRecovered;
@synthesize onCurrentImageEditorChanged;
@synthesize onPlayerDraggingStatusChangedHandler;
@synthesize willScrollToIndexHandler;
@synthesize onPreviewModeChanged;

#pragma mark - lifecycle
- (instancetype)initWithImageAlbumData:(ACCImageAlbumData *)albumData containerSize:(CGSize)containerSize
{
    if (self = [super init]) {
        
        _albumData = albumData;
        _containerSize = containerSize;
        if (!ACCImageEditSizeIsValid(containerSize)) {
            _containerSize = [UIScreen mainScreen].bounds.size;
            NSAssert(NO, @"invalid container size");
            [self p_logErrorWithLogMsg:@"init with invalid container size"];
        }
        // 必须确保初始化以接收业务侧接口传入的一些初始化数据
        [self p_setupPlayerDataSource];
    }
    return self;
}


/// ===============================================================================
///                                       Mix
/// ===============================================================================

#pragma mark - mix

- (void)resetWithContainerView:(UIView *)view
{
    if (!view) {
        NSAssert(NO, @"viewshould not be empty");
        [self p_logErrorWithLogMsg:@"reset with view is null"];
        return;
    }
    [self.playerViewModel resetWithContainerView:view];
}

- (void)p_setupPlayerDataSource
{
    if (!self.playerViewModel) {
        
        self.playerViewModel = [[ACCImageAlbumSessionPlayerViewModel alloc] initWithImageAlbumData:self.albumData containerSize:self.containerSize];
        
        @weakify(self);
        
        [self.playerViewModel setOnCustomerContentViewRecovered:^(UIView *contentView, ACCImageAlbumItemModel *imageItemModel, NSInteger index, CGSize imageLayerSize, CGSize originalImageLayerSize) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.onCustomerContentViewRecovered, contentView, imageItemModel, index, imageLayerSize, originalImageLayerSize);
        }];
        
        [self.playerViewModel setOnPreviewModeChanged:^(UIView *contentView, BOOL isPreviewMode) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.onPreviewModeChanged, contentView, isPreviewMode);
        }];
        
        [self.playerViewModel setOnCurrentImageEditorChanged:^(NSInteger currentIndex, BOOL isByAutoTimer) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.onCurrentImageEditorChanged, currentIndex, isByAutoTimer);
        }];
        
        [self.playerViewModel setOnStickerRecovered:^(NSInteger uniqueId, NSInteger stickerId) {
            @strongify(self);
            [self p_updateStickerIdMappingWithUniqueId:uniqueId stickerId:stickerId];
        }];
        
        [self.playerViewModel setOnAllRenderOperationsCompleteHandler:^{
            @strongify(self);
            if (!self.didFirstRenderedCallbacked) {
                [self p_logInfoWithLogMsg:@"firstRenderedCallbacked"];
                self.didFirstRenderedCallbacked = YES;
                ACCBLOCK_INVOKE(self.onFirstImageEditorRendered);
            }
        }];
        
        [self.playerViewModel setWillScrollToIndexHandler:^(NSInteger targetIndex, BOOL withAnimation, BOOL isByAutoTimer) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.willScrollToIndexHandler, targetIndex, withAnimation, isByAutoTimer);
        }];
        
        [self.playerViewModel setOnPlayerDraggingStatusChangedHandler:^(BOOL isDragging) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.onPlayerDraggingStatusChangedHandler, isDragging);
        }];
    }
}

- (UIView *)customerContentViewAtIndex:(NSInteger)imageIndex
{
    return [self.playerViewModel customerContentViewAtIndex:imageIndex];
}

- (ACCImageAlbumItemModel *)currentImageItemModel
{
    return [self imageItemAtIndex:self.currentIndex];
}

- (ACCImageAlbumItemModel *)imageItemAtIndex:(NSInteger)index
{
    if (index < 0) {
        NSParameterAssert(index >= 0);
        return nil;
    }
    return [self.albumData.imageAlbumItems acc_objectAtIndex:index];
}

- (CGSize)imageLayerSizeAtIndex:(NSInteger)imageIndex needClip:(BOOL)needClip
{
    ACCImageAlbumItemModel *imageItem = [self imageItemAtIndex:imageIndex];
    return [ACCImageAlbumEditor calculateImageLayerSizeWithContainerSize:self.containerSize
                                                               imageSize:CGSizeMake(imageItem.originalImageInfo.width,imageItem.originalImageInfo.height)
                                                                needClip:needClip];
}

- (CGSize)imageOriginalSizeAtIndex:(NSInteger)index
{
    ACCImageAlbumItemModel *imageItem = [self imageItemAtIndex:index];
    return CGSizeMake(imageItem.originalImageInfo.width, imageItem.originalImageInfo.height);
}

- (NSInteger)totalImageItemCount
{
    return self.albumData.imageAlbumItems.count;
}

- (void)beginCurrentImageEditorBatchUpdate
{
    [self.playerViewModel.currentIdleImageEditorIfExist beginCurrentImageEditorBatchUpdate];
}

- (void)endCurrentImageEditorBatchUpdate
{
    [self.playerViewModel.currentIdleImageEditorIfExist endCurrentImageEditorBatchUpdate];
}

- (void)updateAlbumData:(ACCImageAlbumData *)albumData {
    _albumData = albumData;
    [self.playerViewModel updateAlbumData:albumData];
}

/// ===============================================================================
///                                    Player
/// ===============================================================================

#pragma mark - Player

- (void)releasePlayer
{
    [self.playerViewModel releasePlayer];
}

- (void)reloadData
{
    [self.playerViewModel reloadData];
}

- (void)markCurrentImageNeedReload
{
    [self.playerViewModel markCurrentImageHasBeenModify];
}

- (void)scrollToIndex:(NSInteger)index
{
    [self.playerViewModel scrollToIndex:index];
}

- (NSInteger)currentIndex
{
    return self.playerViewModel.currentIndex;
}

- (void)setBottomOffset:(CGFloat)bottomOffset
{
    [self.playerViewModel setBottomOffset:bottomOffset];
}

- (void)setIsPreviewMode:(BOOL)isPreviewMode
{
    [self.playerViewModel setIsPreviewMode:isPreviewMode];
}

- (void)setScrollEnable:(BOOL)scrollEnable
{
    [self.playerViewModel setScrollEnable:scrollEnable];
}

- (void)setPreviewSize:(CGSize)previewSize
{
    [self.playerViewModel setPreviewSize:previewSize];
}

- (void)setPageControlStyle:(ACCImageAlbumEditorPageControlStyle)pageControlStyle
{
    [self.playerViewModel setPageControlStyle:pageControlStyle];
}

- (void)startAutoPlay
{
    [self.playerViewModel startAutoPlay];
}

- (void)stopAutoPlay
{
    [self.playerViewModel stopAutoPlay];
}

- (void)setAutoPlayInterval:(NSTimeInterval)autoPlayInterval
{
    [self.playerViewModel setAutoPlayInterval:autoPlayInterval];
}

- (void)updateInteractionContainerAlpha:(CGFloat)alpha
{
    [self.playerViewModel updateInteractionContainerAlpha:alpha];
}


/// ===============================================================================
///                                     Sticker
/// ===============================================================================

#pragma mark - sticker

- (NSInteger)addInfoStickerWithPath:(NSString *)path effectInfo:(NSArray *)effectInfo userInfo:(NSDictionary *)userInfo imageIndex:(NSInteger)imageIndex;
{
    if (ACC_isEmptyString(path)) {
        [self p_logErrorWithLogMsg:[NSString stringWithFormat:@"addInfoSticker error : no file path"]];
        return ACCImageEditInvaildStickerId;
    }
    
    [self.playerViewModel markCurrentImageHasBeenModify];
    
    // 例如从编辑页进入到发布页 走的是合成，这个时候很多editor并没有实例，所以 先简单的add进入就可以的
    // 复制一个fake stickerId避免被过滤掉，走恢复逻辑的时候回创建真正的stickerId，然后更新映射关系
    NSInteger stickerId = ACCImageEditFakeStickerId;
    
    ACCImageAlbumEditor *imageEditor = [self.playerViewModel idleImageEditorIfExistAtIndex:imageIndex];
    
    // 只是单纯计算size用的话随便取一个reload过的item加贴纸即可，随后会remove掉
    // 计算逻辑之后会让VE侧单独开个接口，所以这里先简单兼容下
    if (!imageEditor && [userInfo acc_boolValueForKey:@"is_fake_add_key"]) {
        imageEditor = [self.playerViewModel anyReloadedImageEditorIfExist];
    }
    
    ACCImageAlbumItemModel *imageItem = [self imageItemAtIndex:imageIndex];
    
    NSInteger orderIndex =  [imageItem.stickerInfo maxOrder] +1;
    
    // 如果editor不存在 说明不在缓存里，那先加入到data里下次会走恢复
    if (imageEditor)  {
        stickerId = [imageEditor addInfoStickerWithPath:path effectInfo:effectInfo orderIndex:orderIndex];
        [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s, addInfoSticker with editor, sticker id:%@", __func__,@(stickerId)]];
    }
    
    if (ACCIImageEditIsInvaildSticker(stickerId)) {
        NSAssert(NO, @"check");
        [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s, addInfoSticker faild because of editor return invaild sticker id, sticker id:%@", __func__,@(stickerId)]];
        return stickerId;
    }

    ACCImageAlbumStickerModel *sticker = [[ACCImageAlbumStickerModel alloc] initWithTaskId:self.albumData.taskId];
    [sticker setAbsoluteFilePath:path];
    sticker.uniqueId = [self.albumData maxStickerUniqueId] + 1;
    [self p_updateStickerIdMappingWithUniqueId:sticker.uniqueId stickerId:stickerId];
    sticker.param.order = orderIndex;
    sticker.userInfo = userInfo;
    sticker.effectInfo = effectInfo;
    
    // 如果没有editor，稍后会走恢复模式不用担心
    if (imageEditor) {
        [sticker.param updateBoundingBox:[imageEditor getInfoStickerBoundingBoxWithStickerId:stickerId]];
    }
    
    [imageItem.stickerInfo addStickerWithSticker:sticker];
    
    return sticker.uniqueId;
}

- (void)removeInfoStickerWithUniqueId:(NSInteger)uniqueId
{
    [self removeInfoStickerWithUniqueId:uniqueId traverseAllEditorIfNeed:NO];
}

- (void)removeInfoStickerWithUniqueId:(NSInteger)uniqueId
              traverseAllEditorIfNeed:(BOOL)traverseAllEditorIfNeed
{
    ACCImageAlbumStickerSearchResult *stickerResult = [self stickerWithUniqueId:uniqueId];
    
    if (!stickerResult.sticker) {
        return;
    }
    
    [self.playerViewModel markCurrentImageHasBeenModify];
    
    ACCImageAlbumItemModel *imageItem = [self imageItemAtIndex:stickerResult.imageIndex];
    ACCImageAlbumEditor *imageEditor = [self.playerViewModel idleImageEditorIfExistAtIndex:stickerResult.imageIndex];
    
    if (!imageEditor && traverseAllEditorIfNeed) {
        imageEditor = [self.playerViewModel anyReloadedImageEditorIfExist];
    }
    
    [imageEditor removeInfoStickerWithStickerId:kStickerIdWithUniqueId(uniqueId)];
    [imageItem.stickerInfo removeStickerWithUniqueId:uniqueId];
}

- (void)updateInfoStickerWithUniqueId:(NSInteger)uniqueId
                          updateTypes:(ACCImageAlbumEditorStickerUpdateType)updateTypes
                                props:(ACCImageAlbumStickerProps *)targetProps
{
    ACCImageAlbumStickerSearchResult *stickerResult = [self stickerWithUniqueId:uniqueId];
    
    if (!stickerResult.sticker) {
        NSParameterAssert(stickerResult.sticker != nil);
        [self p_logErrorWithLogMsg:[NSString stringWithFormat:@"updateInfoSticker error : no sticker found with uniqueId:%@", @(uniqueId)]];
        return;
    }
    
    [self.playerViewModel markCurrentImageHasBeenModify];
    
    ACCImageAlbumStickerProps *currentProps = stickerResult.sticker.param;
    ACCImageAlbumEditorStickerUpdateType realUpdateTypes = ACCImageAlbumEditorStickerUpdateTypeNone;

    ACCImageAlbumItemModel *imageItem = [self imageItemAtIndex:stickerResult.imageIndex];
    ACCImageAlbumEditor *imageEditor = [self.playerViewModel idleImageEditorIfExistAtIndex:stickerResult.imageIndex];
    
    if (updateTypes & ACCImageAlbumEditorStickerUpdateTypeRotation) {
        
        if (!ACC_FLOAT_EQUAL_TO(targetProps.angle, currentProps.angle)) {
            realUpdateTypes |= ACCImageAlbumEditorStickerUpdateTypeRotation;
            currentProps.angle = targetProps.angle;
        }
    }
    
    if (updateTypes & ACCImageAlbumEditorStickerUpdateTypeScale) {
        
        if (targetProps.scale != 1.0) {
            realUpdateTypes |= ACCImageAlbumEditorStickerUpdateTypeScale;
            currentProps.absoluteScale = currentProps.absoluteScale*targetProps.scale;
            currentProps.scale = targetProps.scale;
        }
    }
    
    if (updateTypes & ACCImageAlbumEditorStickerUpdateTypeAlpha) {
        
        if (!ACC_FLOAT_EQUAL_TO(targetProps.alpha, currentProps.alpha)) {
            realUpdateTypes |= ACCImageAlbumEditorStickerUpdateTypeAlpha;
            currentProps.alpha = targetProps.alpha;
        }
    }
    
    if (updateTypes & ACCImageAlbumEditorStickerUpdateTypeOffset) {
        
        if (!CGPointEqualToPoint(targetProps.offset, currentProps.offset)) {
            realUpdateTypes |= ACCImageAlbumEditorStickerUpdateTypeOffset;
            [currentProps updateOffset:targetProps.offset];
        }
    }
    
    if (updateTypes & ACCImageAlbumEditorStickerUpdateTypeAbove) {
        
        NSInteger maxOrder = [imageItem.stickerInfo maxOrder];
        BOOL isAlreadyAbove = (maxOrder >0 && currentProps.order >= maxOrder);
        if (!isAlreadyAbove) {
            realUpdateTypes |= ACCImageAlbumEditorStickerUpdateTypeAbove;
            currentProps.order = maxOrder + 1;
        }
    }
    
    // 调用editor要是用currentProps 因为像order之类的是更新在currentProps ，另外用realUpdateTypes达到去重效果
    [imageEditor updateInfoStickerWithStickerId:kStickerIdWithUniqueId(uniqueId) updateTypes:realUpdateTypes props:currentProps];
}

- (ACCImageAlbumStickerSearchResult *)stickerWithUniqueId:(NSInteger)uniqueId
{
    return [self.albumData stickerWithUniqueId:uniqueId preferredImageIndex:@(self.currentIndex)];
}

- (UIEdgeInsets)getInfoStickerBoundingBoxWithUniqueId:(NSInteger)uniqueId
{
    ACCImageAlbumStickerSearchResult *stickerResult = [self stickerWithUniqueId:uniqueId];
    return [stickerResult.sticker.param boundingBox];
}

- (void)p_updateStickerIdMappingWithUniqueId:(NSInteger)uniqueId stickerId:(NSInteger)stickerId
{
    self.stickerUniqueIdStcikerIdMapping[@(uniqueId)] = @(stickerId);
}

- (NSInteger)p_getVEStickerIdWithUniqueId:(NSInteger)uniqueId
{
    NSNumber *stickerIdWrap =  self.stickerUniqueIdStcikerIdMapping[@(uniqueId)];
    return stickerIdWrap == nil ? -1: stickerIdWrap.integerValue;
}

- (NSMutableDictionary<NSNumber *, NSNumber *> *)stickerUniqueIdStcikerIdMapping
{
    if (!_stickerUniqueIdStcikerIdMapping) {
        _stickerUniqueIdStcikerIdMapping = [NSMutableDictionary dictionary];
    }
    return _stickerUniqueIdStcikerIdMapping;
}


/// ===============================================================================
///                                     HDR
/// ===============================================================================

#pragma mark - HDR

- (void)setupLensHDRModelWithFilePath:(NSString *)filePath
{
    [self.albumData updateLensHDRModelWithFilePath:filePath];
    
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s, vaild:%@", __func__,@(ACC_isEmptyString(filePath))]];
}

- (void)setHDREnable:(BOOL)enable
{
    // HDR比较特殊 是作用到所有图片上，所以需要全部更新
    [[self.albumData.imageAlbumItems copy] enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.HDRInfo.enableHDRNet = enable;
    }];
    
    [[self.playerViewModel anyReloadedImageEditorIfExist] updateEditWithTypes:ACCImageAlbumEditorEffectUpdateTypeHDR];
    
    // 由于HDR是应用在所有图片上，所以需要刷新当前所有的已加载的图片
    [self.playerViewModel reloadAllPlayerItems];
}


/// ===============================================================================
///                                     Filter
/// ===============================================================================

#pragma mark - Filter

- (void)updateComposerFilterWithFilterId:(NSString *)filterId
                                filePath:(NSString *)filePath
                               intensity:(float)intensity
{
    [self.playerViewModel markCurrentImageHasBeenModify];
    
    BOOL hasFilter = (!ACC_isEmptyString(filterId) && !ACC_isEmptyString(filePath));
    
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s, hasFilter:%@", __func__,@(hasFilter)]];
    
    ACCImageAlbumItemModel *currentImageItemModel = [self currentImageItemModel];
    currentImageItemModel.filterInfo.effectIdentifier = hasFilter? filterId : nil;
    [currentImageItemModel.filterInfo setAbsoluteFilePath:hasFilter ? filePath : nil];
    currentImageItemModel.filterInfo.filterIntensityRatio = hasFilter? @(intensity) : nil;
    
    [self.playerViewModel.currentIdleImageEditorIfExist updateEditWithTypes:ACCImageAlbumEditorEffectUpdateTypeFilter];
}


/// ===============================================================================
///                                     Export
/// ===============================================================================

#pragma mark - Export

- (void)exportImagesWithProgress:(void (^)(NSInteger, NSInteger))progressBlock
                       onSucceed:(void (^)(NSArray<ACCImageAlbumExportItemModel *> * _Nonnull))succeedBlock
                         onFaild:(void (^)(NSInteger))faildBlock
{
    
    if (ACC_isEmptyArray(self.albumData.imageAlbumItems)) {
        ACCBLOCK_INVOKE(faildBlock, 0);
        [self p_logErrorWithLogMsg:@"exportImages error : no album data"];
        return;
    }
    
    [[ACCImageAlbumExportManager sharedManager] exportImagesWithImageItems:self.albumData.imageAlbumItems containerSize:self.containerSize progress:progressBlock onSucceed:succeedBlock onFaild:faildBlock];
}

- (UIImage *_Nullable)capturePreviewUIImage
{
    return [self.playerViewModel renderedImageAtIndex:self.currentIndex];
}

- (void)getProcessedPreviewImageAtIndex:(NSInteger)index
                         preferredSize:(CGSize)size
                            compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSInteger index))compeletion
{
    [self p_getPreviewImageAtIndex:index preferredSize:size usingOriginalImage:NO compeletion:compeletion];
}

- (void)getSourcePreviewImageAtIndex:(NSInteger)index
                       preferredSize:(CGSize)size
                         compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSInteger index))compeletion
{
    [self p_getPreviewImageAtIndex:index preferredSize:size usingOriginalImage:YES compeletion:compeletion];
}

- (void)p_getPreviewImageAtIndex:(NSInteger)index
                   preferredSize:(CGSize)size
              usingOriginalImage:(BOOL)usingOriginalImage
                     compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSInteger index))compeletion
{
    ACCImageAlbumItemModel *imageItem = [self imageItemAtIndex:index];
    if (!imageItem) {
        compeletion(nil, index);
        [self p_logErrorWithLogMsg:[NSString stringWithFormat:@"getPreviewImage error : no imageItem at index:%@", @(index)]];
        return;
    }
    
    @weakify(self);
    dispatch_block_t action = ^(void) {
        
        @strongify(self);
        // 如果导出编辑图则直接使用缓存
        if (!usingOriginalImage && CGSizeEqualToSize(CGSizeZero, size)) {
            UIImage *cachedImage = [self.playerViewModel renderedImageAtIndex:index];
            if (cachedImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    ACCBLOCK_INVOKE(compeletion, cachedImage, index);
                });
                return;
            }
        }
        [[ACCImageAlbumCaptureManager sharedManager] fetchPreviewImageAtIndex:index imageItem:imageItem containerSize:self.containerSize preferredSize:size usingOriginalImage:usingOriginalImage compeletion:compeletion];
    };
    
    /// 低端机避开首帧渲染
    if (self.playerViewModel.isLowLevelDeviceOpt && !self.didFirstRenderedCallbacked) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            ACCBLOCK_INVOKE(action);
        });
    } else {
        ACCBLOCK_INVOKE(action);
    }

}

- (void)beginImageAlbumPreviewTaskExportItemRetainAndReuse
{
    [[ACCImageAlbumCaptureManager sharedManager] beginImageAlbumPreviewTaskExportItemRetainAndReuse];
}

- (void)endImageAlbumPreviewTaskExportItemRetainAndReuse
{
    [[ACCImageAlbumCaptureManager sharedManager] endImageAlbumPreviewTaskExportItemRetainAndReuse];
}


/// ===============================================================================
///                                     Audio
/// ===============================================================================

#pragma mark - audio

- (void)replayMusic
{
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s", __func__]];
    [self setupAudioPlayerIfNeed];
    [self.audioPlayer replay];
}

- (void)continuePlayMusic
{
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s", __func__]];
    [self setupAudioPlayerIfNeed];
    [self.audioPlayer continuePlay];
}

- (void)pauseMusic
{
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s", __func__]];
    [self.audioPlayer pause];
}

- (void)replaceMusic:(id<ACCMusicModelProtocol>)music
{
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s", __func__]];
    [self setupAudioPlayerIfNeed];
    [self.audioPlayer replaceMusic:music];
}

- (void)setupAudioPlayerIfNeed
{
    if (!self.audioPlayer) {
        self.audioPlayer = [[ACCImageAlbumAudioPlayer alloc] init];
    }
}

#pragma mark - private

- (void)p_logInfoWithLogMsg:(NSString *)logMsg
{
    [self p_logInfoWithLogMsg:logMsg isError:NO];
}

- (void)p_logErrorWithLogMsg:(NSString *)logMsg
{
    [self p_logInfoWithLogMsg:logMsg isError:YES];
}

- (void)p_logInfoWithLogMsg:(NSString *)logMsg isError:(BOOL)isError
{
    NSString *log = [NSString stringWithFormat:@"\nImageAlbumSession : msg:%@, totalImage:%@, currentImage:%@\n", logMsg, @(self.totalImageItemCount), @(self.currentIndex)];
    
    if (isError) {
        AWELogToolError(AWELogToolTagEdit, log);
    } else {
        AWELogToolInfo(AWELogToolTagEdit, log);
    }
}

@end
