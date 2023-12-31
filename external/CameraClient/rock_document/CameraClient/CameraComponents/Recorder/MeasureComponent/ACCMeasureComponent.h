//
//  ACCMeasureComponent.h
//  Pods
//
//  Created by 郝一鹏 on 2019/8/11.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCFeatureComponent.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCVCLifeCycleStage) {
    ACCVCLifeCycleStageInit = 1,
    ACCVCLifeCycleStageViewDidLoadStart,
    ACCVCLifeCycleStageViewDidLoadEnd,
    ACCVCLifeCycleStageViewWillAppear,
    ACCVCLifeCycleStageViewDidAppear,
};

@interface ACCMeasureComponent : ACCFeatureComponent

@end

NS_ASSUME_NONNULL_END
