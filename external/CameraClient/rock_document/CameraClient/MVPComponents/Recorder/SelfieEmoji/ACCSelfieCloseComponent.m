//
//  ACCSelfieCloseComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by liujingchuan on 2021/8/29.
//

#import "ACCSelfieCloseComponent.h"
#import "ACCSelfieCloseComponentService.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@interface ACCSelfieCloseComponent()

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCSelfieCloseComponentService> closeServiceImpl;

@end

@implementation ACCSelfieCloseComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, closeServiceImpl, ACCSelfieCloseComponentService)

- (void)loadComponentView {
    UIImage *image = ACCResourceImage(@"ic_titlebar_close_white");
    [self.closeButton setImage:image forState:UIControlStateNormal];
    [self.viewContainer.rootView addSubview:self.closeButton];
    [self.closeButton addTarget:self action:@selector(clickCloseBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.closeButton.superview bringSubviewToFront:self.closeButton];
}

- (void)componentDidMount {
    [self loadComponentView];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase {
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)clickCloseBtn:(UIButton *)btn {
    [self.closeServiceImpl didClickCloseBtn:btn];
    [self.controller close];
}


- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(16, ACC_STATUS_BAR_NORMAL_HEIGHT + 30, 24, 24)];
        _closeButton.accessibilityTraits = UIAccessibilityTraitButton;
        _closeButton.accessibilityLabel = @"关闭";
    }
    return _closeButton;
}


@end
