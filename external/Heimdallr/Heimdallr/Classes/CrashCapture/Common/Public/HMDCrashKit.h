//
//  HMDCrashKit.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import "HMDPublicMacro.h"

@class HMDCrashReportInfo;

@protocol HMDCrashKitDelegate <NSObject>

- (void)crashKitDidDetectCrashForLastTime:(HMDCrashReportInfo * _Nullable)crashReport;

@optional

- (void)crashKitDidNotDetectCrashForLastTime;

@end

@interface HMDCrashKit : NSObject

@property(nonatomic,weak, nullable) id<HMDCrashKitDelegate> delegate;

+ (instancetype _Nonnull)sharedInstance;

- (void)setup;

- (void)setDynamicValue:(NSString * _Nullable)value key:(NSString * _Nullable)key HMD_PRIVATE;

- (void)syncDynamicValue:(NSString * _Nullable)value key:(NSString * _Nullable)key HMD_PRIVATE;

- (void)removeDynamicValue:(NSString * _Nullable)key HMD_PRIVATE;

@end


#define HMDSharedCrashKit [HMDCrashKit sharedInstance]
