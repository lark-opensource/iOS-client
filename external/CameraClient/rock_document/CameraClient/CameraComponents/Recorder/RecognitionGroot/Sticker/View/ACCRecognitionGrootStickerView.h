//
//  ACCRecognitionGrootStickerView.h
//  CameraClient-Pods-Aweme
//
//  Created by Ryan Yan on 2021/8/23.
//

#import <UIKit/UIKit.h>

#import <CameraClientModel/ACCVideoCommentModel.h>
#import "ACCStickerEditContentProtocol.h"
#import "ACCGrootStickerModel.h"
#import "ACCInteractionStickerFontHelper.h"

@class ACCRecognitionGrootStickerView;

@protocol ACCRecognitionGrootStickerViewDelegate <NSObject>

@optional
- (void)hitView:(nonnull ACCRecognitionGrootStickerView *)view;

@end

@interface ACCRecognitionGrootStickerView : UIView <ACCStickerEditContentProtocol>

@property (nonatomic, assign) CGFloat currentScale;
@property (nonatomic, weak  , nullable) id<ACCRecognitionGrootStickerViewDelegate> delegate;
@property (nonatomic, strong, nonnull) ACCGrootDetailsStickerModel *stickerModel;

- (void)configWithModel:(nullable ACCGrootDetailsStickerModel *)grootStickerModel;

- (UIFont *)getSocialFont:(CGFloat)fontSize retry:(NSInteger)retry;

- (void)transportToEditWithSuperView:(nonnull UIView *)superView
                           animation:(nullable void (^)(void))animationBlock
                   animationDuration:(CGFloat)duration;

- (void)restoreToSuperView:(nonnull UIView *)superView
         animationDuration:(CGFloat)duration
            animationBlock:(nullable void (^)(void))animationBlock
                completion:(nullable void (^)(void))completion;

@end
