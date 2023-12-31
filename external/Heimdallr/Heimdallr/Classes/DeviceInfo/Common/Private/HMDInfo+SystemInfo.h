//
//  HMDInfo+SystemInfo.h
//  Heimdallr
//
//  Created by 谢俊逸 on 8/4/2018.
//

#import "HMDInfo.h"

@interface HMDInfo (SystemInfo)

@property (nonatomic, assign, readonly, getter=isLowPowerModeEnabled) BOOL lowPowerModeEnabled;
@property (nonatomic, strong, readonly) NSString *systemVersion;
@property (nonatomic, strong, readonly) NSString *systemName;
@property (nonatomic, strong, readonly) NSString *executablePath;
@property (nonatomic, strong, readonly) NSString *executableName;
@property (nonatomic, strong, readonly) NSString *osVersion;
@property (nonatomic, strong, readonly) NSString *processName;
@property (nonatomic, strong, readonly) NSString *platform;
@property (nonatomic, assign, readonly) int processID;

@end
