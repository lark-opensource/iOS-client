//
//  ACCFilterService.h
//  CameraClient-Pods-Aweme
//
//  Created by pengzhenhuan on 2020/12/22.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/IESEffectModel+ComposerFilter.h>
#import <CreationKitArch/AWEColorFilterConfigurationHelper.h>

@class RACSignal<__covariant ValueType>;
NS_ASSUME_NONNULL_BEGIN

@protocol ACCFilterService <NSObject>

@property (nonatomic, strong, readonly) RACSignal<IESEffectModel *> *showFilterNameSignal;
@property (nonatomic, strong, readonly) __kindof RACSignal *filterViewWillShowSignal;
@property (nonatomic, strong, readonly) __kindof RACSignal<NSNumber *> *applyFilterSignal;

@property (nonatomic, assign) BOOL hasDeselectionBeenMadeRecently;
@property (nonatomic, assign, getter=isPanGestureRecognizerEnabled) BOOL panGestureRecognizerEnabled;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, strong) IESEffectModel *currentFilter;
@property (nonatomic, assign, readonly) BOOL isUsingComposerFilter;

- (void)applyFilterForCurrentCameraWithShowFilterName:(BOOL)show sendManualMessage:(BOOL)sendManualMessage;

- (void)applyFilter:(nullable IESEffectModel *)filter withShowFilterName:(BOOL)show sendManualMessage:(BOOL)sendManualMessage;

- (void)applyFilterWithFilterID:(NSString *)filterID; // not show filter name, not send manual apply message

- (void)defaultFilterManagerUpdateEffectFilters;

@optional
- (void)storyFilterManagerUpdateEffectFilters;

@end

NS_ASSUME_NONNULL_END
