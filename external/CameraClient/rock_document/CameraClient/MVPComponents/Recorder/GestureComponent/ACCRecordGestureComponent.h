//
//  ACCRecordGestureComponent.h
//  Pods
//
//  Created by songxiangwu on 2019/7/28.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCFeatureComponent.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordGestureComponent : ACCFeatureComponent

- (void)duetLayoutDidApplyDuetEffect:(BOOL)enableDuetLayoutPanGesture;

- (BOOL)cameraTapGestureEnabled;
- (void)enableAllCameraGesture:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
