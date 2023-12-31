//
//  ACCBeautyFeatureComponent+Private.h
//  CameraClient-Pods-Modeo
//
//  Created by zhangyuanming on 2021/1/20.
//

#import <CreationKitComponents/ACCBeautyFeatureComponent.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCBeautyFeatureComponent (Private)

@property (nonatomic, strong, readonly) id<ACCBeautyService> beautyService;

@end

NS_ASSUME_NONNULL_END
