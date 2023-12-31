//
//  ACCBeuatyReducer.m
//  CameraClient
//
//  Created by luochaojing on 2019/12/25.
//

#import "ACCBeautyReducer.h"
#import "ACCBeautyState.h"
#import "ACCBeautyAction.h"

@implementation ACCBeautyReducer

- (ACCBeautyState *)stateWithAction:(ACCAction *)action andState:(ACCBeautyState *)state {
    NSAssert([state isKindOfClass:[ACCBeautyState class]], @"invalid state type");
    
    if ([action isKindOfClass:[ACCBeautyAction class]]) {
        ACCBeautyAction *_action = (ACCBeautyAction *)action;
        ACCBeautyState *updatedState = [[ACCBeautyState alloc] init];
        [updatedState mergeValuesForKeysFromModel:state];
        
        switch (action.type) {
            case ACCBeautyActionTypeApplyLVBeauty: {
                [self lvUpdateState:updatedState withAction:_action];
                break;
            }
            case ACCBeautyActionTypeApplyBeauty: {
                [self updateState:updatedState withAction:_action isChangeRation:NO];
                break;
            }
            case ACCBeautyActionTypeChangeBeautyRatio: {
                [self updateState:updatedState withAction:_action isChangeRation:YES];
                break;
            }
            default: {
                break;
            }
        }
        return updatedState;
    }
    
    return state;
}

- (void)lvUpdateState:(ACCBeautyState *)state withAction:(ACCBeautyAction *)action
{
    switch (action.beautyType) {
        case ACCCameraBeautyTypeBeauty:
            state.smoothValue = action.value;
            break;
        case ACCCameraBeautyTypeReshape:
            state.faceLiftValue = action.value;
            break;
        default:
            break;
    }
}

- (void)updateState:(ACCBeautyState *)state withAction:(ACCBeautyAction *)action isChangeRation:(BOOL)isChangeRatio
{
    switch (action.beautyType) {
        case ACCCameraBeautyTypeBeauty: {
            if (!isChangeRatio) {
                state.beautyPath = action.path;
            }
            state.smoothValue = action.beautyParam.smoothValue ? action.beautyParam.smoothValue.floatValue : state.smoothValue;
            state.whiteValue = action.beautyParam.whiteValue ? action.beautyParam.whiteValue.floatValue : state.whiteValue;
            state.sharpValue = action.beautyParam.sharpValue ? action.beautyParam.sharpValue.floatValue : state.sharpValue;
            break;
        }
        case ACCCameraBeautyTypeReshape: {
            if (!isChangeRatio) {
                state.reshapePath = action.path;
            }
            state.bigEyeValue = action.reshapeParam.bigEyeValue ? action.reshapeParam.bigEyeValue.floatValue : state.bigEyeValue;
            state.faceLiftValue = action.reshapeParam.faceLiftValue ? action.reshapeParam.faceLiftValue.floatValue : state.faceLiftValue;
            break;
        }
        case ACCCameraBeautyTypeMakeup: {
            if (!isChangeRatio) {
                state.makeupPath = action.path;
            }
            state.blusherValue = action.makeupParam.blusherValue ? action.makeupParam.blusherValue.floatValue : state.blusherValue;
            state.lipStickerValue = action.makeupParam.lipStickerValue ? action.makeupParam.lipStickerValue.floatValue : state.lipStickerValue;
            state.decreeValue = action.makeupParam.decreeValue ? action.makeupParam.decreeValue.floatValue : state.decreeValue;
            state.pouchValue = action.makeupParam.pouchValue ? action.makeupParam.pouchValue.floatValue : state.pouchValue;
            break;
        }
        default:
            break;
    }
}

- (Class)domainActionClass
{
    return [ACCBeautyAction class];
}
@end
