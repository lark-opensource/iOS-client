//
//  ACCPropExploreService.h
//  CameraClient-Pods-AwemeCore
//
//  Created by wanghongyu on 2021/10/12.
//

#import <Foundation/Foundation.h>

@protocol ACCPropExploreServiceSubscriber <NSObject>

- (void)propExplorePageWillShow;

@end

@protocol ACCPropExploreService <NSObject>

- (void)showExplorePage;
- (void)dismissExplorePage;
- (BOOL)isShowing;

- (void)addSubscriber:(nonnull id<ACCPropExploreServiceSubscriber>)subscriber;

@end

