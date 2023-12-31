//
//  ACCImageAlbumStickerServiceImpl.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/25.
//

#import <Foundation/Foundation.h>
#import "ACCStickerServiceProtocol.h"

@class AWEVideoPublishViewModel, ACCImageAlbumItemModel, ACCStickerContainerView;
@protocol ACCEditServiceProtocol,ACCEditViewContainer;

NS_ASSUME_NONNULL_BEGIN

@interface ACCImageAlbumStickerServiceImpl : NSObject<ACCStickerServiceProtocol>

@property (nonatomic, copy) ACCStickerContainerView *(^stickerContainerLoader)(void);

@property (nonatomic, weak, nullable) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;

- (void)finish;

- (void)setStickersForPublish;

- (void)addInteractionStickerInfosForImageItem:(ACCImageAlbumItemModel *)item inContainer:(ACCStickerContainerView *)containerView;

- (void)startQuickTextInput;

// 自渲染贴纸（例如 POI）在点击下一步的时候会将贴纸渲染到播放器内部，从发布页返回的时候会调用
// 此方法来移除播放器内部的贴纸特效，否则将会出现两个同样的贴纸（一个是自渲染视图，一个是播放器内部特效）
- (void)resetStickerInPlayer;

- (void)resetStickerContainer;

- (BOOL)shouldDismissInPreviewMode:(id)typeId;

@end

NS_ASSUME_NONNULL_END
