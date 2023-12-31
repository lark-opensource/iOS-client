//
//  AWERecordLoadingView.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/3/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CreationKitArch/ACCStudioDefines.h>

@interface AWERecordLoadingMaskView : UIView

@end

@interface AWERecordLoadingView : UIView

- (instancetype)initWithFrame:(CGRect)frame animationCompletion:(void(^)(void))animationCompletion;
- (instancetype)initWithFrame:(CGRect)frame
              delayRecordMode:(AWEDelayRecordMode)isShortDelay
          animationCompletion:(void (^)(void))animationCompletion;

@end
