//
//  AWEStickerHintView.h
//  AWEStudio
//
//  Created by guochenxiang on 2018/7/23.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IESEffectModel;

typedef void(^ACCStickerHintViewShowCompletion)(BOOL isShowing);
typedef void(^ACCDuetGreenScreenHintViewCompletion)(void);

@interface AWEStickerHintView : UIView

@property (nonatomic, assign) BOOL isShowing;

@property (nonatomic, copy, nullable) ACCStickerHintViewShowCompletion hintViewShowBlock;

@property (nonatomic, copy, nullable) ACCDuetGreenScreenHintViewCompletion duetGreenScreenHintViewCompletionBlock;

- (void)showWithTitle:(NSString *)title;

- (void)showWithTitleRepeat:(NSString *)title;

- (void)showWithEffect:(IESEffectModel *)model;

- (void)showPhotoSensitiveWithEffect:(IESEffectModel *)model;

- (void)removePhotoSensitiveHint;

- (void)remove;

- (void)stopGifTipsAnimation;

- (void)stopLottieTipsAnimation;

@end
