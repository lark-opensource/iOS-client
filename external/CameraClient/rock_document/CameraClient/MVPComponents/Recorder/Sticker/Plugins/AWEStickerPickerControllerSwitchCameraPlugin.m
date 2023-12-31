//
//  AWEStickerPickerControllerSwitchCameraPlugin.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/10/19.
//

#import "AWEStickerPickerControllerSwitchCameraPlugin.h"
#import <CreationKitArch/AWECameraContainerToolButtonWrapView.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitInfra/ACCToastProtocol.h>

#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIView+AWEStudioAdditions.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CameraClient/ACCCameraSwapService.h>

#import "ACCKaraokeService.h"

@interface AWEStickerPickerControllerSwitchCameraPlugin () <ACCKaraokeServiceSubscriber, ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong) AWECameraContainerToolButtonWrapView *cameraButtonWrapView;

@property (nonatomic, strong) UIButton *cameraButton;

@property (nonatomic, weak) id<ACCCameraSwapService> cameraSwapService;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;

@end

@implementation AWEStickerPickerControllerSwitchCameraPlugin

- (instancetype)initWithServiceProvider:(id<IESServiceProvider>)serviceProvider
{
    self = [super init];
    if (self) {
        _cameraSwapService = IESAutoInline(serviceProvider, ACCCameraSwapService);
        _karaokeService = IESOptionalInline(serviceProvider, ACCKaraokeService);
        [_karaokeService addSubscriber:self];
        _switchModeService = IESAutoInline(serviceProvider, ACCRecordSwitchModeService);
        [_switchModeService addSubscriber:self];
    }
    return self;
}

- (void)controllerViewDidLoad:(AWEStickerPickerController *)controller
{
    [controller.view addSubview:self.cameraButtonWrapView];
    
    CGFloat rightSpacing = 2;
    CGFloat featureViewHeight = 48;
    CGFloat featureViewWidth = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 48.0 : 52;
    CGFloat buttonSpacing = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 2.0 : 14.0;
    CGFloat buttonHeightWithSpacing = featureViewHeight + buttonSpacing;
    
    CGRect tempFrame = CGRectMake(6, 20, featureViewWidth, featureViewHeight);
    if ([UIDevice acc_isIPhoneX]) {
        if (@available(iOS 11.0, *)) {
            tempFrame = CGRectMake(6, ACC_STATUS_BAR_NORMAL_HEIGHT + 20, featureViewWidth, featureViewHeight);
        }
    }
    
    CGFloat topOffset = tempFrame.origin.y + 6.0;//6 is back button's image's edge
    CGFloat shift = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 3 : 0;
    self.cameraButtonWrapView.frame = CGRectMake(ACC_SCREEN_WIDTH - rightSpacing - featureViewWidth + shift, topOffset, self.cameraButtonWrapView.acc_width, buttonHeightWithSpacing);
    
    
    [self p_enableCameraButtonForSticker:controller.model.currentSticker];
    [self p_configCameraSwapButtonAccessiblity];
}

- (void)controller:(AWEStickerPickerController *)controller didSelectNewSticker:(IESEffectModel *)newSticker oldSticker:(IESEffectModel *)oldSticker
{
    [self p_enableCameraButtonForSticker:newSticker];
}

- (void)controller:(AWEStickerPickerController *)controller willShowOnView:(UIView *)view
{
    self.cameraButtonWrapView.hidden = YES;
}

- (void)controller:(AWEStickerPickerController *)controller didShowOnView:(UIView *)view
{
    [self updateCameraSwapButtonVisibility];
}

- (void)controller:(AWEStickerPickerController *)controller willDimissFromView:(UIView *)view
{
    self.cameraButtonWrapView.hidden = YES;
}
// xiafeiyutodo why hidden = NO when dismissed ?
- (void)controller:(AWEStickerPickerController *)controller didDismissFromView:(UIView *)view
{
    [self updateCameraSwapButtonVisibility];
}

- (void)cameraButtonPressed:(UIButton *)button
{
    BOOL shouldSwitchPosition = button.alpha == 1.0;
    if (shouldSwitchPosition) {
        [button acc_counterClockwiseRotate];
        if( ACCConfigBool(kConfigInt_enable_camera_switch_haptic)){
            if(@available(ios 10.0, *)){
                UISelectionFeedbackGenerator *selection = [[UISelectionFeedbackGenerator alloc] init];
                [selection selectionChanged];
            }
        }

        [self.cameraSwapService switchToOppositeCameraPositionWithSource:ACCCameraSwapSourcePropPanel];
        [self p_configCameraSwapButtonAccessiblity];
    } else {
        ACCBLOCK_INVOKE(button.acc_disableBlock);
    }
}

- (UIButton *)cameraButton
{
    if (!_cameraButton) {
        _cameraButton = [[UIButton alloc] init];
        _cameraButton.exclusiveTouch = YES;
        _cameraButton.adjustsImageWhenHighlighted = NO;
        [_cameraButton setImage:[self swapCameraButtonImage] forState:UIControlStateNormal];
        [_cameraButton addTarget:self
                          action:@selector(cameraButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
        _cameraButton.accessibilityLabel = ACCLocalizedCurrentString(@"reverse");
    }
    return _cameraButton;
}

- (AWECameraContainerToolButtonWrapView *)cameraButtonWrapView
{
    if (!_cameraButtonWrapView) {
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [ACCFont() acc_boldSystemFontOfSize:10];
        label.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        label.textAlignment = NSTextAlignmentCenter;
        label.text = ACCLocalizedCurrentString(@"reverse");
        label.numberOfLines = 2;
        [label acc_addShadowWithShadowColor:ACCResourceColor(ACCUIColorConstLinePrimary) shadowOffset:CGSizeMake(0, 1) shadowRadius:2];
        label.isAccessibilityElement = NO;
        _cameraButtonWrapView = [[AWECameraContainerToolButtonWrapView alloc] initWithButton:self.cameraButton label:label itemID:ACCRecorderToolBarSwapContext];
    }
    return _cameraButtonWrapView;
}

- (UIImage *)swapCameraButtonImage
{
    return ACCResourceImage(@"ic_camera_filp");
}

- (void)p_enableCameraButtonForSticker:(IESEffectModel *)sticker
{
    // AR类道具禁止切换前后置摄像头
    if ([sticker isTypeAR]) {
        self.cameraButtonWrapView.alpha = 0.5;
        self.cameraButton.acc_disableBlock = ^{
            [ACCToast() show: ACCLocalizedString(@"record_artext_disable_front_camera", @"AR类道具仅支持后置摄像头")];
        };
    } else {
        self.cameraButtonWrapView.alpha = 1.0;
        self.cameraButton.acc_disableBlock = nil;
    }
}

- (void)updateCameraSwapButtonVisibility
{
    self.cameraButtonWrapView.hidden = self.karaokeService.inKaraokeRecordPage && self.karaokeService.recordMode == ACCKaraokeRecordModeAudio;
    [self p_configCameraSwapButtonAccessiblity];
}

#pragma mark - Accessiblity

- (void)p_configCameraSwapButtonAccessiblity
{
    [self.cameraSwapService syncCameraActualPosition];
    BOOL isFront = self.cameraSwapService.currentCameraPosition == AVCaptureDevicePositionFront;
    self.cameraButton.accessibilityLabel = isFront ? @"摄像头已前置,点击翻转" : @"摄像头已后置,点击翻转";
}

#pragma mark - ACCKaraokeServiceSubscriber

- (void)karaokeService:(id<ACCKaraokeService>)service recordModeDidChangeFrom:(ACCKaraokeRecordMode)prevMode to:(ACCKaraokeRecordMode)mode
{
    [self updateCameraSwapButtonVisibility];
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    [self updateCameraSwapButtonVisibility];
}

@end
