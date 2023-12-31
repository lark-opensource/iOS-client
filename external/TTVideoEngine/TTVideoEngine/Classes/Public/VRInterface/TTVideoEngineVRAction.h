//
//  TTVideoEngineVRAction.h
//  TTVideoEngine
//
//  Created by shen chen on 2022/7/26.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineVRModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TTVideoEngineVRAction <NSObject>

- (void)setVREffectParamter:(NSDictionary *)paramter;

- (void)configVRWithUserInfo:(NSDictionary *)userInfo;

- (void)startRenderVROutlet;

- (void)updateConfigurationWithParams:(NSDictionary *)params;

- (void)rotateWithPitch:(CGFloat)pitch andYaw:(CGFloat)yaw andRoll:(CGFloat)roll;

- (void)recenter;

- (void)setVRModeEnabled:(BOOL)VRModeEnabled;

- (void)setScopicType:(TTVideoEngineVRScopicType)scopicType;

- (void)setHeadTrackingEnabled:(BOOL)headTrackingEnabled;

- (void)setZoom:(float)zoom;

@end

NS_ASSUME_NONNULL_END
