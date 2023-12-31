//
//  ACCStudioRepoNearbyModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/10/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWEStudioNearbyCircleModelProtocol;
@protocol ACCStudioRepoNearbyModelProtocol <NSObject>

@property (nonatomic, strong) NSString *publishTitleHint;
@property (nonatomic, copy) id<AWEStudioNearbyCircleModelProtocol> nearbyCircleModel;
@property (nonatomic, assign) BOOL isFromNearby;

@end

NS_ASSUME_NONNULL_END
