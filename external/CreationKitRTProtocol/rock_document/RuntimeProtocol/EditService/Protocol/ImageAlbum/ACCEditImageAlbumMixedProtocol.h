//
//  ACCEditImageAlbumMixedProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/23.
//

#import <Foundation/Foundation.h>
#import "ACCEditWrapper.h"
NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;
@class ACCImageAlbumItemModel;
@class ACCImageAlbumItemModel, ACCImageAlbumExportItemModel;

@protocol ACCEditImageAlbumMixedMessageProtocol <NSObject>

@optional
/// Image switch callback will trigger callback for the first time, similar to the change of video play time
- (void)onCurrentImageEditorChanged:(NSInteger)currentIndex;

/// With the reuse of image editor, the business can restore its own view, such as the gesture container of stickers
/// The editing effect is the same as that of the video. The image player does not need to restore the business itself
/// Contentview will be cleaned up and re created after reuse, so don't hold it because it's useless to hold it. If you need to cache your own view, cache it
- (void)onImageEditorRecoveredAtIndex:(NSInteger)index
                          contentView:(UIView *)contentView
                            imageItem:(ACCImageAlbumItemModel *)imageItemModel
                       imageLayerSize:(CGSize)imageLayerSize
               originalImageLayerSize:(CGSize)originalImageLayerSize;

- (void)onImageEditorPreviewModeChangedAtContentView:(UIView *)contentView
                                       isPreviewMode:(BOOL)isPreviewMode;

@end

/// Some image editing mode unique ability split, follow-up to see if you can align in the move
/// The assumption is that most interfaces can be roughly aligned by redefining input and output data, and subsequent versions are being optimized
@protocol ACCEditImageAlbumMixedProtocol <ACCEditWrapper>

#pragma mark - view
- (void)resetWithContainerView:(UIView *)view;

#pragma mark - observer
- (void)addSubscriber:(id<ACCEditImageAlbumMixedMessageProtocol>)subscriber;

- (void)removeSubscriber:(id <ACCEditImageAlbumMixedMessageProtocol>)subscriber;

#pragma mark - music
// play from the beginning
- (void)replayMusic;

// play from the current time
- (void)continuePlayMusic;

// pause
- (void)pauseMusic;

/// will auto play if player is playing when replace
- (void)replaceMusic:(id<ACCMusicModelProtocol>)music;

#pragma mark - control
- (void)setImagePlayerScrollEnable:(BOOL)scrollEnable;

- (void)setImagePlayerIsPreviewMode:(BOOL)isPreviewMode;

- (void)setImagePlayerPreviewSize:(CGSize)previewSize;

/// Release all ve resources, image resources and pageview of the edit page, but not including the editor being exported, so the export task will not be affected
/// It is applicable to release some editor resources of edit page in publishing process
- (void)releasePlayer;

#pragma mark - getter
- (NSInteger)currentImageEditorIndex;

- (ACCImageAlbumItemModel *)currentImageItemModel;

- (UIView *_Nullable)currentImageEditorContentView;

- (NSInteger)totalImagePlayerImageCount;

/// The size of the image after the screen render, rather than the size of the image itself, will be scaled proportionally
- (CGSize)imageLayerSizeAtIndex:(NSInteger)index;

/// Image original size
- (CGSize)imageSizeAtIndex:(NSInteger)index;

#pragma mark - setter
// For example, when editing the bar of the page, set the offset to change the position of pageview, etc., which will not affect the layout of the picture
- (void)setPlayerBottomOffset:(CGFloat)bottomOffset;

#pragma mark - export
- (void)exportImagesWithProgress:(void(^_Nullable)(NSInteger finishedCount, NSInteger totalCount))progressBlock
                       onSucceed:(void(^_Nullable)(NSArray<ACCImageAlbumExportItemModel *> *exportedItems))succeedBlock
                         onFaild:(void(^_Nullable)(NSInteger faildIndex))faildBlock;

@end

NS_ASSUME_NONNULL_END
