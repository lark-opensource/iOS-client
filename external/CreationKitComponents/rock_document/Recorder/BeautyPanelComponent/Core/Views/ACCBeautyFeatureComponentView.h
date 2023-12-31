//
//  ACCBeautyFeatureComponentView.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/1/17.

#import <Foundation/Foundation.h>
#import "ACCBeautyPanel.h"
#import <CreationKitArch/AWECameraContainerToolButtonWrapView.h>
#import <CreativeKit/ACCAnimatedButton.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCBeautyFeatureComponentViewDelegate <NSObject>

- (void)modernBeautyButtonClicked:(UIButton *)sender;

- (void)beautySwitchButtonClicked:(UIButton *)sender;

- (void)beautyPanelDisplay;

- (void)beautyPanelDismiss;

@end


@interface ACCBeautyFeatureComponentView : NSObject
@property (nonatomic, assign) BOOL isBeautySwitchButtonSelected;// store beauty interaction status
@property (nonatomic,   weak) id<ACCBeautyFeatureComponentViewDelegate,AWEComposerBeautyDelegate> delegate;
@property (nonatomic, strong) ACCBeautyPanel *beautyPanel;

- (instancetype)initWithModernBeautyButtonLabel:(UILabel *)modernLabel
                        beautySwitchButtonLabel:(UILabel *)switchLabel
                                     referExtra:(NSDictionary *)referExtra;

- (AWECameraContainerToolButtonWrapView *)modernBeautyButtonWarpView;

- (AWECameraContainerToolButtonWrapView *)beautySwitchButtonWarpView;

- (void)showPointView;
- (void)hidePointView;

// inherit
@property (nonatomic, strong) ACCAnimatedButton *beautySwitchButton;
- (void)clickSwitchBeautyBtn:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
