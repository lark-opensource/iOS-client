//
//  AWECameraPreviewContainerView.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/3.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTVideoEditor/VERecorder.h>

@interface AWECameraPreviewContainerView : UIView

@property (nonatomic, assign) BOOL enableInteraction;

@property (nonatomic, assign) BOOL shouldHandleTouch;

@property (nonatomic, weak) id<VERecorderPublicProtocol> camera;

@end
