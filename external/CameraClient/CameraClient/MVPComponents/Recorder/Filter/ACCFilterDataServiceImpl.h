//
//  ACCFilterDataServiceImpl.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/5/20.
//

#import <Foundation/Foundation.h>
#import <CreationKitComponents/ACCFilterDataService.h>

@class AWEVideoPublishViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface ACCFilterDataServiceImpl : NSObject<ACCFilterDataService>

-(instancetype)initWithRepository:(AWEVideoPublishViewModel *)repository;

@end

NS_ASSUME_NONNULL_END
