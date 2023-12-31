//
//  HMDCrashTracker.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import <Foundation/Foundation.h>

#if SIMPLIFYEXTENSION
#import "HMDCrashConfig.h"
#else
#import "HMDTracker.h"
#import "HMDCrashRecord.h"
#endif

#if SIMPLIFYEXTENSION
@interface HMDCrashTracker : NSObject
@property (atomic, strong, readonly, nullable) HMDCrashConfig *config;
#else
typedef void (^ _Nullable CrashReportBlock)(HMDCrashRecord * _Nullable record);
typedef void (^ _Nullable CrashReportNotDetectBlock)(void);
@interface HMDCrashTracker : HMDTracker
#endif

@property (nonatomic, strong, nullable) NSString *crashPath;
@property (nonatomic, assign, readonly) NSTimeInterval launchThreshold;
@property(atomic, readonly, getter=isFinishDetection) BOOL finishDetection;
@property(atomic, readonly, getter=isDetected) BOOL detected;

#if SIMPLIFYEXTENSION
+ (instancetype _Nonnull)sharedTracker;
- (void)start;
- (void)updateConfig:(HMDCrashConfig * _Nullable)config;
#else
- (void)addCrashDetectCallBack:(CrashReportBlock)reportBlock;
- (void)addCrashNotDetectCallBack:(CrashReportNotDetectBlock)reportBlock;

- (void)uploadCrashLogImmediately;
/// Upload Crash Log immediately. If request success, return YES. If request failed, return NO.
/// Not even if no Crash Log available for upload, return value may still be YES for most of conditions.
/// YES only means it is now able to check whether crash log exist, and then upload it
/// - Parameter error: the reason why return NO
- (BOOL)uploadCrashLogImmediately:(NSError * __autoreleasing _Nullable * _Nullable)error;
#endif

@end
