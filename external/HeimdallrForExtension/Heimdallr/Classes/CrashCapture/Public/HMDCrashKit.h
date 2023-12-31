//
//  HMDCrashKit.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/23.
//

#import <Foundation/Foundation.h>
@class HMDCrashReportInfo;

@protocol HMDCrashKitDelegate <NSObject>

- (void)crashKitDidDetectCrashForLastTime:(HMDCrashReportInfo * _Nullable)crashReport;

@optional
- (void)crashKitDidNotDetectCrashForLastTime;

@end

@interface HMDCrashKit : NSObject

@property(nonatomic,weak, nullable) id<HMDCrashKitDelegate> delegate;

+ (instancetype)sharedInstance;

- (void)setup;

- (void)setDynamicValue:(NSString * _Nullable)value key:(NSString * _Nullable)key;

- (void)syncDynamicValue:(NSString * _Nullable)value key:(NSString * _Nullable)key;

- (void)removeDynamicValue:(NSString * _Nullable)key;

@end


#define HMDSharedCrashKit [HMDCrashKit sharedInstance]
