//
//  AWERecordFilterViewControllerDelegate.h
//  AWEStudio
//
//Created by Hao Yipeng on February 9, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#ifndef AWERecordFilterViewControllerDelegate_h
#define AWERecordFilterViewControllerDelegate_h

@class IESEffectModel, AWEColorFilterConfigurationHelper, IESCategoryModel;

@protocol AWERecordFilterVCDelegate <NSObject>

@required

- (void)applyFilter:(IESEffectModel *)item;
- (void)applyFilter:(IESEffectModel *)item indensity:(float)indensity;
- (float)filterIndensity:(IESEffectModel *)item;
- (AWEColorFilterConfigurationHelper *)currentFilterHelper;
- (BOOL)enableFilterIndensity;

@optional

///The value of the slider is actually the value of colorfilterintensityratio in publishviewmodel in the original video logic, not the value applied to VE
///The selected value of the slider will be converted into ve index through a series of transformations, and then the value of the slider will be stored in a helper. For details, please refer to the geteffectintensitywithdefault I of awecolorfilterconfiguration helper ndensity:Ratio
///Because each image doesn't share a filter in atlas mode, this method can't work, so callback will go back to its own storage
- (void)onUserSlideIndensityValueChanged:(CGFloat)sliderIndensity;

// track use
- (void)didClickedCategory:(IESCategoryModel *)category;
- (void)didClickedFilter:(IESEffectModel *)item;

@end

#endif /* AWERecordFilterViewControllerDelegate_h */
