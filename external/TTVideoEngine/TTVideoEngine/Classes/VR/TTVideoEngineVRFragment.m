//
//  TTVideoEngineVRFragment.m
//  TTVideoEngine
//
//  Created by shen chen on 2022/7/26.
//

#import "TTVideoEngineVRFragment.h"
#import "TTVideoEngineVRReaction.h"
#import "TTVideoEngineActionManager.h"
#import "TTVideoEngineVRModel.h"
#import "NSDictionary+TTVideoEngine.h"

@interface TTVideoEngineVRFragment()

@property (nonatomic, weak) id<TTVideoEngineVRReaction> reaction;
@property (nonatomic, assign) TTVideoEngineVRScopicType scopicType;
@property (nonatomic, assign) BOOL headTrackingEnable;
@property (nonatomic, assign) float zoom;
@property (nonatomic, assign) BOOL isVRModeEnable;
@property (nonatomic, assign) TTVideoEngineVRContentType contentType;
@property (nonatomic, assign) TTVideoEngineVRFOV fovType;

@end

@implementation TTVideoEngineVRFragment

+ (instancetype)fragmentInstance {
    TTVideoEngineVRFragment *fragment = [[TTVideoEngineVRFragment alloc] init];
    return fragment;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [[TTVideoEngineActionManager shareInstance] registerActionObj:self forProtocol:@protocol(TTVideoEngineVRAction)];
}

- (void)dealloc {
    [[TTVideoEngineActionManager shareInstance] removeActionObj:self forProtocol:@protocol(TTVideoEngineVRAction)];
}

- (void)videoEngineDidPrepared:(TTVideoEngine *)engine {
    
}

- (void)videoEngineDidCallPlay:(TTVideoEngine *)engine {
   
}

- (void)videoEngineDidReset:(TTVideoEngine *)engine {
   
}

- (void)videoEngineDidInit:(TTVideoEngine *)engine {
    self.reaction = engine;
}

- (void)setVRModeEnabled:(BOOL)VRModeEnabled {
    _isVRModeEnable = VRModeEnabled;
    if ([self.reaction respondsToSelector:@selector(setEffectParams:)]) {
        [self.reaction setEffectParams:@{
            kTTVideoEngineVideoProcessingProcessorAction: @(kTTVideoEngineVideoProcessingProcessorActionUseEffect),
            kTTVideoEngineVideoProcessingProcessorEffectType: @(kTTVideoEngineVideoProcessingProcessorEffectTypeVR),
            kTTVideoEngineVideoProcessingProcessorIntValue: @(VRModeEnabled),
        }];
    }
}

- (void)configVRWithUserInfo:(nonnull NSDictionary *)userInfo {
    if (!self.isVRModeEnable) {
        return;
    }
    BOOL enableVsync = [userInfo ttVideoEngineBoolValueForKey:kTTVideoEngineVideoProcessingProcessorVREnableVsyncHelper defaultValue:NO];
    NSInteger customizedVideoRenderingFrameRate = [userInfo ttVideoEngineIntegerValueForKey:kTTVideoEngineVideoProcessingProcessorVRCustomizedVideoRenderingFrameRate defaultValue:0];
    if ([self.reaction respondsToSelector:@selector(setIntOptionValue:forKey:)]) {
        [self.reaction setIntOptionValue:enableVsync forKey:TTVideoEnginePlayerOptionEnableVsyncHelper];
        [self.reaction setIntOptionValue:customizedVideoRenderingFrameRate forKey:TTVideoEnginePlayerOptionCustomizedVideoRenderingFrameRate];
    }
    if ([self.reaction respondsToSelector:@selector(setEffectParams:)]) {
        [self.reaction setEffectParams:@{
            kTTVideoEngineVideoProcessingProcessorAction: @(kTTVideoEngineVideoProcessingProcessorActionInitEffect),
            kTTVideoEngineVideoProcessingProcessorEffectType: @(kTTVideoEngineVideoProcessingProcessorEffectTypeVR),
            kTTVideoEngineVideoProcessingProcessorUseEffect: @(1),
        }];
    }
}

- (void)recenter {
    if ([self.reaction respondsToSelector:@selector(setEffectParams:)]) {
        [self.reaction setEffectParams:@{
            kTTVideoEngineVideoProcessingProcessorAction: @(kTTVideoEngineVideoProcessingProcessorActionVRRecenter),
        }];
    }
}

- (void)rotateWithPitch:(CGFloat)pitch andYaw:(CGFloat)yaw andRoll:(CGFloat)roll {
    [self updateConfigurationWithParams:@{
           kTTVideoEngineVideoProcessingProcessorVRRotationPitch: @(pitch),
           kTTVideoEngineVideoProcessingProcessorVRRotationYaw: @(yaw),
           kTTVideoEngineVideoProcessingProcessorVRRotationRoll: @(roll),
    }];
}

- (void)setHeadTrackingEnable:(BOOL)headTrackingEnable {
    _headTrackingEnable = headTrackingEnable;
    [self updateConfigurationWithParams:@{
        kTTVideoEngineVideoProcessingProcessorVRHeadTrackingEnabled: @(headTrackingEnable),
    }];
}

- (void)setScopicType:(TTVideoEngineVRScopicType)scopicType {
    _scopicType = scopicType;
    [self updateConfigurationWithParams:@{
        kTTVideoEngineVideoProcessingProcessorVRScopicType: @(scopicType),
    }];
}

- (void)setContentType:(TTVideoEngineVRContentType)contentType {
    _contentType = contentType;
    [self updateConfigurationWithParams:@{
        kTTVideoEngineVideoProcessingProcessorVRContentType: @(contentType),
    }];
}

- (void)setFovType:(TTVideoEngineVRFOV)fovType {
    _fovType = fovType;
    [self updateConfigurationWithParams:@{
        kTTVideoEngineVideoProcessingProcessorVRFOVType: @(fovType),
    }];
}

- (void)setZoom:(float)zoom {
    _zoom = zoom;
    [self updateConfigurationWithParams:@{
           kTTVideoEngineVideoProcessingProcessorVRZoom: @(zoom),
    }];
}

- (void)startRenderVROutlet {
    TTVideoEngineVRScopicType scopicType = self.scopicType;
    BOOL isHeadTrackingEnabled = self.headTrackingEnable;
    float zoom = self.zoom;
    TTVideoEngineVRContentType contentType = self.contentType;
    TTVideoEngineVRFOV fovType = self.fovType;
    [self updateConfigurationWithParams:@{
        kTTVideoEngineVideoProcessingProcessorVRScopicType: @(scopicType),
        kTTVideoEngineVideoProcessingProcessorVRHeadTrackingEnabled: @(isHeadTrackingEnabled),
        kTTVideoEngineVideoProcessingProcessorVRZoom: @(zoom),
        kTTVideoEngineVideoProcessingProcessorVRContentType: @(contentType),
        kTTVideoEngineVideoProcessingProcessorVRFOVType: @(fovType)
    }];
}

- (void)updateConfigurationWithParams:(nonnull NSDictionary *)params {
    NSMutableDictionary *configuration = [NSMutableDictionary dictionaryWithDictionary:@{
           kTTVideoEngineVideoProcessingProcessorAction: @(kTTVideoEngineVideoProcessingProcessorActionVRConfiguration),
       }];
    [configuration addEntriesFromDictionary:params];
    if ([self.reaction respondsToSelector:@selector(setEffectParams:)]) {
        [self.reaction setEffectParams:configuration.copy];
    }
}

- (void)setVREffectParamter:(NSDictionary *)paramter {
    id value = [paramter objectForKey:kTTVideoEngineVideoProcessingProcessorAction];
    if (![value isKindOfClass:[NSNumber class]]) {
        return;
    }
    int temp = [value intValue];
    if (temp == kTTVideoEngineVideoProcessingProcessorActionVRConfiguration) {
        [self updateVRConfingWithParameter:paramter];
    } else if (temp == kTTVideoEngineVideoProcessingProcessorActionInitEffect) {
        bool enableVRMode = [paramter ttVideoEngineBoolValueForKey:kTTVideoEngineEnableVRMode defaultValue:NO];
        [self setVRModeEnabled:enableVRMode];
        [self configVRWithUserInfo:paramter];
        [self updateVRConfingWithParameter:paramter];
        [self startRenderVROutlet];
    } else if (temp == kTTVideoEngineVideoProcessingProcessorActionVRRecenter) {
        [self recenter];
    } else if (temp == kTTVideoEngineVideoProcessingProcessorActionUseEffect) {
        int useVR = [paramter ttVideoEngineIntValueForKey:kTTVideoEngineVideoProcessingProcessorIntValue defaultValue:0];
        [self.reaction setEffectParams:@{
            kTTVideoEngineVideoProcessingProcessorAction: @(kTTVideoEngineVideoProcessingProcessorActionUseEffect),
            kTTVideoEngineVideoProcessingProcessorEffectType: @(kTTVideoEngineVideoProcessingProcessorEffectTypeVR),
            kTTVideoEngineVideoProcessingProcessorIntValue: @(useVR),
        }];
    }
}

- (void)updateVRConfingWithParameter:(NSDictionary *)paramter {
    id zoomValue = [paramter objectForKey:kTTVideoEngineVideoProcessingProcessorVRZoom];
    if ([zoomValue isKindOfClass:[NSNumber class]]) {
        [self setZoom:[zoomValue floatValue]];
    }
    id scopicTypeValue = [paramter objectForKey:kTTVideoEngineVideoProcessingProcessorVRScopicType];
    if ([scopicTypeValue isKindOfClass:[NSNumber class]]) {
        [self setScopicType:[scopicTypeValue intValue]];
    }
    id headTrackingEnabledValue = [paramter objectForKey:kTTVideoEngineVideoProcessingProcessorVRHeadTrackingEnabled];
    if ([headTrackingEnabledValue isKindOfClass:[NSNumber class]]) {
        [self setHeadTrackingEnable:[headTrackingEnabledValue boolValue]];
    }
    id contentType = [paramter objectForKey:kTTVideoEngineVideoProcessingProcessorVRContentType];
    if ([contentType isKindOfClass:[NSNumber class]]) {
        [self setContentType:[contentType intValue]];
    }
    id fovType = [paramter objectForKey:kTTVideoEngineVideoProcessingProcessorVRFOVType];
    if ([fovType isKindOfClass:[NSNumber class]]) {
        [self setFovType:[fovType intValue]];
    }
    id pitchValue = [paramter objectForKey:kTTVideoEngineVideoProcessingProcessorVRRotationPitch];
    id yawValue = [paramter objectForKey:kTTVideoEngineVideoProcessingProcessorVRRotationYaw];
    id rollValue = [paramter objectForKey:kTTVideoEngineVideoProcessingProcessorVRRotationRoll];
    if ([pitchValue isKindOfClass:[NSNumber class]] && [yawValue isKindOfClass:[NSNumber class]] && [rollValue isKindOfClass:[NSNumber class]]) {
        [self rotateWithPitch:[pitchValue floatValue] andYaw:[yawValue floatValue] andRoll:[rollValue floatValue]];
    }
}

@end
