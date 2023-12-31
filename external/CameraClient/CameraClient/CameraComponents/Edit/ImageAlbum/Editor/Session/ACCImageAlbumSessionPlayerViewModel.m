//
//  ACCImageAlbumSessionPlayerViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/8/17.
//

#import "ACCImageAlbumSessionPlayerViewModel.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCImageAlbumPlayerPreviewExportManager.h"
#import "ACCImageAlbumEditPlayerView.h"
#import "ACCImageAlbumPlayerItemContainerView.h"
#import "ACCImageAlbumEditorGeometry.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import "ACCConfigKeyDefines.h"

@class ACCImageItemStruct;
typedef NSArray <NSString *> *ItemIdList;
typedef NSArray <ACCImageItemStruct *> *ItemStructList;

NS_INLINE NSString *kLogStringFromArray(NSArray *array) {
    
    if (!array.count) {
        return @"[empty]";
    }
    return [NSString stringWithFormat:@"[%@]", [array componentsJoinedByString:@","]];
}

NS_INLINE NSArray *kFilterList(NSArray *list) {

    NSMutableArray *ret  = [NSMutableArray array]; // 用Array保持有序，而非set
    [list.copy enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![ret containsObject:obj]) {
            [ret acc_addObject:obj];
        }
    }];
    return [ret copy];
}

// 一张图片对应一个playerItemView以及导出的image数据等
@interface ACCImageAlbumEditorPlayerItemModel : NSObject

- (instancetype)initWithContainerSize:(CGSize)containerSize;
@property (nonatomic, strong, readonly) ACCImageAlbumPlayerItemContainerView *playerItemView;
// 初始化或者被标记需要更新导出的图片则为YES
@property (nonatomic, assign) BOOL needUpdate;

@end

// 注意，index和imageItem并非强关联，业务上随时有可能更改图集的数据源
// 所以任何场景都不要使用index来判断，仅仅用于输出log，使用itemId作为唯一标识
@interface ACCImageItemStruct : NSObject

@property (nonatomic, strong, readonly) ACCImageAlbumItemModel *itemModel;
- (NSString *)itemId;
@property (nonatomic, strong, readonly) NSNumber *index;
+ (instancetype)structWithItemModel:(ACCImageAlbumItemModel *)itemModel index:(NSNumber *)index;

@end


@interface  ACCImageAlbumSessionPlayerViewModel ()
<
ACCImageAlbumEditPlayerViewDelegate,
ACCImageAlbumEditPlayerViewDataSource
>

/// - - - - - - - init data
@property (nonatomic, strong) ACCImageAlbumData *albumData;
@property (nonatomic, strong) ACCImageAlbumEditor *imageEditor;
@property (nonatomic, strong) UIView *playerContainerView;

/// association
@property (nonatomic, strong) ACCImageAlbumEditPlayerView *playerView;
@property (nonatomic, strong) ACCImageAlbumPlayerPreviewExportManager *exportManager;

/// - - - - - - - runtime data
// 预加载的图片池
@property (nonatomic, strong) NSMutableDictionary <NSString *, ACCImageAlbumEditorPlayerItemModel *> *activePlayerItemlPool;
// 当前预加载的对应indexs
@property (nonatomic, copy) NSArray <NSNumber *> *currentActivePlayerIndexs;

/// - - - - - - - flags
// 表示最后一次reload过的item，防止重复reload
@property (nonatomic,   copy) NSString *lastReloadedItemId;
@property (nonatomic, assign) BOOL didPlayerActived;
@property (nonatomic, assign) BOOL isPreviewMode;

/// - - - - - - - DEBUG监控
@property (nonatomic, strong) NSNumber *lastOperationMonitoringStartTime;
@property (nonatomic, assign) NSInteger operationMonitoringConsumingCount;
@property (nonatomic, strong) NSString *operationMonitoringConsumingLog;

@end

@implementation ACCImageAlbumSessionPlayerViewModel
@synthesize currentIndex  = _currentIndex, containerSize = _containerSize;
@synthesize onCustomerContentViewRecovered, onCurrentImageEditorChanged, onPreviewModeChanged;
@synthesize onPlayerDraggingStatusChangedHandler, willScrollToIndexHandler;

#pragma mark - life cycle
- (instancetype)initWithImageAlbumData:(ACCImageAlbumData *)albumData
                         containerSize:(CGSize)containerSize
{
    if (self = [super init]) {
        
        // 由于优化后放开了所有机型， 6S以下低端机需要开启，否则滑动过快会黑屏，加开关为了防止有遗漏的机型可以动态配置
        _isLowLevelDeviceOpt = ![UIDevice acc_isBetterThanIPhone7] ||
        ACCConfigBool(kConfigBool_image_album_current_device_is_low_level_opt_target);
        
        _albumData = albumData;
        _containerSize = containerSize;
        
        _activePlayerItemlPool = [NSMutableDictionary dictionary];
        
        // playerView需要初始化，用于接受接口传下来的一些配置参数
        _playerView = ({
            ACCImageAlbumEditPlayerView *playerView = [[ACCImageAlbumEditPlayerView alloc] initWithFrame:CGRectMake(0, 0, containerSize.width, containerSize.height)];
            playerView.delegate = self;
            playerView.dataSource = self;
            playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            playerView;
        });

    }
    return self;
}

- (void)resetWithContainerView:(UIView *)view
{
    if (view == self.playerContainerView) {
        [self p_logInfoWithLogMsg:@"FLAG:lifeCycle>>> resetWithContainerView ignored because of same view" isError:NO];
        return;
    }
    
    [self p_logInfoWithLogMsg:@"FLAG:lifeCycle>>> resetWithContainerView" isError:NO];
    
    self.playerContainerView = view;
    
    [self p_setupImageEditorIfNeed];
    [self p_setupExportManagerIfNeed];
    [self p_setupInitActivePlayerItemPoolIfNeed];

    [self.playerView removeFromSuperview];
    [view addSubview:self.playerView];
    self.playerView.center = CGPointMake(view.bounds.size.width / 2.f, view.bounds.size.height / 2.f);
    [self.playerView reloadData];
    
    self.didPlayerActived = YES;
    
    ACCBLOCK_INVOKE(self.onCurrentImageEditorChanged, self.currentIndex, NO);
}

- (void)releasePlayer
{
    [self p_logInfoWithLogMsg:@"FLAG:lifeCycle>>> releasePlayer" isError:NO];
    
    self.playerContainerView = nil;
    self.didPlayerActived = NO;
    
    [self.playerView stopAutoPlay];
    [self.playerView removeFromSuperview];
    
    [self.imageEditor markAsReleased];
    self.imageEditor = nil;
    [self.exportManager releaseAllOperations];
    self.exportManager = nil;
    
    self.lastReloadedItemId = nil;
    [self.activePlayerItemlPool removeAllObjects];
}

#pragma mark - public

- (void)reloadData
{
    [self p_logInfoWithLogMsg:@"FLAG:lifeCycle>>> reloadData" isError:NO];
    
    // 外部可能已经更新了数据源，重新计算池子
    // 重构后并不需要整个都刷新，只需要计算预加载的池子与缓存的池子的diff
    if (self.currentActivePlayerIndexs.count) {
        [self p_updateActivePlayerItemsPoolWithPreloadIndexs:self.currentActivePlayerIndexs];
    }
    // 触发cell的reload，加载最新的play item view如果有
    if (self.didPlayerActived) {
        [self.playerView reloadData];
    }
}

- (void)scrollToIndex:(NSInteger)index
{
    if (!self.didPlayerActived) {return;}
    [self.playerView scrollToIndex:index];
}

- (void)markCurrentImageNeedReload
{
    [self markCurrentImageHasBeenModify];
}

- (void)startAutoPlay
{
    if (!self.didPlayerActived) {return;}
    [self.playerView startAutoPlay];
}

- (void)stopAutoPlay
{
    if (!self.didPlayerActived) {return;}
    [self.playerView stopAutoPlay];
}

- (void)updateAlbumData:(ACCImageAlbumData *)albumData {
    _albumData = albumData;
}

#pragma mark - protect

- (void)markCurrentImageHasBeenModify
{
    // 当前的简单标记即可，等下一次预加载导出的时候会自动加到任务中
    // 因为当前的图片展示的是image editor实例，像贴纸拖动的时候会频繁调用，所以并不需要立即重新导出图片以优化性能
    [self p_playerItemModelAtIndex:self.currentIndex].needUpdate = YES;
    self.imageEditor.needForceReloadOnceFlag = YES;
}

- (void)reloadAllPlayerItems
{
    // mark all has been edited
    [[self.activePlayerItemlPool allValues] enumerateObjectsUsingBlock:^(ACCImageAlbumEditorPlayerItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.needUpdate = YES;
    }];
    
    // 由于所有图片编辑效果都发生改变，所以需要立即更新池子
    if (self.currentActivePlayerIndexs.count) {
        [self p_updateActivePlayerItemsPoolWithPreloadIndexs:self.currentActivePlayerIndexs];
    }
}

#pragma mark - reload impl

// 根据预加载的index重新计算需要导出的缓存池子
- (void)p_updateActivePlayerItemsPoolWithPreloadIndexs:(NSArray<NSNumber *> *)preloadIndexs
{
    [self debugCheckPreloadIndex:preloadIndexs currentIndex:self.currentIndex itemCount:self.albumData.imageAlbumItems.count];
    
    // 去重
    NSMutableSet *tempPreloadIndexSet = [NSMutableSet setWithArray:preloadIndexs?:@[]];
    // 防止当前的被过滤
    [tempPreloadIndexSet addObject:@(self.currentIndex)];
    preloadIndexs = [tempPreloadIndexSet allObjects];
    
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"FLAG:RELOAD>>> reloadActive: %@", kLogStringFromArray(preloadIndexs)] isError:NO];
    
    ///@note 不能判断 activeIndexs 与 currentActivePlayerIndexs相等就return，因为index和实际item并没有强关联
    ///      在数据源变化后，即使相同的indexList计算出的item也未必一样
    self.currentActivePlayerIndexs = preloadIndexs;
    
    ItemStructList activeItemList = [self p_imageItemStructListFromIndexs:preloadIndexs];
    ItemIdList activeItemIdList = [self p_imageItemIdListFromImageItemStructList:activeItemList];
    
    // delete and release unused player item cache
    [self.activePlayerItemlPool.allKeys.copy enumerateObjectsUsingBlock:^(NSString *_Nonnull itemId, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (![activeItemIdList containsObject:itemId]) {
            // release view
            ACCImageAlbumEditorPlayerItemModel *itemModel = self.activePlayerItemlPool[itemId];
            [itemModel.playerItemView removeFromSuperview];
            [itemModel.playerItemView updateRenderImage:nil]; // 预防view被持有image未释放
            [self.activePlayerItemlPool removeObjectForKey:itemId];
        }
    }];
    
    // add new if not exist
    [activeItemList enumerateObjectsUsingBlock:^(ACCImageItemStruct * _Nonnull itemStruct, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *itemId = itemStruct.itemId;
        
        if (ACC_isEmptyString(itemId)) {
            NSAssert(NO, @"check");
            return;
        }
        // add new cache
        if (!self.activePlayerItemlPool[itemId]) {
            
            ACCImageAlbumEditorPlayerItemModel *playerItemModel = [self p_creatPlayerItemModelWithItemStruct:itemStruct];
            self.activePlayerItemlPool[itemId] = playerItemModel;
            
            // 给业务侧恢复业务的容器，例如贴纸容器
            [self p_doRecoverCustomerContentViewWithPlayerItemModel:playerItemModel
                                                          itemStruct:itemStruct];
        }
    }];
    
    if (self.isLowLevelDeviceOpt) {
        // 低端机先取消已经不需要的任务
        [self.exportManager cancelOperationsExcludeWithItemIdList:activeItemIdList];
    }
    
    // 将池子里所有需要更新导出的添加到任务里
    [self p_exportAllNeedUpdatePlayerItemsFromItemsPool];
    // 新加的player item view需要同步一下runtime信息
    [self p_updateRuntimeStatus];
    [self p_updateDebugLogString];
}

// 导出所有被标记需要更新的item
- (void)p_exportAllNeedUpdatePlayerItemsFromItemsPool
{
    // 找到所有需要导出的，包括新加的和之前标记过需要重新导出的
    NSMutableArray <NSString *> *itemIdList = [NSMutableArray array];
    [self.activePlayerItemlPool.copy enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull itemId, ACCImageAlbumEditorPlayerItemModel * _Nonnull obj, BOOL * _Nonnull stop) {
        
        if (obj.needUpdate && ![itemIdList containsObject:itemId]) {
            [itemIdList acc_addObject:itemId];
        }
        
        obj.needUpdate = NO; // 导出过一次则不需要再次更新直到标记为需要重新导出
    }];
    
    // 批量添加需要导出的任务
    [self p_addExportImageItemOperationsWithItemIdList:[itemIdList copy]];
}

- (void)p_addExportImageItemOperationsWithItemIdList:(ItemIdList)itemIdList
{
    itemIdList = kFilterList(itemIdList);
    
    if (!itemIdList.count) {
        return;
    }
    
    // 标记下次editor需要重新reload，导出会刷新editor的数据，所以在刷新结束后需要重新reload为当前
    self.lastReloadedItemId = nil;
    
    // 如果需要导出当前item的，则当前item的导出任务 则需要排在首个
    NSMutableArray <NSString *> *tempItemList = [itemIdList mutableCopy];
    NSString *currentItemId = [self p_imageItemStructAtIndex:self.currentIndex].itemId;
    if (currentItemId && [tempItemList containsObject:currentItemId]) {
        [tempItemList removeObject:currentItemId];
        [tempItemList acc_insertObject:currentItemId atIndex:0];
    }
    itemIdList = [tempItemList copy];
    
    // indexs just for log
    NSMutableArray <NSNumber *> *reloadedItemIndexs = [NSMutableArray array];
    
    for (NSString *itemId in [itemIdList copy]) {
        
        ACCImageItemStruct *itemStruct = [self p_imageItemStructWithItemId:itemId];
        
        if (!itemStruct.itemModel) {
            NSAssert(NO, @"index out of bounce, check");
            continue;
        }
        
        [reloadedItemIndexs acc_addObject:itemStruct.index];
        
        [self.exportManager addExportOperationWithItemModel:itemStruct.itemModel index:itemStruct.index.integerValue];
    }
    
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"FLAG:RELOAD>>> addedExportImageOperations:%@", kLogStringFromArray(reloadedItemIndexs)] isError:NO];
    
    // 都导出完成后需要最终刷新一次当前的
    // 如果正在交互则等会在交互完成后再刷新，可以减少一次刷新的操作
    if (!self.playerView.isDraggingOrScrolling) {
        [self p_addReloadCurrentEditorOperationIfNeed];
    }
}

- (void)p_addReloadCurrentEditorOperationIfNeed
{
    BOOL needReload = NO;
    NSString *currentItemId = [self p_imageItemStructAtIndex:self.currentIndex].itemId;
    if (ACC_isEmptyString(self.lastReloadedItemId) ||
        ![currentItemId isEqualToString:self.lastReloadedItemId]) {
        needReload = YES;
    }
    if (!needReload) {
        return;
    }
    
    ACCImageItemStruct *imageItemStruct = [self p_imageItemStructAtIndex:self.currentIndex];
    if (imageItemStruct.itemModel) {
        self.lastReloadedItemId = imageItemStruct.itemId;
        [self.exportManager addReloadOperationWithItemModel:imageItemStruct.itemModel index:imageItemStruct.index.integerValue];
        [self p_logInfoWithLogMsg:@"FLAG:RELOAD>>> added reload current editor operation" isError:NO];
    }
}

// 创建新的player item之后需要回调给业务侧进行业务恢复，例如贴纸容器等
- (void)p_doRecoverCustomerContentViewWithPlayerItemModel:(ACCImageAlbumEditorPlayerItemModel *)playerItemModel
                                               itemStruct:(ACCImageItemStruct *)itemStruct
{
    ACCImageAlbumItemModel *itemModel = itemStruct.itemModel;
    
    CGSize imageSize = CGSizeMake(itemModel.originalImageInfo.width, itemModel.originalImageInfo.height);

    if (!ACCImageEditSizeIsValid(imageSize)) {
        
        NSAssert(NO, @"can not get image size");
        
        if (!ACC_isEmptyString([itemModel.originalImageInfo getAbsoluteFilePath])) {
            UIImage *originImage = [UIImage imageWithContentsOfFile:[itemModel.originalImageInfo getAbsoluteFilePath]];
            imageSize = originImage.size;
        }
    }
    if (!ACCImageEditSizeIsValid(imageSize)) {
        [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"recover customer content view failded because of invaild image size:%@", itemStruct.index] isError:YES];
        NSAssert(NO, @"can not get image size");
        return;
    }
    
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"recover customer content view at index:%@", itemStruct.index] isError:NO];
    
   CGSize imageLayerSize = [ACCImageAlbumEditor calculateImageLayerSizeWithContainerSize:self.containerSize imageSize:imageSize needClip:YES];
    
    CGSize originalImageLayerSize = [ACCImageAlbumEditor calculateImageLayerSizeWithContainerSize:self.containerSize imageSize:imageSize needClip:NO];
    
    ACCBLOCK_INVOKE(self.onCustomerContentViewRecovered, playerItemModel.playerItemView.customerContentView, itemModel, itemStruct.index.integerValue, imageLayerSize, originalImageLayerSize);
}

- (ACCImageAlbumEditorPlayerItemModel *)p_creatPlayerItemModelWithItemStruct:(ACCImageItemStruct *)itemStruct
{
    ACCImageAlbumEditorPlayerItemModel *playerItemModel = [[ACCImageAlbumEditorPlayerItemModel alloc] initWithContainerSize:self.containerSize];
    playerItemModel.needUpdate = YES;
    
    // 低端机先展示压缩过的原图占位图，由于压缩后很小，加载很快，而导出相对较慢，所以可以避免黑屏
    // 高端机不需要，因为高端机导出即使毫秒，加上预加载的判断，不会出现cell展示晚于导出
    if (self.isLowLevelDeviceOpt) {
        NSString *placeholderImageFilePath = itemStruct.itemModel.originalImageInfo.placeHolderImageInfo.getAbsoluteFilePath;
        if (!ACC_isEmptyString(placeholderImageFilePath)) {
            UIImage *placeholderImage = [UIImage imageWithContentsOfFile:placeholderImageFilePath];
            if (placeholderImage) {
                [playerItemModel.playerItemView updateRenderImage:placeholderImage];
            }
        }
    }
    return playerItemModel;
}

- (void)p_updateRuntimeStatus
{
    [[[self.activePlayerItemlPool allValues] copy] enumerateObjectsUsingBlock:^(ACCImageAlbumEditorPlayerItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 预览模式不可交互
        obj.playerItemView.customerContentView.userInteractionEnabled = !self.isPreviewMode;
        ACCBLOCK_INVOKE(self.onPreviewModeChanged, obj.playerItemView.customerContentView, self.isPreviewMode);
    }];
}

#pragma mark - public player setter

- (void)setScrollEnable:(BOOL)scrollEnable
{
    self.playerView.scrollEnable = scrollEnable;
}

- (void)setBottomOffset:(CGFloat)bottomOffset
{
    self.playerView.bottomOffset = bottomOffset;
}

- (void)setIsPreviewMode:(BOOL)isPreviewMode
{
    _isPreviewMode = isPreviewMode;
    [self p_updateRuntimeStatus];
}

- (void)setPreviewSize:(CGSize)previewSize
{
    // unsupport，理论上之前的也是用不上的，先保留接口全量后一起删除
}

- (void)setAutoPlayInterval:(NSTimeInterval)autoPlayInterval
{
    self.playerView.autoPlayInterval = autoPlayInterval;
}

- (void)updateInteractionContainerAlpha:(CGFloat)alpha
{
    [self.playerView updateInteractionContainerAlpha:alpha];
}

- (void)setPageControlStyle:(ACCImageAlbumEditorPageControlStyle)pageControlStyle
{
    self.playerView.pageControlStyle = pageControlStyle;
}

#pragma mark - public getter

- (UIView *)customerContentViewAtIndex:(NSInteger)index
{
    ACCImageAlbumEditorPlayerItemModel *playerItemModel = [self p_playerItemModelAtIndex:index];
    return playerItemModel.playerItemView.customerContentView;
}

- (UIView *)playerViewAtIndex:(NSInteger)index
{
    ACCImageAlbumEditorPlayerItemModel *playerItemModel = [self p_playerItemModelAtIndex:index];
    if (!playerItemModel) {
        NSAssert(NO, @"no cache for index, check life cycle");
        return [UIView new];
    }
    return playerItemModel.playerItemView;
}

- (UIImage *)renderedImageAtIndex:(NSInteger)index
{
    ACCImageAlbumEditorPlayerItemModel *playerItemModel = [self p_playerItemModelAtIndex:index];
    // 如果有更新不能直接用
    if (!playerItemModel.needUpdate) {
        return [self p_playerItemModelAtIndex:index].playerItemView.renderedImage;
    }
    return nil;
}

- (ACCImageAlbumEditor *)idleImageEditorIfExistAtIndex:(NSInteger)index
{
    if (self.exportManager.currentOperationCount > 0) {
        // busy
        return nil;
    }
    if (index == self.currentIndex &&
        [self p_isCurrentItemModel:self.imageEditor.imageItemModel]) {
        return self.imageEditor;
    }
    return nil;
}

- (ACCImageAlbumEditor *)currentIdleImageEditorIfExist
{
    return [self idleImageEditorIfExistAtIndex:self.currentIndex];
}

- (ACCImageAlbumEditor *)anyReloadedImageEditorIfExist
{
    if (self.imageEditor.didAddImage) {
        return self.imageEditor;
    }
    return nil;
}

#pragma mark - ACCImageAlbumEditPlayerViewDelegate

- (void)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView
      didUpdateCurrentIndex:(NSInteger)currentIndex
              isByAutoTimer:(BOOL)isByAutoTimer
{
    if (currentIndex == self.currentIndex) {
        return;
    }
    _currentIndex = currentIndex;
    // update if need
    [self p_exportAllNeedUpdatePlayerItemsFromItemsPool];
    dispatch_async(dispatch_get_main_queue(), ^{
        // 下一个runloop去更新，因为有可能在更新完index之后会触发更新预加载逻辑，自动会刷新一次，避免重新刷新
        [self p_addReloadCurrentEditorOperationIfNeed];
        ACCBLOCK_INVOKE(self.onCurrentImageEditorChanged, currentIndex, isByAutoTimer);
    });
}

- (void)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView didUpdatePreloadIndexs:(NSArray<NSNumber *> *)preloadIndexs
{
    [self p_updateActivePlayerItemsPoolWithPreloadIndexs:preloadIndexs];
}

- (void)albumEditPlayerView:(nonnull ACCImageAlbumEditPlayerView *)playerView didUpdateDraggingStatus:(BOOL)isDrag
{
    ACCBLOCK_INVOKE(self.onPlayerDraggingStatusChangedHandler, isDrag);
}

- (void)albumEditPlayerView:(nonnull ACCImageAlbumEditPlayerView *)playerViewt willScrollToIndex:(NSInteger)targetIndex withAnimation:(BOOL)withAnimation isByAutoTimer:(BOOL)isByAutoTimer
{
    ACCBLOCK_INVOKE(self.willScrollToIndexHandler, targetIndex, withAnimation, isByAutoTimer);
}

- (void)albumEditPlayerViewDidEndAnimationAndDragging:(ACCImageAlbumEditPlayerView *)playerView
{
    [self p_addReloadCurrentEditorOperationIfNeed];
}

#pragma mark - ACCImageAlbumEditPlayerViewDataSource
- (UIView *)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView previewViewAtIndex:(NSInteger)index
{
    UIView *ret =  [self playerViewAtIndex:index];
    return ret ?: [UIView new];
}

- (NSInteger)numberOfPreviewForAlbumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView
{
    return self.albumData.imageAlbumItems.count;
}

- (BOOL)albumEditPlayerView:(nonnull ACCImageAlbumEditPlayerView *)playerView hasPreloadedItemWithIndex:(NSInteger)index {
    
    return [self p_playerItemModelAtIndex:index] != nil;
}

#pragma mark - lazy setups

- (void)p_setupImageEditorIfNeed
{
    if (self.imageEditor) {
        return;
    }

    ACCImageAlbumEditor *editor = [[ACCImageAlbumEditor alloc] initWithContainerSize:self.containerSize];
    self.imageEditor = editor;
    @weakify(self);
    [editor setOnStickerRecovered:^(NSInteger uniqueId, NSInteger stickerId) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.onStickerRecovered, uniqueId, stickerId);
    }];
}

- (void)p_setupExportManagerIfNeed
{
    if (self.exportManager) {
        return;
    }
    
    self.exportManager = [[ACCImageAlbumPlayerPreviewExportManager alloc] initWithEditor:self.imageEditor];
    
    @weakify(self);
    self.exportManager.onOperationWillStart = ^(ACCImageAlbumItemModel * _Nonnull targetItemModel, NSInteger index,  BOOL isReloadOperation) {
        
        @strongify(self);
        
        if (ACCConfigBool(kConfigBool_enable_image_album_debug_tool)) {
            if (self.lastOperationMonitoringStartTime == nil) {
                self.lastOperationMonitoringStartTime = @(CFAbsoluteTimeGetCurrent());
            }
            self.operationMonitoringConsumingCount++;
        }

        // 当前任务开始执行的时候隐藏editor的视图，当前展示的将会是渲染的图片
        // 如果执行的是当前导出任务不需要隐藏
        // 例如贴纸移动后再滑动图片导出预加载的时候由于当前图片还没重新导出，所以隐藏的话会跳变到之前的图片
        if (![self p_isCurrentItemModel:targetItemModel]) {
            self.imageEditor.containerView.hidden = YES;
        }
        
        [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"FLAG:Operation>>> onOperationWillStart index: %@, isReloadOperation: %@", @(index), @(isReloadOperation)] isError:NO];
    };
    
    self.exportManager.onExportCompleteHandler = ^(UIImage * _Nonnull image, ACCImageAlbumItemModel * _Nonnull itemModel, NSInteger index) {
        
        @strongify(self);
        ACCImageAlbumEditorPlayerItemModel *playerItemModel = [self p_playerItemModelWithItemId:itemModel.itemIdentify];
        if (image) {
            [playerItemModel.playerItemView updateRenderImage:image];
        }
        
        [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"FLAG:Operation>>> onExportOperationComplete index: %@", @(index)] isError:NO];
    };
    
    self.exportManager.onReloadCompleteHandler = ^(ACCImageAlbumItemModel * _Nonnull targetItemModel, NSInteger index) {
        
        @strongify(self);
        if ([self p_isCurrentItemModel:targetItemModel]) {
            
            [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"FLAG:Operation>>> onReloadOperationComplete index: %@", @(index)] isError:NO];
            
            self.imageEditor.containerView.hidden = NO;
            ACCImageAlbumEditorPlayerItemModel *playerItemModel = [self p_playerItemModelAtIndex:self.currentIndex];
            [playerItemModel.playerItemView updateEditingView:self.imageEditor.containerView];
        }
    };
    
    self.exportManager.onAllOperationsCompleteHandler = ^{
        
        @strongify(self);
        
        [self p_logInfoWithLogMsg:@"FLAG:Operation>>> onAllOperationsComplete" isError:NO];
        
        ACCBLOCK_INVOKE(self.onAllRenderOperationsCompleteHandler);
        
        // monitoring
        if (ACCConfigBool(kConfigBool_enable_image_album_debug_tool)) {
            NSTimeInterval consuming = CFAbsoluteTimeGetCurrent() - self.lastOperationMonitoringStartTime.doubleValue;
            self.operationMonitoringConsumingLog = [NSString stringWithFormat:@"任务%@个\n耗时%.2f毫秒",@(self.operationMonitoringConsumingCount), consuming * 1000];
            [self p_updateDebugLogString];
            self.operationMonitoringConsumingCount = 0;
            self.lastOperationMonitoringStartTime = nil;
        }
    };
    
    self.exportManager.onOperationsCountChanged = ^(NSInteger count) {
        @strongify(self);
        [self p_updateDebugLogString];
    };
}

- (void)p_setupInitActivePlayerItemPoolIfNeed
{
    if (!self.currentActivePlayerIndexs.count) {
        
        NSInteger start = 0;
        NSInteger realCacheCount = MIN(3, self.albumData.imageAlbumItems.count);
        NSRange activeEditorRange =  NSMakeRange(start, realCacheCount);
        
        NSMutableArray <NSNumber *> *preloadIndexs = [NSMutableArray array];
        
        for (NSInteger i = activeEditorRange.location; i < activeEditorRange.length; i++) {
            [preloadIndexs acc_addObject:@(i)];
        }
        
        [self p_updateActivePlayerItemsPoolWithPreloadIndexs:preloadIndexs];
    }
}

#pragma mark - utils
- (ACCImageItemStruct *)p_imageItemStructAtIndex:(NSInteger)index
{
    ACCImageAlbumItemModel *itemModel = [self.albumData.imageAlbumItems acc_objectAtIndex:index];
    if (!itemModel) {
        return nil;
    }
    return [ACCImageItemStruct structWithItemModel:itemModel index:@(index)];
}

- (ACCImageItemStruct *)p_imageItemStructWithItemId:(NSString *)itemId
{
    if (ACC_isEmptyString(itemId)) {
        return nil;
    }
    __block ACCImageItemStruct *ret = nil;
    [[self.albumData.imageAlbumItems copy] enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.itemIdentify isEqualToString:itemId]) {
            ret = [ACCImageItemStruct structWithItemModel:obj index:@(idx)];
            *stop = YES;
        }
    }];
    
    return ret;
}

- (ItemStructList)p_imageItemStructListFromIndexs:(NSArray <NSNumber *> *)indexs
{
    indexs = kFilterList(indexs);
    
    NSMutableArray<ACCImageItemStruct *> *ret = [NSMutableArray array];
    [[indexs copy] enumerateObjectsUsingBlock:^(NSNumber  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ACCImageItemStruct *imageItemStruct = [self p_imageItemStructAtIndex:obj.integerValue];
        [ret acc_addObject:imageItemStruct];
    }];
    return [ret copy];
}

- (ItemIdList)p_imageItemIdListFromImageItemStructList:(ItemStructList)itemStructList
{
    NSMutableArray <NSString *> *ret = [NSMutableArray array];
    [itemStructList.copy enumerateObjectsUsingBlock:^(ACCImageItemStruct * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [ret acc_addObject:obj.itemId];
    }];
    return [ret copy];
}

- (BOOL)p_isCurrentItemModel:(ACCImageAlbumItemModel *)itemModel
{
    NSString *currentItemId = [self p_imageItemStructAtIndex:self.currentIndex].itemId;
    return (currentItemId && [itemModel.itemIdentify isEqualToString:currentItemId]);
}

- (ACCImageAlbumEditorPlayerItemModel *)p_playerItemModelAtIndex:(NSInteger)index
{
    return [self p_playerItemModelWithItemId:[self p_imageItemStructAtIndex:index].itemId];
}

- (ACCImageAlbumEditorPlayerItemModel *)p_playerItemModelWithItemId:(NSString *)itemId
{
    if (ACC_isEmptyString(itemId)) {
        return nil;
    }
    return self.activePlayerItemlPool[itemId];
}

#pragma Mark -log
- (void)p_logInfoWithLogMsg:(NSString *)logMsg isError:(BOOL)isError
{
    
    NSString *log = [NSString stringWithFormat:@"\nImageAlbumSessionPlayerViewModel : msg:%@   currentImage:%@  currentActivePlayerIndexs:%@, PlayerItemsPoolCont:%@, operationCount:%@ ", logMsg, @(self.currentIndex), kLogStringFromArray(self.currentActivePlayerIndexs),@(self.activePlayerItemlPool.count), @([self.exportManager currentOperationCount])];
    
    if (isError) {
        AWELogToolError(AWELogToolTagEdit, log);
    } else {
        AWELogToolInfo(AWELogToolTagEdit, log);
    }
}

#pragma mark - debug
- (void)p_updateDebugLogString
{
    if (!ACCConfigBool(kConfigBool_enable_image_album_debug_tool)) {
        return;
    }
    
    NSArray *sortIndexs = [self.currentActivePlayerIndexs sortedArrayUsingComparator:^NSComparisonResult(NSNumber *_Nonnull obj1, NSNumber *_Nonnull obj2) {
        return obj2.integerValue > obj1.integerValue?NSOrderedAscending:NSOrderedDescending;
    }];
    

    NSString *log = [NSString stringWithFormat:@"cindex:%@\nactives:%@\npool cnt:%@\n队列cnt:%@\n队列:%@low level:%@", @(self.currentIndex), kLogStringFromArray(sortIndexs),@(self.activePlayerItemlPool.count), @([self.exportManager currentOperationCount]),self.operationMonitoringConsumingLog,@(self.isLowLevelDeviceOpt)];
    
    [self onDebugInfoLogChanged:log];
}

- (void)onDebugInfoLogChanged:(NSString *)debugLogString{}
- (void)debugCheckPreloadIndex:(NSArray<NSNumber *> *)indexs currentIndex:(NSInteger)currentIndex itemCount:(NSInteger)itemCount{}

@end


@implementation ACCImageAlbumEditorPlayerItemModel
@synthesize playerItemView = _playerItemView;

- (instancetype)initWithContainerSize:(CGSize)containerSize
{
    if (self = [super init]) {
        _playerItemView = [[ACCImageAlbumPlayerItemContainerView alloc] initWithContainerSize:containerSize];
        _needUpdate = YES;
    }
    return self;
}

@end

@implementation ACCImageItemStruct

+ (instancetype)structWithItemModel:(ACCImageAlbumItemModel *)itemModel index:(NSNumber *)index
{
    return [[self alloc] initWithItemModel:itemModel index:index];
}

- (instancetype)initWithItemModel:(ACCImageAlbumItemModel *)itemModel index:(NSNumber *)index
{
    if (self = [super init]) {
        _itemModel = itemModel;
        _index = index;
    }
    return self;
}

- (NSString *)itemId
{
    return self.itemModel.itemIdentify;
}

@end
