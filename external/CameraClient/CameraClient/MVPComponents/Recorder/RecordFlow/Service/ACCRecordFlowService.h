//
//  ACCRecordFlowService.h
//  Pods
//
//  Created by liyingpeng on 2020/6/23.
//

#import <CreationKitArch/HTSVideoDefines.h>
#import <CreationKitArch/AWESwitchRecordModelDefine.h>
#import <CreationKitInfra/ACCRACWrapper.h>

#import <CoreMedia/CMTime.h>

#ifndef ACCRecordFlowService_h
#define ACCRecordFlowService_h

typedef NS_ENUM(NSUInteger, ACCRecordFlowState) {
    ACCRecordFlowStateNormal = 0,
    ACCRecordFlowStateStart,
    ACCRecordFlowStatePause,
    ACCRecordFlowStateStop,
    ACCRecordFlowStateFinishExport,
};

@protocol ACCRecordFlowService, ACCLivePhotoConfigProtocol, ACCLivePhotoResultProtocol;
@class AWEPictureToVideoInfo, AWEVideoFragmentInfo, ACCRecordMode;
@class HTSVideoData;

@protocol ACCRecordFlowServiceSubscriber <NSObject>
@optional

- (void)flowServiceStateDidChanged:(ACCRecordFlowState)state preState:(ACCRecordFlowState)preState;

- (void)flowServiceDidUpdateDuration:(CGFloat)duration;
- (void)flowServiceDidMarkDuration:(CGFloat)duration;
- (void)flowServiceDidRemoveLastSegment:(BOOL)isReactHasMerge;
- (void)flowServiceDidAddPictureToVideo:(AWEPictureToVideoInfo *)pictureToVideo;
- (void)flowServiceDidAddFragment:(AWEVideoFragmentInfo *)fragment;
- (void)flowServiceDidRemoveAllSegment;
- (void)flowServiceDurationHasRestored;

- (void)flowServiceWillBeginTakePicture;
- (void)flowServiceDidTakePicture:(UIImage *)image error:(NSError *)error;

- (void)flowServiceWillBeginLivePhoto;
- (void)flowServiceWillCompleteLivePhotoWithConfig:(id<ACCLivePhotoConfigProtocol>)config;
- (void)flowServiceDidCompleteLivePhoto:(id<ACCLivePhotoResultProtocol>)data error:(NSError *)error;
- (void)flowServiceDidStepLivePhotoWithConfig:(id<ACCLivePhotoConfigProtocol>)config index:(NSInteger)index total:(NSInteger)total expectedTotal:(NSInteger)expectedTotal;

- (BOOL)flowServcieShouldStartRecord:(BOOL)isDelayRecord;

- (void)flowServiceDidCompleteRecord;

- (void)flowServiceWillEnterNextPageWithMode:(ACCRecordMode *)mode;
- (void)flowServiceDidEnterNextPageWithMode:(ACCRecordMode *)mode;


- (void)flowServiceTurnOnPureMode;
- (void)flowServiceTurnOffPureMode;

@end

@protocol ACCRecordFlowService <NSObject>

@property (nonatomic, assign) HTSVideoSpeed selectedSpeed;
@property (nonatomic, assign) BOOL isFirstDuration;
@property (nonatomic, assign, getter=isExporting) BOOL exporting;
@property (nonatomic, assign) CGFloat currentDuration; // 单位 s
@property (nonatomic, assign) NSTimeInterval lastCapturedVideoDuration;
@property (nonatomic, assign) NSTimeInterval reactLastCapturedVideoDuration;
@property (nonatomic, assign) AWERecordModeMixSubtype mixSubtype;
@property (nonatomic, assign) BOOL hasStopCaptureWhenEnterEdit;
@property (nonatomic, assign) BOOL isDelayRecord;

@property (nonatomic, assign, readonly) NSUInteger videoSegmentsCount;
@property (nonatomic, assign, readonly) ACCRecordFlowState flowState;
@property (nonatomic, strong, readonly) NSMutableArray *markedTimes;
@property (nonatomic, copy) NSTimeInterval(^totalDurationCalculator)(HTSVideoData *);
@property (nonatomic, copy) void(^segmentDurationEnumerator)(HTSVideoData *, void(^)(CMTime));

// segment operation
- (NSInteger)markedTimesCount;
- (void)restoreVideoDuration;
- (void)restoreDuration;
- (void)deleteAllSegments;
- (void)deleteAllSegments:(dispatch_block_t)block;
- (void)removeLastSegment;
- (void)fillChallengeNameForFragmentInfo;
- (BOOL)allowComplete;
- (void)setupMaxLimitTime;

// record operation
- (void)startRecord;
- (void)startRecordWithDelayRecord:(BOOL)isDelayRecord;
- (void)pauseRecordWithSuccess:(BOOL)success;
- (void)picturePauseRecordWithSuccess:(BOOL)success;
- (void)pauseRecord;
- (void)stopRecordAndPossiblyExportVideo;
- (void)stopRecordAndExportVideo;
- (void)finishExportVideo:(BOOL)success;
- (void)executeExportCompletionWithVideoData:(HTSVideoData *_Nullable)newVideoData error:(NSError *_Nullable)error;

// take picture
- (void)takePicture;

// live-photo
- (void)startLivePhotoRecordWithCompletion:(void(^)(void))completion;

// completeRecord
- (BOOL)complete;
- (void)willEnterNextPageWithMode:(ACCRecordMode *)mode;
- (void)didEnterNextPageWithMode:(ACCRecordMode *)mode;

// pure mode
- (void)turnOnPureMode;
- (void)turenOffPureMode;

- (void)addSubscriber:(id<ACCRecordFlowServiceSubscriber>)subscriber;
- (void)removeSubscriber:(id<ACCRecordFlowServiceSubscriber>)subscriber;

// delay fetch asset
- (RACSignal *)captureStillImageSignal;
- (void)cancelDelayFetchIfNeeded;

@end

#endif /* ACCRecordFlowService_h */
