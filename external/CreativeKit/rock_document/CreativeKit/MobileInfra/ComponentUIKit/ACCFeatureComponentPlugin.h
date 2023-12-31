//
//  ACCFeatureComponentPlugin.h
//  CreativeKit-Pods-CameraClient
//
//  Created by Howie He on 2021/3/1.
//

#import <Foundation/Foundation.h>

@protocol ACCFeatureComponent;
@protocol IESServiceProvider;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCFeatureComponentPlugin <NSObject>

/// Identifier of host component, only support subclass of ACCFeatureComponent now.
@property (nonatomic, class, readonly) id hostIdentifier;

/// It can be changed to associated type when we migrate to Swift
@property (nonatomic, weak) __kindof id<ACCFeatureComponent> component;
@optional
- (void)bindToComponent:(__kindof id<ACCFeatureComponent>)component;

@end

NS_ASSUME_NONNULL_END
