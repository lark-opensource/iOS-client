//
//  ACCTapticEngineManager.m
//  CameraClient
//
// Created by Xiong Dian on November 10, 2017
//  Copyright  ©  Byedance. All rights reserved, 2017
//

#import "ACCTapticEngineManager.h"
#import <UIKit/UIKit.h>

@interface ACCTapticEngineManager()

@property (nonatomic, strong) UISelectionFeedbackGenerator *selectionFeedback NS_AVAILABLE_IOS(10_0);
@property (nonatomic, strong) UINotificationFeedbackGenerator *notificationFeedback NS_AVAILABLE_IOS(10_0);

@end

@implementation ACCTapticEngineManager

+ (instancetype)sharedManager
{
    static ACCTapticEngineManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (UISelectionFeedbackGenerator *)selectionFeedback
{
    if (!_selectionFeedback) {
        _selectionFeedback = [[UISelectionFeedbackGenerator alloc] init];
    }
    return _selectionFeedback;
}

- (UINotificationFeedbackGenerator *)notificationFeedback
{
    if (!_notificationFeedback) {
        _notificationFeedback = [[UINotificationFeedbackGenerator alloc] init];
    }
    return _notificationFeedback;
}

+ (void)tap
{
    if (@available(iOS 10.0, *)) {
        [[ACCTapticEngineManager sharedManager].selectionFeedback selectionChanged];
    }
}

+ (void)notifySuccess
{
    if (@available(iOS 10.0, *)) {
        [[ACCTapticEngineManager sharedManager].notificationFeedback notificationOccurred:UINotificationFeedbackTypeSuccess];
    }
}

+ (void)notifyFailure
{
    if (@available(iOS 10.0, *)) {
        [[ACCTapticEngineManager sharedManager].notificationFeedback notificationOccurred:UINotificationFeedbackTypeError];
    }
}

+ (void)notifyWarning
{
    if (@available(iOS 10.0, *)) {
        [[ACCTapticEngineManager sharedManager].notificationFeedback notificationOccurred:UINotificationFeedbackTypeWarning];
    }
}

@end
