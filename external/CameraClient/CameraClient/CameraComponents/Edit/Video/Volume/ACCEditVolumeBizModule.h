//
//  ACCEditVolumeBizModule.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/9/18.
//

#import <Foundation/Foundation.h>
#import <IESInject/IESServiceContainer.h>

@class AWEVideoPublishViewModel;

@interface ACCEditVolumeBizModule : NSObject

- (instancetype)initWithServiceProvider:(nonnull id<IESServiceProvider>) serviceProvider;
- (void)setup;

@end
