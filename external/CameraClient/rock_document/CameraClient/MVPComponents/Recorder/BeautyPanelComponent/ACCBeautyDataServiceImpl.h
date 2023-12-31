//
//  ACCBeautyDataServiceImpl.h
//  CameraClient-Pods-Aweme
//
//  Created by machao on 2021/5/24.
//

#import <Foundation/Foundation.h>
#import <CreationKitComponents/ACCBeautyDataService.h>

NS_ASSUME_NONNULL_BEGIN
@class AWEVideoPublishViewModel;

@interface ACCBeautyDataServiceImpl : NSObject<ACCBeautyDataService>

- (instancetype)initWithRepository:(AWEVideoPublishViewModel *)repository;

@end

NS_ASSUME_NONNULL_END
