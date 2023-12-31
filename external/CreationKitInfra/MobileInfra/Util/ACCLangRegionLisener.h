//
//  ACCLangRegionLisener.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/8/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define ACC_LANGUAGE_CHANGE_NOTIFICATION [[ACCLangRegionLisener shareInstance] languageChangedNotification]
#define ACC_REGION_CHANGE_NOTIFICATION [[ACCLangRegionLisener shareInstance] regionChangedNotification]

@interface ACCLangRegionLisener : NSObject

+ (instancetype)shareInstance;

- (NSString*)languageChangedNotification;

- (NSString*)regionChangedNotification;

@end

NS_ASSUME_NONNULL_END
