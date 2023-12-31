//
//  AWEStudioMeasureManager.h
//  Pods
//
// Created by Hao Yipeng on June 11, 2019
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEStudioMeasureManager : NSObject

@property (nonatomic, assign) CFTimeInterval startRecordTime;
@property (nonatomic, assign) CFTimeInterval pauseRecordTime;

@property (nonatomic, assign, readonly) CFTimeInterval viewDidLoadedToFirstFrameAppearDuration; // ms

+ (instancetype)sharedMeasureManager;

// Monitor the camera's routine shooting of Lujin, and click the plus sign to display the first frame of the camera
- (void)trackClickPlusTime;
- (void)cancelTrackClickPlusTime;
- (void)trackClickPlusToRecordPageFirstFrameAppearWithReferString:(NSString *)referString;

// Monitor the life cycle of the first frame of the camera
- (void)trackViewDidLoad;

// Cancel reporting of single camera statistics
- (void)cancelOnceTrack;


// Asynchronous synchronous queue execution
- (void)asyncOperationBlock:(dispatch_block_t)block;

- (void)asyncMonitorTrackService:(NSString *)trackService status:(NSInteger)status extra:(NSDictionary *)extra;

- (void)asyncMonitorTrackService:(NSString *)trackService value:(float)value extra:(NSDictionary *_Nullable)extra;

- (void)asyncMonitorTrackData:(NSDictionary *)trackData logTypeStr:(NSString *)logTypeStr;


#pragma mark - performance track

- (void)trackOfDraftInfo:(NSInteger)count;

- (void)trackOfDraftClickStart;
- (void)trackOfDraftClickEnd:(NSDictionary *)trackParams;

- (void)trackEffectInfo;

- (void)trackCaptureIMG:(nullable NSDictionary * (^)(void))block;

@end

NS_ASSUME_NONNULL_END
