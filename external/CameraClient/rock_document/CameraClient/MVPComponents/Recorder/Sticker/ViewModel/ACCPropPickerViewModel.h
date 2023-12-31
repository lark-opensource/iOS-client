//
//  ACCPropPickerViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/1/10.
//

#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;
extern NSString *const ACCPropPickerHotTab;
extern NSString *const ACCPropPickerFavorTab;

@interface ACCPropPickerViewModel : ACCRecorderViewModel

@property (nonatomic, strong, readonly) RACSignal<NSString *> *showPanelSignal;
@property (nonatomic, strong, readonly) RACSignal<IESEffectModel *> *exposePanelPropSelectionSignal;
@property (nonatomic, strong, readonly) RACSignal<NSArray<IESEffectModel *> *> *sendFavoriteEffectsSignal;

@property (nonatomic, assign) BOOL isExposePanelShowFavor;

- (void)showPanelFromTab:(nullable NSString *)tab;
- (void)selectPropFromExposePanel:(IESEffectModel *)prop;
- (void)sendFavoriteEffectsForRecognitionPanel:(nullable NSArray<IESEffectModel *> *)favoriteEffects;

@end

NS_ASSUME_NONNULL_END
