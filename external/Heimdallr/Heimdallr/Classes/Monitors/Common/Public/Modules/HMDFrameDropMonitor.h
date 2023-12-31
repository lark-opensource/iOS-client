//
//  HMDFrameDropMonitor.h
//  Heimdallr
//
//  Created by 王佳乐 on 2019/3/5.
//

#import <Foundation/Foundation.h>
#import "HMDMonitor.h"
#import "HMDMonitorCallbackObject.h"
#import "HMDMonitorCustomSwitch.h"

extern NSString * _Nonnull const kHMDFrameDropMonitor;

@interface HMDFrameDropMonitorConfig : HMDMonitorConfig

@property (nonatomic, assign) BOOL enableUploadStaticRecord;

@end

@interface HMDFrameDropMonitor : HMDMonitor <HMDMonitorCustomSwitch>
// 是否允许在静止状态下对丢帧进行采样 默认是 NO; 默认静止状态下不采样
@property (nonatomic, assign, readonly) BOOL isStaticStateSample;
/// 是否固定丢帧帧率
/// 背景: HTR3/7/25 的丢帧N帧率 hitch_duraion / frame_duration  的 frame_duration 是固定的 16.67 . 但是 frame_drop 丢帧监控的监控的 frame_drop_duration / frame_duration 这里的 frame_dration 是随着设备变化的, 所以会导致平台上的 HTR3/HTR7/HTR25 和 frame_drop3/7/25 对不齐. 这个开关用来控制 frame_drop 的 frame_duration 是否也固定成 16.67
@property (nonatomic, assign) BOOL isFixedFrameDropStandardDuration;

- (nonnull instancetype)init __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));
+ (nonnull instancetype)new __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));

- (void)applicationDidReceiveFrameNotification:(CFTimeInterval)timeInterval frameDuration:(CFTimeInterval)frameDuration __attribute__((deprecated("This interface is not available!!! Do not call this method!!! it will cause an error in frame drop data")));
- (void)applicationDidReceiveFrameNotification:(CFTimeInterval)timeInterval frameDuration:(CFTimeInterval)frameDuration targetTimestamp:(CFTimeInterval)targetTimestamp __attribute__((deprecated("This interface is not available!!! Do not call this method!!! it will cause an error in frame drop data")));

/// 在滑动拖拽结束时设置，滑动结束后，会重置为 0
- (void)updateCurrentTouchReleasedVelocity:(CGPoint)velocity targetContentDistance:(CGPoint)targetDistance;
- (void)updateFrameDropCustomScene:(NSString *_Nonnull)customScene;

- (void)addFrameDropMonitorCallback:(HMDMonitorCallback _Nonnull)callback;
- (void)removeFrameDropMonitorCallback:(HMDMonitorCallback _Nonnull)callback;

/// the method will return a object. if remove the callback from HMDFrameDropMonitor, please use "removeFPSMonitorCallbackObject:" that parameter is the object returned from this method
/// @param callback get record call back
- (HMDMonitorCallbackObject * _Nullable)addFrameDropMonitorCallbackObject:(HMDMonitorCallback _Nonnull)callback;

/// remove added callback, use HMDMonitorCallbackObject
/// @param callbackObject the callback info object (HMDMonitorCallbackObject). returned by calling "addFPSMonitorCallbackObject:"
- (void)removeFrameDropMonitorCallbackObject:(HMDMonitorCallbackObject * _Nullable)callbackObject;

- (void)refreshRateInfo:(NSUInteger)refreshRate;

/// 是否允许在静止状态下对丢帧进行采样 默认是 NO; 如果只对单个场景进行设置, 在离开场景时要恢复原来的状态
- (void)allowedNormalStateSample:(BOOL)isAllowed;
/// whether allow record fps_drop while UI is static(not scroll)
/// @param isAllowed isAllowed ; default is NO
/// @param callbackInterval if set call,  callback exec interval (sec)
- (void)allowedNormalStateSample:(BOOL)isAllowed callbackInterval:(NSInteger)callbackInterval;

/// "entra" in the fps_drop record, key must be NSString and value must be NSString or NSNumber
- (void)addFrameDropCustomExtra:(NSDictionary *_Nonnull)extra;
- (void)removeFrameDropCustomExtra:(NSDictionary *_Nonnull)extra;
- (void)removeFrameDropCustomExtraWithKeys:(NSArray<NSString *> *_Nonnull)keys;

- (void)setLastTimestampToZero;
@end

