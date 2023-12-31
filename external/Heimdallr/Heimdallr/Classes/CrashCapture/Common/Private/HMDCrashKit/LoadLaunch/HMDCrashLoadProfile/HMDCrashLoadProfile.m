//
//  HMDCrashLoadMeta.m
//  Heimdallr
//
//  Created by sunrunwang on 2024/08/08.
//

#import "HMDMacro.h"
#import "HMDCrashLoadProfile.h"
#import "NSDictionary+HMDSafe.h"

@implementation HMDCrashLoadProfile

- (NSDictionary * _Nonnull)mirrorDictionary {
    NSMutableDictionary *dictionary =
        [NSMutableDictionary dictionaryWithCapacity:7];
    
    [dictionary setValue:self.channel        forKey:@"channel"];
    [dictionary setValue:self.appName        forKey:@"appName"];
    [dictionary setValue:self.installID      forKey:@"installID"];
    [dictionary setValue:self.deviceID       forKey:@"deviceID"];
    [dictionary setValue:self.userID         forKey:@"userID"];
    [dictionary setValue:self.scopedDeviceID forKey:@"scopedDeviceID"];
    [dictionary setValue:self.scopedUserID   forKey:@"scopedUserID"];
    
    return dictionary;
}

+ (instancetype _Nonnull)mirrorProfile:(NSDictionary * _Nullable)dictionary
                               outdate:(BOOL)outdate {
    HMDCrashLoadProfile *profile = HMDCrashLoadProfile.alloc.init;
    profile.channel        = [dictionary hmd_stringForKey:@"channel"];
    profile.appName        = [dictionary hmd_stringForKey:@"appName"];
    profile.installID      = [dictionary hmd_stringForKey:@"installID"];
    if(unlikely(!outdate)) {
        profile.deviceID       = [dictionary hmd_stringForKey:@"deviceID"];
        profile.userID         = [dictionary hmd_stringForKey:@"userID"];
        profile.scopedDeviceID = [dictionary hmd_stringForKey:@"scopedDeviceID"];
        profile.scopedUserID   = [dictionary hmd_stringForKey:@"scopedUserID"];
    }
    return profile;
}

+ (instancetype _Nonnull)userProfile:(HMDCLoadOptionRef _Nonnull)option {
    
    HMDCrashLoadProfile *profile = HMDCrashLoadProfile.alloc.init;
    if(option == NULL) DEBUG_RETURN(profile);
    
    const char * _Nullable channel = option->userProfile.channel;
    if(channel != NULL) {
        profile.channel = [NSString stringWithUTF8String:channel];
    }
    
    const char * _Nullable appName = option->userProfile.appName;
    if(appName != NULL) {
        profile.appName = [NSString stringWithUTF8String:appName];
    }
    
    const char * _Nullable installID = option->userProfile.installID;
    if(installID != NULL) {
        profile.installID = [NSString stringWithUTF8String:installID];
    }
    
    const char * _Nullable deviceID = option->userProfile.deviceID;
    if(deviceID != NULL) {
        profile.deviceID = [NSString stringWithUTF8String:deviceID];
    }
    
    const char * _Nullable userID = option->userProfile.userID;
    if(userID != NULL) {
        profile.userID = [NSString stringWithUTF8String:userID];
    }
    
    const char * _Nullable scopedDeviceID = option->userProfile.scopedDeviceID;
    if(scopedDeviceID != NULL) {
        profile.scopedDeviceID = [NSString stringWithUTF8String:scopedDeviceID];
    }
    
    const char * _Nullable scopedUserID = option->userProfile.scopedUserID;
    if(scopedUserID != NULL) {
        profile.scopedUserID = [NSString stringWithUTF8String:scopedUserID];
    }
    
    return profile;
}

+ (instancetype _Nonnull)defaultProfile {
    HMDCrashLoadProfile *profile = HMDCrashLoadProfile.alloc.init;
    profile.channel        = @"";
    profile.appName        = @"";
    profile.installID      = @"0";
    profile.deviceID       = @"0";
    profile.userID         = @"0";
    profile.scopedDeviceID = @"0";
    profile.scopedUserID   = @"0";
    return profile;
}

@end
