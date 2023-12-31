//
//  ACCEditToPublishRouterCoordinatorProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/9/26.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCRouterCoordinatorProtocol.h>
#import "ACCPublishViewControllerInputData.h"
#import "ACCEditViewControllerInputData.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditToPublishRouterCoordinatorProtocol <ACCRouterCoordinatorProtocol>

@property (nonatomic, strong, nullable) ACCEditViewControllerInputData *sourceViewControllerInputData;
@property (nonatomic, strong, nullable) ACCPublishViewControllerInputData *targetViewControllerInputData;

@end

NS_ASSUME_NONNULL_END
