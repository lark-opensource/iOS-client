//
//  ACCBeautyService.h
//  CameraClient
//
//  Created by pengzhenhuan on 2020/12/22.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <AVFoundation/AVFoundation.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectViewModel.h>
#import "ACCBeautyPanelViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEComposerBeautyEffectWrapper;

@protocol ACCBeautyService <NSObject>
@property (nonatomic, assign) BOOL beautyOn;
@property (nonatomic, strong, readonly) AWEComposerBeautyEffectViewModel *effectViewModel;
@property (nonatomic, strong, readonly) ACCBeautyPanelViewModel *beautyPanelViewModel;

- (BOOL)isUsingBeauty;

- (void)updateAppliedFilter:(IESEffectModel *)filterModel;

- (void)cacheSelectedFilter:(NSString *)filterID
         withCameraPosition:(AVCaptureDevicePosition)cameraPosition;

- (void)syncFrontAndRearFilterId:(NSString *)filterId;

- (void)clearAllComposerBeautyEffects;

- (void)updateAvailabilityForEffectsInCategories:(NSArray *)categories;

- (void)applyComposerBeautyEffects:(NSArray <AWEComposerBeautyEffectWrapper *> *)effectWrappers;

- (void)clearComposerBeautyEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effectWrappers;

- (BOOL)isUsingLocalBeautyResource;

- (void)addAlgorithmCallbackForBeauty:(AWEComposerBeautyEffectWrapper *)beautyWrapper;

@optional
/// set all beauty sub item rotio = 0.f
- (void)updateBeautyAllSubItemZeroRatio;

/// a replace interface
- (void)replaceComposerBeautyWithNewEffects:(NSArray *)newEffects oldEffects:(NSArray *)oldEffects;

@end

NS_ASSUME_NONNULL_END
