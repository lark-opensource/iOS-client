//
//  ACCExposePropPanelViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/1/6.
//

#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreativeKit/ACCViewModel.h>
#import "ACCPropPickerView.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCPropPickerItem.h"
#import "ACCStickerGroupedApplyPredicate.h"
#import "ACCHotPropDataManager.h"
#import "AWEStickerPickerControllerFavoritePlugin.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCameraService;

@interface ACCRecognitionPropPanelViewModel : ACCRecorderViewModel <ACCPropPickerViewDelegate, ACCPropFavoriteObserverProtocol>

@property (nonatomic, copy, readonly) NSArray<ACCPropPickerItem *> *propPickerDataList;

@property (nonatomic, strong, readonly) ACCPropPickerItem *selectedItem;
@property (nonatomic, strong, readonly) RACSignal<RACTwoTuple<ACCPropPickerItem *, NSNumber *> *> *selectItemSignal; // tuple of item and whether should with an animation

@property (nonatomic, strong, readonly) RACSignal<RACTwoTuple<NSNumber *, NSNumber *> *> *downloadProgressSignal;

@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *enableCaptureSignal;
@property (nonatomic, strong, readonly) RACSignal *captureFocusSignal;

@property (nonatomic, strong, readonly) RACSignal<IESEffectModel *> *propSelectionSignal;
@property (nonatomic, strong, readonly) RACSignal<NSString *> *showPropPickerTabSignal; // show Prop Picker Panel and switch tab

//@property (nonatomic, assign) BOOL isShowingPropPickerPanel;
@property (nonatomic, assign) BOOL isShowingPanel;

@property (nonatomic, copy, nullable) id<ACCCameraService> (^cameraServiceBlock)(void);

@property (nonatomic, strong, nullable) ACCPropPickerItem *homeItem;

- (void)applyFirstHot;
- (void)applyFirstRecognition;

#pragma mark - Favor
@property (nonatomic, assign, readonly) BOOL favorStatus;
- (void)changeFavorStatus;
//- (BOOL)isFavorItemSelected;

- (void)fetchHotDataIfNeeded;
- (void)fetchFavoriteEffectsIfNeed;
- (void)updatePropPickerItems;
- (void)updateFavoriteEffects:(NSArray<IESEffectModel *> *)favoriteEffects;

- (void)selectRecognitionWithEffectModel:(IESEffectModel *)effectModel;
- (void)selectHotWithEffectModel:(IESEffectModel *)effectModel;

- (void)cancelPropSelection;

//- (void)onCaptureFocus;

@end

NS_ASSUME_NONNULL_END
