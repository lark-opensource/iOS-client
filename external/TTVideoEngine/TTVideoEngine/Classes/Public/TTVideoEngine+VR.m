//
//  TTVideoEngine+VR.m
//  TTVideoEngine
//
//  Created by shen chen on 2022/7/26.
//

#import "TTVideoEngine+VR.h"
#import "TTVideoEngine.h"
#import "TTVideoEngineVRAction.h"
#import "TTVideoEngineActionManager.h"
#import "TTVideoEngine+Options.h"
#import <objc/runtime.h>


@implementation TTVideoEngine (VR)

- (void)setVREffectParamter:(NSDictionary *)paramter {
    if ([self.vrAction respondsToSelector:@selector(setVREffectParamter:)]) {
        [self.vrAction setVREffectParamter:paramter];
    }
}

- (void)setVRModeEnabled:(BOOL)VRModeEnabled {
    if ([self.vrAction respondsToSelector:@selector(setVRModeEnabled:)]) {
        [self.vrAction setVRModeEnabled:VRModeEnabled];
    }
}

- (void)configVRWithUserInfo:(NSDictionary *)userInfo {
    if ([self.vrAction respondsToSelector:@selector(configVRWithUserInfo:)]) {
        [self.vrAction configVRWithUserInfo:userInfo];
    }
}

- (void)startRenderVROutlet {
    if ([self.vrAction respondsToSelector:@selector(startRenderVROutlet)]) {
        [self.vrAction startRenderVROutlet];
    }
}

- (void)recenter {
    if ([self.vrAction respondsToSelector:@selector(recenter)]) {
        [self.vrAction recenter];
    }
}

- (void)updateConfigurationWithParams:(NSDictionary *)params {
    if ([self.vrAction respondsToSelector:@selector(updateConfigurationWithParams:)]) {
        [self.vrAction updateConfigurationWithParams:params];
    }
}

- (void)rotateWithPitch:(CGFloat)pitch andYaw:(CGFloat)yaw andRoll:(CGFloat)roll {
    if ([self.vrAction respondsToSelector:@selector(rotateWithPitch:andYaw:andRoll:)]) {
        [self.vrAction rotateWithPitch:pitch andYaw:yaw andRoll:roll];
    }
}

- (void)setScopicType:(TTVideoEngineVRScopicType)scopicType {
    if ([self.vrAction respondsToSelector:@selector(setScopicType:)]) {
        [self.vrAction setScopicType:scopicType];
    }
}

- (void)setHeadTrackingEnabled:(BOOL)headTrackingEnabled {
    if ([self.vrAction respondsToSelector:@selector(setHeadTrackingEnabled:)]) {
        [self.vrAction setHeadTrackingEnabled:headTrackingEnabled];
    }
}

- (void)setZoom:(float)zoom {
    if ([self.vrAction respondsToSelector:@selector(setZoom:)]) {
        [self.vrAction setZoom:zoom];
    }
}

- (void)setVrAction:(id<TTVideoEngineVRAction>)vrAction {
    objc_setAssociatedObject(self, @selector(vrAction), vrAction, OBJC_ASSOCIATION_COPY);
}

- (id<TTVideoEngineVRAction>)vrAction {
    id<TTVideoEngineVRAction> vrAction = objc_getAssociatedObject(self, @selector(vrAction));
    if (!vrAction) {
        vrAction = [[TTVideoEngineActionManager shareInstance] actionObjWithProtocal:@protocol(TTVideoEngineVRAction)];
        objc_setAssociatedObject(self, @selector(vrAction), vrAction, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return vrAction;
}

- (void)setEffectParams:(NSDictionary *)params {
    if (params) {
        [self setEffect:params];
    }
}

- (void)setIntOptionValue:(NSInteger)value forKey:(NSInteger)key {
    switch (key) {
        case TTVideoEnginePlayerOptionEnableVsyncHelper:
            [self setOptionForKey:VEKKeyIsEnableVsyncHelper value:@(value)];
            break;
        case TTVideoEnginePlayerOptionCustomizedVideoRenderingFrameRate:
            [self setOptionForKey:VEKKeyIsCustomizedVideoRenderingFrameRate value:@(value)];
            break;
            
        default:
            break;
    }
}

@end
