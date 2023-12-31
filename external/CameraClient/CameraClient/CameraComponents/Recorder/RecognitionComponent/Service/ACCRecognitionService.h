//

//  ACCRecognitionService.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/6.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCRecorderProtocol.h>
#import <CameraClient/ACCRecognitionEnumerate.h>
#import <CameraClient/ACCRecordPropService.h>
#import "ACCScanService.h"

@class ACCRecordViewControllerInputData;
@class ACCHotPropDataManager;
@class IESMMEffectMessage;
@class IESEffectModel;
@class ACCRecognitionTrackModel;
@class SSRecommendResult;
@protocol ACCCameraService;
@class ACCRecordMode;
@class RACTwoTuple<__covariant First, __covariant Second>;
@class RACSignal<__covariant ValueType>;
@class IESEffectModel;
@protocol ACCKaraokeService;
@protocol ACCFlowerService;


FOUNDATION_EXPORT NSString * const kACCRecogEnterMethodLongPress;
FOUNDATION_EXPORT NSString * const kACCRecogEnterMethodIconClick;
FOUNDATION_EXPORT NSString * const kACCRecogEnterMethodFlowerPanelAuto;
FOUNDATION_EXPORT NSString * const kACCRecogEnterMethodFlowerPanelLongPress;


@protocol ACCRecognitionService

@property (nonatomic, assign, readonly) ACCRecognitionState recognitionState;
@property (nonatomic, assign, readonly) ACCRecognitionRecorderState recordState;

@property (nonatomic, strong, readonly) ACCRecordViewControllerInputData *inputData;
@property (nonatomic, strong, readonly) IESMMEffectMessage *recognitionMessage;
@property (nonatomic, strong, readonly) ACCHotPropDataManager *dataManager;

@property (nonatomic, copy, readonly, nullable) NSString *currentDetectModeStr;
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *currentDetectModeArray;
@property (nonatomic, assign, readonly) ACCRecognitionDetectResult detectResult;
@property (nonatomic, strong, readonly, nullable) RACSignal<RACTwoTuple<SSRecommendResult *, NSString *> *> *recognitionResultSignal;
@property (nonatomic, strong, readonly) RACSignal *recognitionEffectsSignal;
@property (nonatomic, strong, readonly) RACSignal *disableRecognitionSignal;
@property (nonatomic, strong, readonly) RACSignal *hiddenSwitchModeSignal;
/// outer
@property (nonatomic,   weak) id<ACCCameraService> cameraService;
@property (nonatomic,   weak) id<ACCRecordPropService> propService;
@property (nonatomic,   weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic,   weak, nullable) id<ACCScanService> scanService;
@property (nonatomic,   weak, nullable) id<ACCFlowerService> flowerService;

@property (nonatomic, assign, readonly) BOOL disableRecognize;

@property (nonatomic, strong, readonly) ACCRecognitionTrackModel *trackModel;

/// 'BUGFIX': record's recordState is uncorrect(not accurate, actually), normal state is never used
/// maintain a accurate state to indicate the real record state.
- (void)updateRecordState:(ACCRecognitionRecorderState)state;
- (void)updateRecordMode:(ACCRecordMode *)mode;
- (void)enterDisablePage:(BOOL)enter;  /// enter some record page not supported, like karaoke
- (void)askingHideSwithModeView:(BOOL)hidden;

///
- (void)startAutoScanWithFilter:(ACCRecognitionFilterBlock)filter completion:(ACCRecognitionBlock)completion;
- (void)stopAutoScan;
- (void)releaseScanner;
- (void)willRelease;

@property (nonatomic, strong) IESEffectModel *stashedEffect; /// for recovery
- (void)recoverRecognitionStateIfNeeded;
- (BOOL)shouldShowSwitchMode;

/// start capture and recognition, result will callback by recognitionCallback
/// @param enter enter method, for tracking(read ACCRecognitionTrackModel for more detail)
/// @param detectType which ability to enable
- (void)captureImagesAndRecognize:(NSString *)enter detectMode:(NSString * _Nullable)detectMode;

- (BOOL)isReadyForRecognition;
/// stop recognizing or clear current recognized result (reset state to normal, actually)
- (void)resetRecognition;

- (void)updateMessage:(IESMMEffectMessage *)message;

- (BOOL)shouldShowBubble:(ACCRecognitionBubble)bubble;
- (void)markShowedBubble:(ACCRecognitionBubble)bubble;

- (double)thresholdFor:(ACCRecognitionThreashold)threshold;

/// for fixing some effect trigger auto popup prop panel issue
/// effects from recognition forbid this behaviour
- (void)applyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource;

- (void)updateTrackModel;

@end
