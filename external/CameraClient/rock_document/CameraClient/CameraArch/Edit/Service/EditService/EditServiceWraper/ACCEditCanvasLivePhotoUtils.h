//
//  ACCEditCanvasLivePhotoUtils.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/7/15.
//

#import <Foundation/Foundation.h>

@class AWEVideoPublishViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditCanvasLivePhotoUtils : NSObject

+ (void)configLivePhotoWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
