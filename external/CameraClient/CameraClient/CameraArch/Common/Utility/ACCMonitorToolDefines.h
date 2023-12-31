//
//  ACCMonitorToolDefines.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/8/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ACCMonitorToolBusinessTypeKey;

typedef NS_ENUM(NSInteger, ACCMonitorToolBusinessType) {
    ACCMonitorToolBusinessTypeNone = 0,
    ACCMonitorToolBusinessTypeSecurityFrames = 1,
    ACCMonitorToolBusinessTypeAnchor = 2,
    ACCMonitorToolBusinessTypeProp = 3,
};

NS_ASSUME_NONNULL_END
