//
//  ACCRecordToEditRouterCoordinatorProtocol.h
//  Pods
//
//  Created by songxiangwu on 2019/9/6.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCRouterCoordinatorProtocol.h>
#import "ACCEditViewControllerInputData.h"
#import <CameraClient/ACCRecordViewControllerInputData.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRecordToEditRouterCoordinatorProtocol <ACCRouterCoordinatorProtocol>

@property (nonatomic, strong, nullable) ACCRecordViewControllerInputData *sourceViewControllerInputData;
@property (nonatomic, strong, nullable) ACCEditViewControllerInputData *targetViewControllerInputData;

@end

NS_ASSUME_NONNULL_END
