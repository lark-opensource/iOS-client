//
//  AWECameraPreviewContainerView.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/3.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWECameraPreviewContainerView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCLogProtocol.h>

#import <TTVideoEditor/VERecorder.h>

typedef NS_ENUM(NSInteger, ACCTouchStateType) {
    ACCTouchStateTypeBegin = 0,
    ACCTouchStateTypeMoved = 1,
    ACCTouchStateTypeEnd = 2,
    ACCTouchStateTypeCancelled = 3,
};

@implementation AWECameraPreviewContainerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.multipleTouchEnabled = YES;
        self.enableInteraction = YES;
        self.shouldHandleTouch = YES;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.enableInteraction) {
        return;
    }
    
    [super touchesBegan:touches withEvent:event];

    if (!self.camera.config.enableTapFocus && !self.camera.config.enableTapexposure && self.shouldHandleTouch) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:touch.view];
        location = CGPointMake(location.x / touch.view.acc_width, location.y / touch.view.acc_height);
        [self.camera handleTouchEvent:location];
    }
    [self p_handleTouchs:touches withEvent:event touchType:ACCTouchStateTypeBegin];
}

- (void)p_handleTouchs:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event touchType:(ACCTouchStateType)type
{
    for (UITouch* touch in event.allTouches) {
        VETouchInfo touchInfo = {};
        touchInfo.touchId = (unsigned int)[touch hash];;
        UIView *view = self;
        CGPoint location = [view convertPoint:[touch locationInView:touch.view] fromView:touch.view];

        CGFloat width = view.acc_width;
        CGFloat height = view.acc_height;
        CGFloat screenRatio = 9.0f / 16.0f;
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            screenRatio = 16.0f / 9.0f;
        }
        CGFloat widthHeightRatio = width / height;

        if (isnan(widthHeightRatio) || isinf(widthHeightRatio)) {
            AWELogToolError2(@"handleTouches", AWELogToolTagNone, @"unexpected width / height is nan or inf.");
            return;
        }

        if (widthHeightRatio > screenRatio) {
            CGFloat newHeight = width / screenRatio;
            CGFloat diff = (newHeight - height) * 0.5;
            height = newHeight;
            location.y += diff;
        } else if (widthHeightRatio < screenRatio) {
            CGFloat newWidth = height * screenRatio;
            CGFloat diff = (newWidth - width) * 0.5;
            width = newWidth;
            location.x += diff;
        } else {
            // do nothing
        }

        location.x = location.x / width;
        location.y = location.y / height;

        touchInfo.touchPoint = location;
        touchInfo.majorRadius = (float)touch.majorRadius;
        touchInfo.tapCount = (int)event.allTouches.count; //(int)touch.tapCount;
        touchInfo.phase = touch.phase; // or replace with concrete phase in each touchesXXX callback
        if (@available(iOS 9.0, *)) {
            touchInfo.force = (float)touch.force; // 1.0 when lower than ios9
        } else {
            touchInfo.force = 1.0;
        }
        [self.camera updateTouchInfoForGestureRecognition:touchInfo];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.enableInteraction) {
        return;
    }
    
    [super touchesMoved:touches withEvent:event];
    [self p_handleTouchs:touches withEvent:event touchType:ACCTouchStateTypeMoved];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.enableInteraction) {
        return;
    }
    
    [super touchesEnded:touches withEvent:event];
    [self p_handleTouchs:touches withEvent:event touchType:ACCTouchStateTypeEnd];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.enableInteraction) {
        return;
    }
    
    [super touchesCancelled:touches withEvent:event];
    [self p_handleTouchs:touches withEvent:event touchType:ACCTouchStateTypeCancelled];
}

@end
