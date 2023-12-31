//
//  ACCGrootStickerHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/14.
//

#import "ACCStickerHandler.h"
#import "ACCStickerDataProvider.h"
#import "ACCGrootStickerView.h"
#import "ACCGrootStickerConfig.h"
#import "ACCGrootStickerViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCGrootStickerInputDelegate;
@class ACCGrootDetailsStickerModel;

@interface ACCGrootStickerHandler : ACCStickerHandler

@property (nonatomic, copy) void (^editViewOnStartEdit)(void);
@property (nonatomic, copy) void (^editViewOnFinishEdit)(BOOL autoAddGrootHashtag, ACCGrootStickerModel *, BOOL);
@property (nonatomic, copy) void (^willDeleteCallback)(void);
@property (nonatomic, copy, nullable) void (^onStickerApplySuccess)(void);
@property (nonatomic, copy, nullable) void (^selectModelCallback)(ACCGrootDetailsStickerModel *model);
@property (nonatomic, copy) void (^grootStickerConfirmCallback)(void);

- (instancetype)initWithDataProvider:(id<ACCGrootStickerDataProvider>)dataProvider
                        publishModel:(AWEVideoPublishViewModel *)publishModel viewModel:(ACCGrootStickerViewModel *)viewModel;

- (ACCGrootStickerView *)addGrootStickerWithModel:(nullable ACCGrootStickerModel *)model
                                      locationModel:(nullable AWEInteractionStickerLocationModel *)locationModel
                                   constructorBlock:(nullable void (^)(ACCGrootStickerConfig *))constructorBlock;

- (void)editTextStickerView:(ACCGrootStickerView *)stickerView;

- (BOOL)machingEditingGrootSticker;
- (BOOL)hasEditedGrootSticker;

@end

NS_ASSUME_NONNULL_END
