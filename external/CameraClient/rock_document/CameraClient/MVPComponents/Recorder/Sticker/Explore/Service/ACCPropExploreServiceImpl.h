//
//  ACCPropExploreServiceImpl.h
//  CameraClient-Pods-AwemeCore
//
//  Created by wanghongyu on 2021/10/12.
//

#import <Foundation/Foundation.h>
#import "ACCPropExploreService.h"

@protocol IESServiceProvider;
@interface ACCPropExploreServiceImpl : NSObject <ACCPropExploreService>
@property (nonatomic, weak, nullable) id<IESServiceProvider> serviceProvider;
@end


