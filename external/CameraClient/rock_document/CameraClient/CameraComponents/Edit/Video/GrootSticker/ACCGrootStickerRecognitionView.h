//
//  ACCGrootStickerRecognitionView.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/14.
//

#import <UIKit/UIKit.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCGrootStickerView.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCGrootDetailsStickerModel;

@interface ACCGrootStickerRecognitionView : UIView

@property (nonatomic, strong, readonly) ACCGrootStickerView *grootStickerView;
@property (nonatomic, copy) void (^onEditFinishedBlock)(ACCGrootStickerView *stickerView);
@property (nonatomic, copy) void (^finishEditAnimationBlock)(ACCGrootStickerView *stickerView, BOOL autoAddGrootHashTag, NSDictionary *trackInfo);
@property (nonatomic, copy) void (^startEditBlock)(ACCGrootStickerView *stickerView);
@property (nonatomic, copy) void (^selectModelCallback)(ACCGrootDetailsStickerModel *model);
@property (nonatomic, copy) void (^confirmCallback)(void);


+ (instancetype)editViewWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

- (void)startEditStickerView:(ACCGrootStickerView *_Nonnull)stickerView;

@end

NS_ASSUME_NONNULL_END
