//
//  ACCBeautyFeatureComponentView.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/1/17.
//

#import "ACCBeautyFeatureComponentView.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import "ACCBeautyManager.h"
#import "ACCBeautyComponentConfigProtocol.h"
#import <IESInject/IESInject.h>
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "ACCBeautyConfigKeyDefines.h"
#import <CreationKitArch/ACCRecorderToolBarDefines.h>


@interface ACCBeautyFeatureComponentView ()
@property (nonatomic, strong) UIView *redView;
@property (nonatomic, strong) ACCAnimatedButton *modernBeautyButton;

@property (nonatomic, strong) UILabel *modernLbl;
@property (nonatomic, strong) UILabel *switchLbl;
@property (nonatomic, strong) NSDictionary *referExtra;
@property (nonatomic, strong) id<ACCBeautyComponentConfigProtocol> config;
@end


@implementation ACCBeautyFeatureComponentView
@synthesize isBeautySwitchButtonSelected = _isBeautySwitchButtonSelected;

IESAutoInject(ACCBaseServiceProvider(), config, ACCBeautyComponentConfigProtocol);

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (instancetype)initWithModernBeautyButtonLabel:(UILabel *)modernLabel
                        beautySwitchButtonLabel:(UILabel *)switchLabel
                                     referExtra:(NSDictionary *)referExtra
{
    self = [super init];
    if (self) {
        _modernLbl = modernLabel;
        _switchLbl = switchLabel;
        _referExtra = referExtra;
    }
    return self;
}

#pragma mark - modernBeautyButtonWarpView

- (AWECameraContainerToolButtonWrapView *)modernBeautyButtonWarpView
{
    UILabel *buttonLabel;
    if (ACCConfigBool(kConfigBool_show_title_in_video_camera)) {
        buttonLabel = self.modernLbl;
    }

    AWECameraContainerToolButtonWrapView *wrapperView = [[AWECameraContainerToolButtonWrapView alloc] initWithButton:self.modernBeautyButton label:buttonLabel itemID:ACCRecorderToolBarModernBeautyContext];

    if (ACCConfigBool(kConfigBool_studio_record_beauty_icon_show_yellow_dot)) {
        [self showPointView];
    }

    return wrapperView;
}

- (ACCAnimatedButton *)modernBeautyButton
{
    if (!_modernBeautyButton) {
        _modernBeautyButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeScale];
        if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
            [ACCAccessibility() enableAccessibility:_modernBeautyButton
                                             traits:UIAccessibilityTraitButton
                                              label:ACCLocalizedCurrentString(@"filter_beautify")];
        }

        NSString* normalImageName = [self.config beautyIconName];

        [_modernBeautyButton setImage:ACCResourceImage(normalImageName) forState:UIControlStateNormal];

        if ([self.config canAddTargetForModernBeautyButton]) {
            [_modernBeautyButton addTarget:self action:@selector(clickBeautyButton:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            if (ACCConfigBool(kConfigBool_muse_beauty_panel)) {
                [_modernBeautyButton addTarget:self action:@selector(clickBeautyButton:) forControlEvents:UIControlEventTouchUpInside];
            } else {/* do nothing */}
        }
    }
    return _modernBeautyButton;
}

#pragma mark - beautySwitchButtonWarpView

- (AWECameraContainerToolButtonWrapView *)beautySwitchButtonWarpView
{
    UILabel *buttonLabel;
    if (ACCConfigBool(kConfigBool_show_title_in_video_camera)) {
        buttonLabel = self.switchLbl;
    }
    return [[AWECameraContainerToolButtonWrapView alloc] initWithButton:self.beautySwitchButton label:buttonLabel];
}

- (ACCAnimatedButton *)beautySwitchButton
{
    if (!_beautySwitchButton) {
        _beautySwitchButton = [[ACCAnimatedButton alloc] init];
        if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
            [ACCAccessibility() enableAccessibility:_beautySwitchButton
                                             traits:UIAccessibilityTraitButton
                                              label:_switchLbl.text];
        }
        if ([self.config needSetBeautyButtonImage]) {
            if (ACCConfigBool(kConfigBool_muse_beauty_panel) && ACCConfigBool(kConfigBool_mvp_beauty_icon)) {
                [_beautySwitchButton setImage:ACCResourceImage(@"icon_new_beauty") forState:UIControlStateNormal];

            } else {
                [_beautySwitchButton setImage:ACCResourceImage(@"iconBeautyOff2New") forState:UIControlStateNormal];
                [_beautySwitchButton setImage:ACCResourceImage(@"iconBeautyOn2New") forState:UIControlStateSelected];
            }
        } else {
            if (ACCConfigBool(kConfigBool_mvp_beauty_icon)) {
                [_beautySwitchButton setImage:ACCResourceImage(@"icon_new_beauty") forState:UIControlStateNormal];
            } else {
                [_beautySwitchButton setImage:ACCResourceImage(@"iconBeautyOff2New") forState:UIControlStateNormal];
                [_beautySwitchButton setImage:ACCResourceImage(@"iconBeautyOn2New") forState:UIControlStateSelected];
            }
        }

        if ([self.config useBeautySwitch]) {
            [_beautySwitchButton addTarget:self action:@selector(clickSwitchBeautyBtn:) forControlEvents:UIControlEventTouchUpInside];
        }
        _beautySwitchButton.selected = self.isBeautySwitchButtonSelected;
    }
    return _beautySwitchButton;
}

#pragma mark -  button action

- (void)clickBeautyButton:(UIButton *)sender
{
    [self hidePointView];

    if (self.delegate && [self.delegate respondsToSelector:@selector(modernBeautyButtonClicked:)]) {
        [self.delegate modernBeautyButtonClicked:sender];
    }
}

- (void)clickSwitchBeautyBtn:(UIButton *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(beautySwitchButtonClicked:)]) {
        [self.delegate beautySwitchButtonClicked:sender];
    }
}

#pragma mark - isBeautySwitchButtonSelected setter/getter

- (BOOL)isBeautySwitchButtonSelected
{
    return _isBeautySwitchButtonSelected;
}

- (void)setIsBeautySwitchButtonSelected:(BOOL)isBeautySwitchButtonSelected
{
    _isBeautySwitchButtonSelected = isBeautySwitchButtonSelected;
    _beautySwitchButton.selected = isBeautySwitchButtonSelected;
}


#pragma mark - redPoint

- (void)showPointView
{
    if ([ACCCache() boolForKey:[self cachePointViewKey]]) {
        return;
    }
    UIColor *color = ACCResourceColor(ACCColorLink);
    CGFloat radius = 2.5;
    CGPoint point = CGPointMake(self.modernBeautyButton.bounds.size.width - 2 * radius + 3, 2 * radius - 1);

    if (!self.redView) {
        UIView *redView = [[UIView alloc] initWithFrame:CGRectMake(point.x - radius, point.y - radius, radius * 2, radius * 2)];
        redView.backgroundColor = color;
        redView.layer.cornerRadius = radius;
        redView.clipsToBounds = YES;
        [self.modernBeautyButton addSubview:redView];
        self.redView = redView;
    } else {
        self.redView.frame = CGRectMake(point.x - radius, point.y - radius, radius * 2, radius * 2);
        self.redView.backgroundColor = color;
        self.redView.hidden = NO;
    }
}

- (void)hidePointView {
    if (!self.redView) {
        return;
    }else{
        [ACCCache() setBool:YES forKey:[self cachePointViewKey]];
        self.redView.hidden = YES;
    }
}

- (NSString *)cachePointViewKey
{
    return @"ACCBeautyFeatureComponent.modernBeautyButton.pointView.clicked";
}




@end
