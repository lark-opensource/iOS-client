//
//  HMDCrashMetaData.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import "HMDCrashModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashMetaData : HMDCrashModel

@property(nonatomic, copy) NSString *arch;

@property(nonatomic, copy) NSString *deviceModel;

@property(nonatomic, copy) NSString *appVersion;

@property(nonatomic, copy) NSString *bundleVersion;

@property(nonatomic, copy) NSString *osVersion;

@property(nonatomic, copy) NSString *osFullVersion;

@property(nonatomic, copy) NSString *osBuildVersion;

@property(nonatomic, copy) NSString *UUID;

@property(nonatomic, copy) NSString *processName;

@property(nonatomic, assign) NSUInteger processID;

@property(nonatomic, assign) NSTimeInterval startTime;

@property(nonatomic, copy) NSString *bundleID;

@property(nonatomic, assign) unsigned long long physicalMemory;

@property(nonatomic, copy) NSString *sdkVersion;

@property(nonatomic, copy) NSString *commitID;

//appExtension 监控相关
@property(nonatomic, assign) BOOL isAppExtension;

@property(nonatomic, copy) NSString *appExtensionType;

@property(nonatomic, assign) BOOL isMacARM;

@property(nonatomic, assign) unsigned long exceptionMainAddress;

@end

NS_ASSUME_NONNULL_END
