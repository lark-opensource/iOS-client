//
//  AWEVideoGameCameraContainerView.h
//  AWEStudio
//
//  Created by lixingdong on 2018/8/15.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCAnimatedButton.h>

typedef void(^AWEVideoGameAppearCompletion)(void);

@interface AWEVideoGameCameraContainerView : UIView

@property (nonatomic, strong) ACCAnimatedButton *closeBtn;
@property (nonatomic, assign) BOOL isShowingForEffectControlGame;//Effect Control Games need to hide record button and transfer touch events.

- (void)showWithAnimated:(BOOL)animated completion:(AWEVideoGameAppearCompletion)completion;

- (void)dismissWithAnimated:(BOOL)animated completion:(AWEVideoGameAppearCompletion)completion;

@end
