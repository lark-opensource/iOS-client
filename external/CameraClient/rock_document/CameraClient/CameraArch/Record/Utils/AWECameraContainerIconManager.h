//
//  AWECameraContainerIconManager.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2019/1/8.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CreationKitArch/ACCStudioDefines.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWECameraContainerIconManager : NSObject

+ (UIImage *)selectMusicButtonNormalImage;
+ (UIImage *)selectMusicButtonLoadingImage;
+ (UIImage *)selectMusicButtonSelectedImage;

+ (UIImage *)duetLayoutButtonImage;

+ (UIImage *)beautyButtonNormalImage;
+ (UIImage *)beautyButtonSelectedImage;

+ (UIImage *)modernBeautyButtonImage;

+ (UIImage *)delayStartButtonImageWithMode:(AWEDelayRecordMode)mode;

+ (UIImage *)moreButtonImage;

+ (UIImage *)flashButtonAutoImage;
+ (UIImage *)flashButtonOnImage;
+ (UIImage *)flashButtonOffImage;

+ (UIImage *)reactMicButtonNormalImage;
+ (UIImage *)reactMicButtonSelectedImage;

@end

NS_ASSUME_NONNULL_END
