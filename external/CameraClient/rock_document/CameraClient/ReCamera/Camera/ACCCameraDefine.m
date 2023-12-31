//
//  ACCCameraDefine.m
//  Pods
//
//  Created by 郝一鹏 on 2019/12/18.
//

#import <CreationKitRTProtocol/ACCCameraDefine.h>

IESEffectType VEEffectTypeWithCameraBeautyType(ACCCameraBeautyType cameraBeautyType)
{
    switch (cameraBeautyType) {
        case ACCCameraBeautyTypeNone: {
            return IESEffectNone;
            break;
        }
        case ACCCameraBeautyTypeBeauty: {
            return IESEffectBeautify;
            break;
        }
        case ACCCameraBeautyTypeReshape: {
            return IESEffectReshape;
            break;
        }
        default:
            return IESEffectNone;
            break;
    }
}

@implementation ACCCameraBeautyPayload

@synthesize identifier = _identifier;
@synthesize resourcesPath = _resourcesPath;
@synthesize name = _name;

@end
