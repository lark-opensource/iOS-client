//
//  ACCTextStickerApplyHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/7/27.
//

#import <Foundation/Foundation.h>
#import "ACCStickerHandler.h"
#import "ACCStickerDataProvider.h"
#import <CreationKitArch/ACCStickerMigrationProtocol.h>
#import "ACCTextReaderSoundEffectsSelectionViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEStoryTextImageModel, ACCTextStickerConfig, AWEInteractionStickerLocationModel, ACCTextStickerView, ACCRepoImageAlbumInfoModel, AWEVideoPublishViewModel;


@interface ACCTextStickerHandler : ACCStickerHandler <ACCStickerMigrationProtocol, ACCTextReaderSoundEffectsSelectionViewControllerProviderProtocol>

@property (nonatomic, copy) void(^onTimeSelect)(ACCTextStickerView *);
@property (nonatomic, copy) void(^editViewOnStartEdit)(ACCTextStickerView *);
@property (nonatomic, copy) void(^editViewOnFinishEdit)(ACCTextStickerView *);
@property (nonatomic, copy) void(^onFinishedEditAnimationCompletedBlock)(void);
@property (nonatomic, copy, nullable) void(^onStickerApplySuccess)(void);
@property (nonatomic, weak) id<ACCTextStickerDataProvider> dataProvider;
@property (nonatomic, weak) ACCRepoImageAlbumInfoModel *repoImageAlbumInfo;
@property (nonatomic, weak) AWEVideoPublishViewModel *publishViewModel; // 之前的hashtag推荐service用来获取推荐数据
@property (nonatomic, assign) BOOL isImageAlbumEdit;
@property (nonatomic, strong) AWETextStickerStylePreferenceModel *stylePreferenceModel;

@property (nonatomic, copy) void(^panStart)(void);
@property (nonatomic, copy) void(^panEnd)(void);

- (__kindof ACCTextStickerView *)addTextWithTextInfo:(AWEStoryTextImageModel *)textModel locationModel:(nullable AWEInteractionStickerLocationModel *)locationModel constructorBlock:(nullable void (^)(ACCTextStickerConfig *config))constructorBlock;

/// @param preferredRatio default is NO
- (__kindof ACCTextStickerView *)addTextWithTextInfo:(AWEStoryTextImageModel *)textModel locationModel:(nullable AWEInteractionStickerLocationModel *)locationModel preferredRatio:(BOOL)preferredRatio constructorBlock:(nullable void (^)(ACCTextStickerConfig *config))constructorBlock;

- (UIView<ACCStickerProtocol> *)addTextWithTextInfoAndApply:(AWEStoryTextImageModel *)textModel locationModel:(nullable AWEInteractionStickerLocationModel *)locationModel index:(NSUInteger)idx;

- (void)editTextStickerView:(ACCTextStickerView *)stickerView;

- (void)requestTextReadingForStickerView:(ACCTextStickerView *)stickerView;

- (void)removeTextReadingForStickerView:(ACCTextStickerView *)stickerView;

- (void)textEditFinishedForStickerView:(ACCTextStickerView *)stickerView;

@end

NS_ASSUME_NONNULL_END
