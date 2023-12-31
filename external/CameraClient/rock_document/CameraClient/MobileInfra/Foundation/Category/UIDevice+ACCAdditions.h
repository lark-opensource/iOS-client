//
//  UIDevice+ACCAdditions.h
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2020/10/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (ACCAdditions)

+ (NSString *)acc_machineModel;

+ (nullable NSString *)ip4Address;

+ (nullable NSString *)ip6Address;

//当前设备是否需要降分辨率
+ (BOOL)acc_unsupportPresetPhoto;

+ (CGFloat)acc_onePixel;

// 当前设备是否支持三摄
+ (BOOL)acc_supportTrippleVirtualCamera;

@end

NS_ASSUME_NONNULL_END
