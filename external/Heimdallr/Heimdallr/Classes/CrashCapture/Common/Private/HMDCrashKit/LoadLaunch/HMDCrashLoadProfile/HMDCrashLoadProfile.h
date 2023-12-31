//
//  HMDCrashLoadMeta.h
//  Heimdallr
//
//  Created by sunrunwang on 2024/08/08.
//

#import <Foundation/Foundation.h>
#import "HMDCrashLoadOption+Private.h"

@interface HMDCrashLoadProfile : NSObject

@property(direct, nonatomic, nullable) NSString * channel;
@property(direct, nonatomic, nullable) NSString * appName;
@property(direct, nonatomic, nullable) NSString * installID;
@property(direct, nonatomic, nullable) NSString * deviceID;
@property(direct, nonatomic, nullable) NSString * userID;
@property(direct, nonatomic, nullable) NSString * scopedDeviceID;
@property(direct, nonatomic, nullable) NSString * scopedUserID;

+ (instancetype _Nonnull)mirrorProfile:(NSDictionary * _Nullable)dictionary
                               outdate:(BOOL)outdate;

- (NSDictionary * _Nonnull)mirrorDictionary;

+ (instancetype _Nonnull)userProfile:(HMDCLoadOptionRef _Nonnull)option;

+ (instancetype _Nonnull)defaultProfile;

@end
