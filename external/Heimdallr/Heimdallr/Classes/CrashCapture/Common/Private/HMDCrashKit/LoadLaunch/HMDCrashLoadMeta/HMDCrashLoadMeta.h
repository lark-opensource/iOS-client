//
//  HMDCrashLoadMeta.h
//  Heimdallr
//
//  Created by sunrunwang on 2024/08/08.
//

#import <Foundation/Foundation.h>
#import "HMDCrashLoadProfile.h"

@interface HMDCrashLoadMeta : NSObject

@property(direct, nonatomic, nullable) NSString * appID;
@property(direct, nonatomic, nullable) NSString * uploadingHost;

@property(direct, nonatomic, nullable) NSString * codeType;

@property(direct, nonatomic, nullable) NSString * bundleID;             // package_name
@property(direct, nonatomic, nullable) NSString * bundleShortVersion;   // app_version
@property(direct, nonatomic, nullable) NSString * bundleVersion;        // update_version_code
@property(direct, nonatomic, nullable) NSString * displayName;
@property(direct, nonatomic, nullable) NSString * autoTestType;
@property(direct, nonatomic, nullable) NSString * testRuntime;
@property(direct, nonatomic)           BOOL       offline;

@property(direct, nonatomic, nullable) NSString * SDKVersion;
@property(direct, nonatomic, nullable) NSString * OSBuildVersion;

@property(direct, nonatomic)           BOOL       isiOSAppOnMac;
@property(direct, nonatomic, nullable) NSString * deviceModel;
@property(direct, nonatomic, nullable) NSString * OSVersion;
@property(direct, nonatomic, nullable) NSString * processName;
@property(direct, nonatomic)           unsigned   processID;

@property(direct, nonatomic)           NSUInteger hoursFromGMT;

@property(direct, nonatomic, nullable) NSString * language;
@property(direct, nonatomic, nullable) NSString * region;

@property(direct, nonatomic)           BOOL       envAbnormal;

@property(direct, nonatomic, nullable) HMDCrashLoadProfile *profile;

@property(direct, nonatomic, nullable) HMDCrashLoadProfile *mirrorProfile;
@property(direct, nonatomic, nullable) HMDCrashLoadProfile *userProfile;

+ (instancetype _Nonnull)meta;

@end
