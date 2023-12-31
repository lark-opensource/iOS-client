//
//  AWECameraFeatureButtonPassThroughView.h
//  CameraClient-Pods-Aweme
//
//  Created by fengming.shi on 2020/12/8 11:04.
//	Copyright © 2020 Bytedance. All rights reserved.
	

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWECameraFeatureButtonPassThroughViewDelegate <NSObject>

- (void)handleFeatureButtionPassThroughHitTest;

@end

@interface AWECameraFeatureButtonPassThroughView : UIView

@property (nonatomic, weak) id<AWECameraFeatureButtonPassThroughViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
