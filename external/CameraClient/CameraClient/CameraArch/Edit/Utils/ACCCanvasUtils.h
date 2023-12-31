//
//  ACCCanvasUtils.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/6/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@interface ACCCanvasUtils : NSObject

+ (void)setUpCanvasWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                 mediaContainerView:(UIView *)mediaContainerView;

+ (void)updateCanvasContentWithPhoto:(UIImage *)image publishModel:(AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
