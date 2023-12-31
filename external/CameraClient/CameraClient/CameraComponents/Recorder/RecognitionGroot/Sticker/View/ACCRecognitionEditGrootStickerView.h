//
//  ACCRecognitionEditGrootStickerView.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/31.
//

#import <UIKit/UIKit.h>
#import "ACCRecognitionGrootStickerView.h"

@interface ACCRecognitionEditGrootStickerView : UIView

@property (nonatomic, strong, readonly, nullable) ACCRecognitionGrootStickerView *grootStickerView;

@property (nonatomic, copy, nullable) void (^onEditFinishedBlock)(ACCRecognitionGrootStickerView *stickerView);
@property (nonatomic, copy, nullable) void (^finishEditAnimationBlock)(ACCRecognitionGrootStickerView *stickerView);
@property (nonatomic, copy, nullable) void (^startEditBlock)(ACCRecognitionGrootStickerView *stickerView);

- (void)startEditStickerView:(ACCRecognitionGrootStickerView *_Nonnull)stickerView;

- (void)stopEdit;

@end
