//
//  HMDCrashDirectory+Private.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/9.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#import "HMDCrashDirectory.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashDirectory (Private)

#pragma mark last time crash

@property(class, readonly, atomic) BOOL lastTimeCrash;

#pragma mark Urgent

@property(class, nonatomic, readonly, getter=isUrgent) BOOL urgent;    // accessable anytime [⚠️ before setup could not decide urgent flag]

@end

NS_ASSUME_NONNULL_END
