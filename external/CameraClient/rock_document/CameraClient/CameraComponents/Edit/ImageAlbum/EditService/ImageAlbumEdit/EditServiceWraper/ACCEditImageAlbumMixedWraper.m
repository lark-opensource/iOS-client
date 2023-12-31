//
//  ACCEditImageAlbumMixedWraper.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/23.
//

#import "ACCEditImageAlbumMixedWraper.h"
#import "ACCImageAlbumEditorSession.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCConfigKeyDefines.h"

@interface ACCEditImageAlbumMixedWraper ()<ACCEditBuildListener>

@property (nonatomic, weak) id<ACCImageAlbumEditorSessionProtocol> player;
@property (nonatomic, strong) NSHashTable <id <ACCEditImageAlbumMixedMessageProtocolD>> *subscriberArray;
@property (nonatomic, strong) NSMutableSet <NSString *> *stopPlayFlagKeys;


@end

@implementation ACCEditImageAlbumMixedWraper
@synthesize enableAutoPlay = _enableAutoPlay;
@synthesize isAutoPlaying = _isAutoPlaying;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _subscriberArray = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        _stopPlayFlagKeys = [NSMutableSet set];
    }
    return self;
}

- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession
{
    self.player = editSession.imageEditSession;
    
    @weakify(self);
    [self.player setOnCurrentImageEditorChanged:^ (NSInteger index, BOOL isByAutoTimer) {
        @strongify(self);
        for (id <ACCEditImageAlbumMixedMessageProtocolD> subscriber in self.subscriberArray.copy) {
            if ([subscriber respondsToSelector:@selector(onCurrentImageEditorChanged:)]) {
                [subscriber onCurrentImageEditorChanged:index];
            }
            
            if ([subscriber respondsToSelector:@selector(onCurrentImageEditorChanged: isByAutoTimer:)]) {
                [subscriber onCurrentImageEditorChanged:index isByAutoTimer:isByAutoTimer];
            }
        }
    }];
    
    [self.player setOnCustomerContentViewRecovered:^(UIView * _Nonnull contentView, ACCImageAlbumItemModel * _Nonnull imageItemModel, NSInteger index, CGSize imageLayerSize, CGSize originalImageLayerSize) {
        @strongify(self);
        for (id <ACCEditImageAlbumMixedMessageProtocol> subscriber in self.subscriberArray.copy) {
            if ([subscriber respondsToSelector:@selector(onImageEditorRecoveredAtIndex:contentView:imageItem:imageLayerSize:originalImageLayerSize:)]) {
                [subscriber onImageEditorRecoveredAtIndex:index
                                              contentView:contentView
                                                imageItem:imageItemModel
                                           imageLayerSize:imageLayerSize
                                   originalImageLayerSize:originalImageLayerSize];
            }
        }
    }];
    
    [self.player setOnPreviewModeChanged:^(UIView *contentView, BOOL isPreviewMode) {
        @strongify(self);
        for (id <ACCEditImageAlbumMixedMessageProtocol> subscriber in self.subscriberArray.copy) {
            if ([subscriber respondsToSelector:@selector(onImageEditorPreviewModeChangedAtContentView:isPreviewMode:)]) {
                [subscriber onImageEditorPreviewModeChangedAtContentView:contentView
                                                           isPreviewMode:isPreviewMode];
            }
        }
    }];
    
    [self.player setWillScrollToIndexHandler:^(NSInteger targetIndex, BOOL withAnimation, BOOL isByAutoTimer) {
        
        @strongify(self);
        for (id <ACCEditImageAlbumMixedMessageProtocolD> subscriber in self.subscriberArray.copy) {
            if ([subscriber respondsToSelector:@selector(onImagePlayerWillScrollToIndex:withAnimation:isByAutoTimer:)]) {
                [subscriber onImagePlayerWillScrollToIndex:targetIndex withAnimation:withAnimation isByAutoTimer:isByAutoTimer];
            }
        }
    }];
    
    [self.player setOnPlayerDraggingStatusChangedHandler:^(BOOL isDragging) {
        @strongify(self);
        for (id <ACCEditImageAlbumMixedMessageProtocolD> subscriber in self.subscriberArray.copy) {
            if ([subscriber respondsToSelector:@selector(onPlayerDraggingStatusChanged:)]) {
                [subscriber onPlayerDraggingStatusChanged:isDragging];
            }
        }
    }];
    
}

- (void)addSubscriber:(id<ACCEditImageAlbumMixedMessageProtocolD>)subscriber
{
    if (subscriber) {
        [self.subscriberArray addObject:subscriber];
    }
}

- (void)removeSubscriber:(id<ACCEditImageAlbumMixedMessageProtocolD>)subscriber
{
    [self.subscriberArray removeObject:subscriber];
}

- (void)resetWithContainerView:(UIView *)view
{
    [self.player resetWithContainerView:view];
}

- (void)replayMusic
{
    [self.player replayMusic];
}

- (void)continuePlayMusic
{
    [self.player continuePlayMusic];
}

- (void)pauseMusic
{
    [self.player pauseMusic];
}

- (void)replaceMusic:(id<ACCMusicModelProtocol>)music
{
    [self.player replaceMusic:music];
}

- (NSInteger)currentImageEditorIndex
{
    return self.player.currentIndex;
}

- (UIView *)currentImageEditorContentView
{
    return [self.player customerContentViewAtIndex:self.player.currentIndex];
}

- (ACCImageAlbumItemModel *)currentImageItemModel
{
    return [self.player imageItemAtIndex:self.player.currentIndex];
}

- (void)setImagePlayerScrollEnable:(BOOL)scrollEnable
{
    [self.player setScrollEnable:scrollEnable];
}

- (void)setImagePlayerIsPreviewMode:(BOOL)isPreviewMode
{
    [self.player setIsPreviewMode:isPreviewMode];
}

- (void)setImagePlayerPreviewSize:(CGSize)previewSize
{
    [self.player setPreviewSize:previewSize];
}

- (void)exportImagesWithProgress:(void (^)(NSInteger, NSInteger))progressBlock
                       onSucceed:(void (^)(NSArray<ACCImageAlbumExportItemModel *> *exportedItems))succeedBlock
                         onFaild:(void (^)(NSInteger))faildBlock
{
    [self.player exportImagesWithProgress:progressBlock onSucceed:succeedBlock onFaild:faildBlock];
}

- (CGSize)imageLayerSizeAtIndex:(NSInteger)index
{
    return [self.player imageLayerSizeAtIndex:index needClip:YES];
}

- (CGSize)imageSizeAtIndex:(NSInteger)index
{
    return [self.player imageOriginalSizeAtIndex:index];
}

- (NSInteger)totalImagePlayerImageCount
{
    return [self.player totalImageItemCount];
}

- (void)setPlayerBottomOffset:(CGFloat)bottomOffset
{
    [self.player setBottomOffset:bottomOffset];
}

- (void)releasePlayer
{
    [self.player releasePlayer];
}

- (void)startAutoPlayWithKey:(NSString *)key
{
    if (!ACCConfigBool(kConfigBool_enable_image_album_story)) {
        return;
    }
    if (ACC_isEmptyString(key)) {
        NSAssert(NO, @"key is invalid");
        return;
    }

    @synchronized (self) {
        if ([self.stopPlayFlagKeys containsObject:key]) {
            [self.stopPlayFlagKeys removeObject:key];
        }
        [self p_updateAutoPlayStatus];
    }
}

- (void)stopAutoPlayWithKey:(NSString *)key
{
    if (!ACCConfigBool(kConfigBool_enable_image_album_story)) {
        return;
    }
    
    if (ACC_isEmptyString(key)) {
        NSAssert(NO, @"key is invalid");
        return;
    }
    
    @synchronized (self) {
        [self.stopPlayFlagKeys addObject:key];
        [self p_updateAutoPlayStatus];
    }
}

- (void)p_updateAutoPlayStatus
{
    if (!self.enableAutoPlay && !self.isAutoPlaying) {
        return;
    }
    
    if (self.stopPlayFlagKeys.count > 0 || !self.enableAutoPlay) {
        [self.player stopAutoPlay];
        _isAutoPlaying = NO;
    } else {
        [self.player startAutoPlay];
        _isAutoPlaying = YES;
    }
}

- (void)setAutoPlayInterval:(NSTimeInterval)autoPlayInterval
{
    [self.player setAutoPlayInterval:autoPlayInterval];
}

- (void)reloadData
{
    [self.player reloadData];
}

- (void)scrollToIndex:(NSInteger)index
{
    [self.player scrollToIndex:index];
}

- (void)markCurrentImageNeedReload
{
    [self.player markCurrentImageNeedReload];
}

- (void)setPageControlStyle:(ACCImageAlbumEditorPageControlStyle)pageControlStyle
{
    [self.player setPageControlStyle:pageControlStyle];
}

- (void)updateInteractionContainerAlpha:(CGFloat)alpha
{
    [self.player updateInteractionContainerAlpha:alpha];
}

@end
