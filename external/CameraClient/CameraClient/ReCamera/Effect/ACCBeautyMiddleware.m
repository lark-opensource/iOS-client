//
//  ACCBeautyMiddleware.m
//  CameraClient
//
//  Created by luochaojing on 2019/12/25.
//

#import "ACCBeautyMiddleware.h"
#import "ACCBeautyAction.h"
#import "ACCBeautyState.h"

@interface ACCBeautyMiddleware()

@property (nonatomic, weak) IESMMCamera<IESMMRecoderProtocol> *camera;

@end

@implementation ACCBeautyMiddleware

+ (ACCBeautyMiddleware *)middlewareWithCamera:(IESMMCamera<IESMMRecoderProtocol> *)camera {
    ACCBeautyMiddleware *mw = [[ACCBeautyMiddleware alloc] init];
    mw.camera = camera;
    return mw;
}

- (BOOL)shouldHandleAction:(ACCAction *)action {
    return [action isKindOfClass:[ACCBeautyAction class]];
}

- (ACCAction *)handleAction:(ACCAction *)action next:(ACCActionHandler)next {
    if ([action isKindOfClass:[ACCBeautyAction class]]) {
        [self handleBeautyAction:(ACCBeautyAction *)action];
    }
    return next(action);
}

- (void)handleBeautyAction:(ACCBeautyAction *)action {
    // TODO: 生效camera
    switch (action.type) {
        case ACCBeautyActionTypeApplyLVBeauty: {
            [self applyLVBeautyWithAction:action];
            break;
        }
        case ACCBeautyActionTypeApplyBeauty: {
            [self applyBeautyWithAction:action];
            break;
        }
        case ACCBeautyActionTypeChangeBeautyRatio: {
            [self changeBeautyWithAction:action];
            break;
        }
        default: {
            break;
        }
    }
    
}

- (void)applyLVBeautyWithAction:(ACCBeautyAction *)action
{
    switch (action.beautyType) {
        case ACCCameraBeautyTypeReshape: // 瘦脸
            if (action.path.length) {
                [self.camera applyEffect:action.path type:IESEffectReshapeTwoParam];
                CGFloat veMaxEyeIndensityValue = 0.7;
                IESIndensityParam params;
                params.cheekIndensity = action.value;
                params.eyeIndensity = action.value * veMaxEyeIndensityValue;
                [self.camera applyIndensity:params type:IESEffectReshapeTwoParam];
            }
            break;
        case ACCCameraBeautyTypeBeauty: // 美颜
            if (action.path.length) {
                [self.camera applyEffect:action.path type:IESEffectBeautify];
                IESIndensityParam params;
                params.smoothIndensity  = action.value * 0.8;
                params.brightIndensity = 0.0;
                params.sharpIndensity = 0.65;
                [self.camera applyIndensity:params type:IESEffectBeautify];
            }
            break;
        default:
            break;
    }
}

- (void)applyBeautyWithAction:(ACCBeautyAction *)action
{
    [self p_applyBeautyWithAction:action isChangeRatio:NO];
}


- (void)changeBeautyWithAction:(ACCBeautyAction *)action
{
    [self p_applyBeautyWithAction:action isChangeRatio:YES];
}

- (void)p_applyBeautyWithAction:(ACCBeautyAction *)action isChangeRatio:(BOOL)isChangeRatio
{
    ACCBeautyState *currentState = (ACCBeautyState *)[self getState];
    switch (action.beautyType) {
        case ACCCameraBeautyTypeBeauty: {
            IESIndensityParam param = {};
            param.sharpIndensity = action.beautyParam.sharpValue ? action.beautyParam.sharpValue.floatValue : currentState.sharpValue;
            param.brightIndensity = action.beautyParam.whiteValue ? action.beautyParam.whiteValue.floatValue : currentState.whiteValue;
            param.smoothIndensity = action.beautyParam.smoothValue ? action.beautyParam.smoothValue.floatValue : currentState.smoothValue;
            if (!isChangeRatio && ![currentState.beautyPath isEqualToString:action.path]) {
                [self.camera applyEffect:action.path type:IESEffectBeautify];
            }
            [self.camera applyIndensity:param type:IESEffectBeautify];
            break;
        }
        case ACCCameraBeautyTypeReshape: {
            IESIndensityParam param = {};
            param.cheekIndensity = action.reshapeParam.faceLiftValue ? action.reshapeParam.faceLiftValue.floatValue : currentState.faceLiftValue;
            param.eyeIndensity = action.reshapeParam.bigEyeValue ? action.reshapeParam.bigEyeValue.floatValue : currentState.bigEyeValue;
            if (!isChangeRatio && ![currentState.reshapePath isEqualToString:action.path]) {
                [self.camera applyEffect:action.path type:IESEffectReshape];
            }
            [self.camera applyIndensity:param type:IESEffectReshape];
            break;
        }
        case ACCCameraBeautyTypeMakeup: {
            IESIndensityParam param = {};
            param.blusherIndensity = action.makeupParam.blusherValue ? action.makeupParam.blusherValue.floatValue : currentState.blusherValue;
            param.lipIndensity = action.makeupParam.lipStickerValue ? action.makeupParam.lipStickerValue.floatValue : currentState.lipStickerValue;
            param.decreeIndensity = action.makeupParam.decreeValue ? action.makeupParam.decreeValue.floatValue : currentState.decreeValue;
            param.pouchIndensity = action.makeupParam.pouchValue ? action.makeupParam.pouchValue.floatValue : currentState.pouchValue;
            if (!isChangeRatio && ![currentState.makeupPath isEqualToString:action.path]) {
                [self.camera applyEffect:action.path type:IESEffectMakeup];
            }
            [self.camera applyIndensity:param type:IESEffectMakeup];
            break;
        }
        default:
            break;
    }
}

@end
