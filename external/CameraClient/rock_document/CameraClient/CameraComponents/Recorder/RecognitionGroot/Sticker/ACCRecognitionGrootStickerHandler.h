//
//  ACCRecognitionGrootStickerHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by Ryan Yan on 2021/8/23.
//

#import <Foundation/Foundation.h>

#import "ACCStickerHandler.h"
#import "ACCShootSameStickerHandlerProtocol.h"
#import "ACCRecognitionGrootStickerViewModel.h"
#import "ACCRecognitionGrootStickerViewFactory.h"
#import "ACCRecognitionGrootStickerView.h"

@class ACCRecognitionGrootStickerViewModel;
@protocol ACCStickerProtocol, ACCRecognitionService;

@interface ACCRecognitionGrootStickerHandler : ACCStickerHandler

@property (nonatomic, copy) void (^editViewOnStartEdit)(void);
@property (nonatomic, copy) void (^editViewOnFinishEdit)(void);
@property (nonatomic, copy) void (^willDeleteCallback)(void);

@property (nonatomic, weak, nullable) id<ACCRecognitionService> recognitionService;
@property (nonatomic, strong, readonly, nullable) ACCRecognitionGrootStickerView *stickerView;

- (instancetype)initWithGrootStickerViewModel:(nonnull ACCRecognitionGrootStickerViewModel *)viewModel
                                 viewWithType:(ACCRecognitionStickerViewType)viewType;

- (void)updateStickerViewByDetailStickerModel:(nonnull ACCGrootDetailsStickerModel *)detailStickerModel;

- (nullable ACCRecognitionGrootStickerView *)addGrootStickerWithModel:(nullable  ACCGrootStickerModel *)model;

- (void)removeGrootSticker;

- (void)editStickerView;

- (void)stopEditStickerView;

@end
