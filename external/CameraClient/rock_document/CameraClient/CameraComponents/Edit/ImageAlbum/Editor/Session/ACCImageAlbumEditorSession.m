//
//  ACCImageAlbumEditorSession.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/14.
//

#import "ACCImageAlbumEditorSession.h"

#import "ACCImageAlbumEditPlayerView.h"
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

#define kStickerIdWithUniqueId(uniqueId) [self p_getVEStickerIdWithUniqueId:uniqueId]

@interface ACCImageAlbumEditorSession ()
<
ACCImageAlbumEditPlayerViewDelegate,
ACCImageAlbumEditPlayerViewDataSource
>

#pragma mark - flags
@property (nonatomic, assign, readonly) NSInteger imageItemCount;
@property (nonatomic, assign) BOOL didFirstRenderedCallbacked;
@property (nonatomic, assign) BOOL isPreviewMode;
@property (nonatomic, assign) CGSize previewSize;
@property (nonatomic, assign) CGFloat bottomOffset;
@property (nonatomic, assign) ACCImageAlbumEditorPageControlStyle pageControlStyle;

@property (nonatomic, copy) NSArray <NSNumber *> *preloadIndexs;

#pragma mark - player
@property (nonatomic, strong) ACCImageAlbumEditPlayerView *playerView;
@property (nonatomic, strong) ACCImageAlbumAudioPlayer *audioPlayer;
@property (nonatomic, assign) NSTimeInterval autoPlayInterval; /// default is 2s

#pragma mark - container
///
@property (nonatomic, strong) NSMutableSet <ACCImageAlbumEditor *> *imageEditorsReusePool;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSNumber *> *stickerUniqueIdStcikerIdMapping;

@end

@implementation ACCImageAlbumEditorSession
@synthesize currentIndex  = _currentIndex;
@synthesize albumData     = _albumData;
@synthesize containerSize = _containerSize;
@synthesize onFirstImageEditorRendered;
@synthesize onCustomerContentViewRecovered;
@synthesize onCurrentImageEditorChanged;
@synthesize onPlayerDraggingStatusChangedHandler;
@synthesize willScrollToIndexHandler;
@synthesize onPreviewModeChanged;

- (instancetype)initWithImageAlbumData:(ACCImageAlbumData *)albumData containerSize:(CGSize)containerSize
{
    if (self = [super init]) {
        
        _albumData = albumData;
        _containerSize = containerSize;
        _imageItemCount = albumData.imageAlbumItems.count;
        if (!ACCImageEditSizeIsValid(containerSize)) {
            NSAssert(NO, @"invalid container size");
            _containerSize = [UIScreen mainScreen].bounds.size;
            [self p_logErrorWithLogMsg:@"init with invalid container size"];
        }
    }
    return self;
}

#pragma mark - public
- (void)resetWithContainerView:(UIView *)view
{
    if (!view) {
        NSAssert(NO, @"viewshould not be empty");
        [self p_logErrorWithLogMsg:@"reset with view is null"];
        return;
    }
    
    if (view == self.playerView.superview) {
        return; // no need reload
    }
    
    [self p_logInfoWithLogMsg:@"reset container view succeed"];

    /// @see p_getActiveEditorRange: 如果currentIndex进来的时候需要不是从0开始 同步修改下ActiveEditorRange的逻辑
    _currentIndex = 0;
    self.didFirstRenderedCallbacked = NO;
    
    [self p_resetImageEditorReuseQueue];
    
    [self resetPlayerViewWithContainer:view];
    self.playerView.bottomOffset = self.bottomOffset;
    self.playerView.pageControlStyle = self.pageControlStyle;
    self.playerView.autoPlayInterval = self.autoPlayInterval;
    [self.playerView reloadData];
    
    ACCBLOCK_INVOKE(self.onCurrentImageEditorChanged, self.currentIndex, NO);
}

- (void)setBottomOffset:(CGFloat)bottomOffset
{
    _bottomOffset = bottomOffset;
    self.playerView.bottomOffset = bottomOffset;
}

- (void)setPageControlStyle:(ACCImageAlbumEditorPageControlStyle)pageControlStyle
{
    _pageControlStyle = pageControlStyle;
    self.playerView.pageControlStyle = pageControlStyle;
}

- (void)updateInteractionContainerAlpha:(CGFloat)alpha
{
    [self.playerView updateInteractionContainerAlpha:alpha];
}

- (void)updateAlbumData:(ACCImageAlbumData *)albumData {
    _albumData = albumData;
    _imageItemCount = albumData.imageAlbumItems.count;
}

#pragma mark - setup
- (void)resetPlayerViewWithContainer:(UIView *)container
{
    if (self.playerView) {
        [self.playerView stopAutoPlay];
        [self.playerView removeFromSuperview];
        self.playerView = nil;
    }
    self.playerView = [[ACCImageAlbumEditPlayerView alloc] initWithFrame:container.bounds];
    self.playerView.delegate = self;
    self.playerView.dataSource = self;
    self.playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [container addSubview:self.playerView];
}

- (void)releasePlayer
{
    [self.imageEditorsReusePool removeAllObjects];
    if (self.playerView) {
        [self.playerView stopAutoPlay];
        [self.playerView removeFromSuperview];
        self.playerView = nil;
    }
}

#pragma mark - ACCImageAlbumEditPlayerViewDelegate
- (void)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView didUpdateCurrentIndex:(NSInteger)currentIndex isByAutoTimer:(BOOL)isByAutoTimer
{
    if (currentIndex == self.currentIndex) {
        return;
    }
    _currentIndex = currentIndex;
    [self p_reloadReuseableImageEditorWithIndex:currentIndex];
    ACCBLOCK_INVOKE(self.onCurrentImageEditorChanged, currentIndex, isByAutoTimer);
}

- (void)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView didUpdatePreloadIndexs:(NSArray<NSNumber *> *)preloadIndexs
{
    self.preloadIndexs = preloadIndexs;
    [preloadIndexs enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self p_reloadReuseableImageEditorWithIndex:obj.integerValue];
    }];
}

- (void)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerViewt willScrollToIndex:(NSInteger)targetIndex withAnimation:(BOOL)withAnimation isByAutoTimer:(BOOL)isByAutoTimer
{
    ACCBLOCK_INVOKE(self.willScrollToIndexHandler, targetIndex, withAnimation, isByAutoTimer);
}

- (void)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView didUpdateDraggingStatus:(BOOL)isDrag
{
    ACCBLOCK_INVOKE(self.onPlayerDraggingStatusChangedHandler, isDrag);
}

- (void)albumEditPlayerViewDidEndAnimationAndDragging:(ACCImageAlbumEditPlayerView *)playerView
{
    
}

#pragma mark - ACCImageAlbumEditPlayerViewDatasource
- (UIView *)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView previewViewAtIndex:(NSInteger)index
{
    ACCImageAlbumEditor *editor = [self p_getActiveImageEditorIfExistAtIndex:index];
    // must be  preload, bad case if nil
    NSParameterAssert(editor != nil);
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s, %@",__func__, @(index)]];
    if (!editor) {
        [self p_logErrorWithLogMsg:[NSString stringWithFormat:@"%s faild because of no editor %@", __func__, @(index)]];
    }
    return editor.containerView ?: [UIView new];
}

- (NSInteger)numberOfPreviewForAlbumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView
{
    return self.imageItemCount;
}

- (BOOL)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView hasPreloadedItemWithIndex:(NSInteger)index
{
    return [self p_getActiveImageEditorIfExistAtIndex:index] != nil;
}

#pragma mark - image editor control
- (void)p_resetImageEditorReuseQueue
{
    [self.imageEditorsReusePool removeAllObjects];
    NSInteger start = 0;
    NSInteger realCacheCount = MIN(3, self.imageItemCount);
    NSRange activeEditorRange =  NSMakeRange(start, realCacheCount);
    
    NSMutableArray <NSNumber *> *preloadIndexs = [NSMutableArray array];
    
    for (NSInteger i = activeEditorRange.location; i < activeEditorRange.length; i++) {
        if (i!=start) {
            [preloadIndexs addObject:@(i)];
        }
        [self p_creatReloadedImageEditorToReusePoolWithIndex:i];
    }
    
    self.preloadIndexs = [preloadIndexs copy];
    
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"resetImageEditorReuseQueue current cache count %@, active range location:%@: length:%@", @(self.imageEditorsReusePool.count), @(activeEditorRange.location),@(activeEditorRange.length)]];
}

- (ACCImageAlbumEditor *)p_reloadReuseableImageEditorWithIndex:(NSInteger)index
{
    if (index < 0 || index >= self.imageItemCount) {
        NSAssert(NO, @"index out of bounce");
        return nil;
    }
    
    __block ACCImageAlbumEditor *editor =  [self p_getActiveImageEditorIfExistAtIndex:index];
    
    if (editor) {
        [self p_logInfoWithLogMsg:[NSString stringWithFormat:@">>>>>>> reloadedReuseableImageEditor : reused at index %@", @(index)]];
        
        // 图片裁切后需要刷新，否则本来就是对应index的说明之前reload过，没必要再reload一次;
        ACCImageAlbumItemModel *itemModel = [self imageItemAtIndex:index];
        if (editor.needForceReloadOnceFlag) {
            [editor reloadWithImageItem:itemModel index:index];
        }
        
        return editor;
    }
    
    /// 这里是allObjects， 不是copy ， set和array的enumerate block不一样要注意下
    [[self.imageEditorsReusePool allObjects] enumerateObjectsUsingBlock:^(ACCImageAlbumEditor *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        BOOL isCurrentIndexEditor = [self p_isImageEditor:obj canReuseImageItemForIndex:self.currentIndex];
        BOOL isPreloadIndexEditor = [self p_isImageEditor:obj canReuseAnyImageItemForIndexs:self.preloadIndexs];

        if (!isCurrentIndexEditor && !isPreloadIndexEditor) {
            editor = obj;
            *stop = YES;
        }
    }];
    
    if (!editor) {
        
        NSAssert(NO, @"reuse life cycle has fatal error, check");
        [self p_logErrorWithLogMsg:[NSString stringWithFormat:@">>>>>>> reloadedReuseableImageEditor : faild at index %@", @(index)]];
        // 兜底逻辑 没有可用的 则取不是当前的
        [[self.imageEditorsReusePool allObjects] enumerateObjectsUsingBlock:^(ACCImageAlbumEditor *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            BOOL isCurrentIndexEditor = [self p_isImageEditor:obj canReuseImageItemForIndex:self.currentIndex];;
            if (!isCurrentIndexEditor ) {
                editor = obj;
                *stop = YES;
            }
        }];
    }
    
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@">>>>>>> reloadedReuseableImageEditor : reloaded at index:%@, old index:%@", @(index), @(editor.currentIndex)]];
    ACCImageAlbumItemModel *itemModel = [self imageItemAtIndex:index];
    [editor reloadWithImageItem:itemModel index:index];
    return editor;
}

- (ACCImageAlbumEditor *)p_creatReloadedImageEditorToReusePoolWithIndex:(NSInteger)index
{
    CGSize containerSize = self.containerSize;
    if (self.isPreviewMode && ACCImageEditSizeIsValid(self.previewSize)) {
        containerSize = self.previewSize;
    }
    
    ACCImageAlbumEditor *editor = [[ACCImageAlbumEditor alloc] initWithContainerSize:containerSize];
    [self.imageEditorsReusePool addObject:editor];
    
    [editor setOnPreviewModeChanged:self.onPreviewModeChanged];
    [editor reloadRuntimeInfo:[self p_commonEditorRuntimeInfo]];
    [editor setOnCustomerContentViewRecovered:self.onCustomerContentViewRecovered];
    
    @weakify(self);
    [editor setOnStickerRecovered:^(NSInteger uniqueId, NSInteger stickerId) {
        @strongify(self);
        [self p_updateStickerIdMappingWithUniqueId:uniqueId stickerId:stickerId];
    }];
    [editor setOnRenderedComplete:^{
        @strongify(self);
        if (!self.didFirstRenderedCallbacked) {
            [self p_logInfoWithLogMsg:@"firstRenderedCallbacked"];
            self.didFirstRenderedCallbacked = YES;
            ACCBLOCK_INVOKE(self.onFirstImageEditorRendered);
        }
    }];
    
    ACCImageAlbumItemModel *itemModel = [self imageItemAtIndex:index];
    [editor reloadWithImageItem:itemModel index:index];
    
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"creatReloadedImageEditorToReusePool : succeed at index:%@", @(index)]];
    
    return editor;
}

- (ACCImageAlbumEditor *)p_getActiveImageEditorIfExistAtIndex:(NSInteger)index
{
    __block ACCImageAlbumEditor *editor = nil;
    
    [[self.imageEditorsReusePool allObjects] enumerateObjectsUsingBlock:^(ACCImageAlbumEditor *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self p_isImageEditor:obj canReuseImageItemForIndex:index]) {
            editor = obj;
            *stop = YES;
        }
    }];
    return editor;
}

- (NSArray <ACCImageAlbumEditor *> *)p_allImageEditorsCache
{
    return [self.imageEditorsReusePool copy];
}

- (ACCImageAlbumEditorRuntimeInfo *)p_commonEditorRuntimeInfo
{
    ACCImageAlbumEditorRuntimeInfo *runtimeInfo = [[ACCImageAlbumEditorRuntimeInfo alloc] init];
    runtimeInfo.isPreviewMode = self.isPreviewMode;
    return runtimeInfo;
}

- (ACCImageAlbumEditor *)p_currentActiveImageEditor
{
    return [self p_getActiveImageEditorIfExistAtIndex:self.currentIndex];
}

// 根据imageitem的itemID去匹配，而非用index去匹配，因为后续有需求可能会调整图集数据的顺序
- (BOOL)p_isImageEditor:(ACCImageAlbumEditor *)editor canReuseImageItemForIndex:(NSInteger)index
{
    ACCImageAlbumItemModel *itemModel = [self imageItemAtIndex:index];
    if (ACC_isEmptyString(editor.imageItemModel.itemIdentify)||
        ACC_isEmptyString(itemModel.itemIdentify)) {
        [self p_logErrorWithLogMsg:[NSString stringWithFormat:@"canReuseImageItemForIndex:%@, invaild", @(index)]];
        return NO;
    }
    
    return [itemModel.itemIdentify isEqualToString:editor.imageItemModel.itemIdentify];
}

- (BOOL)p_isImageEditor:(ACCImageAlbumEditor *)editor canReuseAnyImageItemForIndexs:(NSArray <NSNumber *>*)indexs
{
    __block BOOL ret = NO;
    [[indexs copy] enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([self p_isImageEditor:editor canReuseImageItemForIndex:obj.integerValue]) {
            ret = YES;
            *stop = YES;
        }
    }];
    return ret;
}

#pragma mark - private
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

- (NSMutableSet<ACCImageAlbumEditor *> *)imageEditorsReusePool
{
    if (!_imageEditorsReusePool) {
        _imageEditorsReusePool = [NSMutableSet set];
    }
    return _imageEditorsReusePool;
}

#pragma mark - log
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


#pragma mark - Getter

- (UIView *)customerContentViewAtIndex:(NSInteger)imageIndex
{
    ACCImageAlbumEditor *imagerEditor =  [self p_getActiveImageEditorIfExistAtIndex:imageIndex];
    NSParameterAssert(imagerEditor != nil);
    if (!imagerEditor) {
        [self p_logErrorWithLogMsg:[NSString stringWithFormat:@"get imageEditorContentViewAtIndex faild because of no active image editor at index:%@", @(imageIndex)]];
    }
    return imagerEditor.customerContentView;
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

#pragma mark - PlayerControl

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

- (void)setScrollEnable:(BOOL)scrollEnable
{
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s,%@", __func__,@(scrollEnable)]];
    self.playerView.scrollEnable = scrollEnable;
}

- (void)setIsPreviewMode:(BOOL)isPreviewMode
{
    if (isPreviewMode == _isPreviewMode) {
        return;
    }
    
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s,%@", __func__,@(isPreviewMode)]];
    
    _isPreviewMode = isPreviewMode;
    [[self p_allImageEditorsCache] enumerateObjectsUsingBlock:^(ACCImageAlbumEditor * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj reloadRuntimeInfo:[self p_commonEditorRuntimeInfo]];
    }];
}

- (void)setPreviewSize:(CGSize)previewSize
{
    _previewSize = previewSize;
}

- (void)beginCurrentImageEditorBatchUpdate
{
    [self.p_currentActiveImageEditor beginCurrentImageEditorBatchUpdate];
}

- (void)endCurrentImageEditorBatchUpdate
{
    [self.p_currentActiveImageEditor endCurrentImageEditorBatchUpdate];
}

- (void)setAutoPlayInterval:(NSTimeInterval)autoPlayInterval
{
    _autoPlayInterval = autoPlayInterval;
    self.playerView.autoPlayInterval = autoPlayInterval;
}

- (void)startAutoPlay
{
    [self.playerView startAutoPlay];
}

- (void)stopAutoPlay
{
    [self.playerView stopAutoPlay];
}

- (void)reloadData
{
    // 数据有可能变更，尝试重新缓存
    [self p_reloadReuseableImageEditorWithIndex:self.currentIndex];
    [self.preloadIndexs enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self p_reloadReuseableImageEditorWithIndex:obj.integerValue];
    }];
    [self.playerView reloadData];
}

- (void)scrollToIndex:(NSInteger)index
{
    [self.playerView scrollToIndex:index];
}

- (void)markCurrentImageNeedReload
{
    [self p_getActiveImageEditorIfExistAtIndex:self.currentIndex].needForceReloadOnceFlag = YES;
}

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
    
    [[self p_allImageEditorsCache] enumerateObjectsUsingBlock:^(ACCImageAlbumEditor * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj updateEditWithTypes:ACCImageAlbumEditorEffectUpdateTypeHDR];
    }];
}


#pragma mark - Filter

- (void)updateComposerFilterWithFilterId:(NSString *)filterId
                                filePath:(NSString *)filePath
                               intensity:(float)intensity
{
    BOOL hasFilter = (!ACC_isEmptyString(filterId) && !ACC_isEmptyString(filePath));
    
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s, hasFilter:%@", __func__,@(hasFilter)]];
    
    [self currentImageItemModel].filterInfo.effectIdentifier = hasFilter? filterId : nil;
    [self.currentImageItemModel.filterInfo setAbsoluteFilePath:hasFilter ? filePath : nil];
    self.currentImageItemModel.filterInfo.filterIntensityRatio = hasFilter? @(intensity) : nil;
    
    [self.p_currentActiveImageEditor updateEditWithTypes:ACCImageAlbumEditorEffectUpdateTypeFilter];
}


#pragma mark - Sticker

- (NSInteger)addInfoStickerWithPath:(NSString *)path effectInfo:(NSArray *)effectInfo userInfo:(NSDictionary *)userInfo imageIndex:(NSInteger)imageIndex;
{
    
    if (ACC_isEmptyString(path)) {
        [self p_logErrorWithLogMsg:[NSString stringWithFormat:@"addInfoSticker error : no file path"]];
        return ACCImageEditInvaildStickerId;
    }
    
    // 例如从编辑页进入到发布页 走的是合成，这个时候很多editor并没有实例，所以 先简单的add进入就可以的
    // 复制一个fake stickerId避免被过滤掉，走恢复逻辑的时候回创建真正的stickerId，然后更新映射关系
    NSInteger stickerId = ACCImageEditFakeStickerId;
    
    ACCImageAlbumEditor *imageEditor = [self p_getActiveImageEditorIfExistAtIndex:imageIndex];
    
    ACCImageAlbumItemModel *imageItem = [self imageItemAtIndex:imageIndex];
    
    NSInteger orderIndex =  [imageItem.stickerInfo maxOrder] +1;
    
    // 如果editor不存在 说明不在缓存里，那先加入到data里下次会走恢复
    if (imageEditor)  {
        stickerId = [imageEditor addInfoStickerWithPath:path effectInfo:effectInfo orderIndex:orderIndex];
        [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s, addInfoSticker with editor, sticker id:%@", __func__,@(stickerId)]];
    }
    
    if (ACCIImageEditIsInvaildSticker(stickerId)) {
        [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"%s, addInfoSticker without editor, sticker id:%@", __func__,@(stickerId)]];
        return stickerId;
    }

    ACCImageAlbumStickerModel *sticker = [[ACCImageAlbumStickerModel alloc] initWithTaskId:self.albumData.taskId];
    [sticker setAbsoluteFilePath:path];
    sticker.uniqueId = [self.albumData maxStickerUniqueId] + 1;
    [self p_updateStickerIdMappingWithUniqueId:sticker.uniqueId stickerId:stickerId];
    sticker.param.order = orderIndex;
    sticker.userInfo = userInfo;
    sticker.effectInfo = effectInfo;
    
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
    
    ACCImageAlbumItemModel *imageItem = [self imageItemAtIndex:stickerResult.imageIndex];
    ACCImageAlbumEditor *imageEditor = [self p_getActiveImageEditorIfExistAtIndex:stickerResult.imageIndex];
    
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
    
    ACCImageAlbumStickerProps *currentProps = stickerResult.sticker.param;
    ACCImageAlbumEditorStickerUpdateType realUpdateTypes = ACCImageAlbumEditorStickerUpdateTypeNone;

    ACCImageAlbumItemModel *imageItem = [self imageItemAtIndex:stickerResult.imageIndex];
    ACCImageAlbumEditor *imageEditor = [self p_getActiveImageEditorIfExistAtIndex:stickerResult.imageIndex];
    
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
    
    if (!stickerResult.sticker) {
        NSParameterAssert(stickerResult.sticker != nil);
        [self p_logErrorWithLogMsg:[NSString stringWithFormat:@"get info sticker bounding error : no sticker found:"]];
        return UIEdgeInsetsZero;
    }
    
    ACCImageAlbumEditor *imageEditor = [self p_getActiveImageEditorIfExistAtIndex:stickerResult.imageIndex];
    if (!imageEditor) {
        [self p_logErrorWithLogMsg:[NSString stringWithFormat:@"get info sticker bounding error : no active image editor at image index:%@",@(stickerResult.imageIndex)]];
        return UIEdgeInsetsZero;
    }
    
    return [imageEditor getInfoStickerBoundingBoxWithStickerId:kStickerIdWithUniqueId(uniqueId)];
}


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


#pragma mark - Capture

- (UIImage *_Nullable)capturePreviewUIImage
{
    return [[self p_currentActiveImageEditor] getRenderingImage];
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
    
    [[ACCImageAlbumCaptureManager sharedManager] fetchPreviewImageAtIndex:index imageItem:imageItem containerSize:self.containerSize preferredSize:size usingOriginalImage:usingOriginalImage compeletion:compeletion];
}

- (void)beginImageAlbumPreviewTaskExportItemRetainAndReuse
{
    [[ACCImageAlbumCaptureManager sharedManager] beginImageAlbumPreviewTaskExportItemRetainAndReuse];
}

- (void)endImageAlbumPreviewTaskExportItemRetainAndReuse
{
    [[ACCImageAlbumCaptureManager sharedManager] endImageAlbumPreviewTaskExportItemRetainAndReuse];
}

@end
