//
//  ACCBeautyComponentConfigProtocol.h
//  CameraClient
//
//  Created by Liu Deping on 2020/4/23.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/HTSFilterDefine.h>
#import <CreationKitBeauty/ACCBeautyDefine.h>

@class AWEComposerBeautyEffectCategoryWrapper, AWEComposerBeautyEffectWrapper;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCBeautyComponentConfigProtocol <NSObject>

- (BOOL)availableFilterBeautyWithCategoryWrapper:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper;

- (BOOL)needConfigAllBeautifyInfo;

- (BOOL)enableSetBeautySwitchButton;

- (BOOL)shouldReturnABBeautyValue;

- (BOOL)canHandleApplyStickerExtralCase;

- (BOOL)enableClearAllBeautyEffects;

- (BOOL)canApplyBeautify;

- (BOOL)canApplyBeautySmoothType;

- (BOOL)shouldAddBeautyParams;

- (BOOL)needSetBeautyButtonImage;

- (BOOL)canAddTargetForModernBeautyButton;

- (BOOL)useSavedValue;

- (BOOL)useBeautySwitch;

// replace condition `!ACC_IS_IN_MUSICALLY_REGION`
- (BOOL)shouldDisableBeautifyForSticker;

- (NSString *)beautyIconName;

@optional

- (NSString *)beautyPanelName;

@end

NS_ASSUME_NONNULL_END
