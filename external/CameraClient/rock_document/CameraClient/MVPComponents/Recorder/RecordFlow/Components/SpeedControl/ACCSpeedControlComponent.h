//
//  ACCSpeedControlComponent.h
//  Pods
//
//  Created by liyingpeng on 2020/6/23.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCFeatureComponent.h>
#import "ACCSpeedControlViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCSpeedControlComponent : ACCFeatureComponent

#pragma mark - SubComponent Visible
- (void)showSpeedControlIfNeeded;
- (ACCSpeedControlViewModel *)viewModel;
- (void)externalSelectSpeed:(HTSVideoSpeed)speed;

@end

NS_ASSUME_NONNULL_END
