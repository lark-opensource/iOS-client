//
//  ACCDeviceInfo.h
//  CameraClient
//
//  Created by Liu Deping on 2019/12/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCDeviceInfo : NSObject

+ (NSString *)acc_appDisplayName;
+ (NSString *)acc_platformName;
+ (NSString *)acc_versionName;
+ (NSString *)acc_appName;
+ (NSString *)acc_appID;
+ (NSString *)acc_bundleIdentifier;
+ (NSString *)acc_currentChannel;
+ (NSString*)acc_OSVersion;

@end

NS_ASSUME_NONNULL_END
