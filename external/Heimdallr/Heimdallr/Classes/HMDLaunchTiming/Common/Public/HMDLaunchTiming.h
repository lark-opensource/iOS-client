//
//  HMDLaunchAnalysis.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/5/27.
//

#import "HeimdallrModule.h"


@interface HMDLaunchTiming : HeimdallrModule

@property (nonatomic, assign) BOOL enableUserFinish;
@property (nonatomic, assign) BOOL enableUseAutoTrace;

+ (nullable instancetype)shared;

/// set more accurate load timestamp
/// @param timestamp millisecond
- (void)resetClassLoadTS:(long long)timestamp;

/// set more accurate applicationdidfinishing timestamp;
- (void)resetAppDidFinishTS:(long long)timestamp;

/// if used custom end, must set enableUserFinish to YES before didFinishLaucnh return;
- (void)userLaunchFinish;
- (void)userLaunchFinishWithName:(NSString * _Nullable)name;

@end

