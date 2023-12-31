//
//  ACCCameraDefine.h
//  Pods
//
//  Created by 郝一鹏 on 2019/12/17.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/IESMMBaseDefine.h>

typedef NS_ENUM(NSUInteger, ACCCameraFlashMode) {
    ACCCameraFlashModeOff  = 0,
    ACCCameraFlashModeOn   = 1,
    ACCCameraFlashModeAuto = 2,
};

typedef NS_ENUM(NSUInteger, ACCCameraTorchMode) {
    ACCCameraTorchModeOff  = 0,
    ACCCameraTorchModeOn   = 1,
    ACCCameraTorchModeAuto = 2, // AVCaptureTorchModeAuto only works when there is an AVCaptureVideoDataOutput. However, monitoring of light levels only happens at the beginning, not "continuously", so you should not use this enum. This torch mode will be ignored.
};

typedef NS_ENUM(NSUInteger, ACCCameraSessionState) {
    ACCCameraSessionStateStart,
    ACCCameraSessionStateStop,
    ACCCameraSessionStatePause,
    ACCCameraSessionStateResume
};

typedef NS_ENUM(NSUInteger, ACCCameraBeautyType) {
    ACCCameraBeautyTypeNone = 0,
    ACCCameraBeautyTypeBeauty = 1,
    ACCCameraBeautyTypeReshape = 2,
    ACCCameraBeautyTypeMakeup = 3
};

typedef NS_ENUM(NSUInteger, ACCCameraBeautyItem) {
    ACCCameraBeautyItemNone,
    // 美颜
    ACCCameraBeautyItemFullBeauty,
    ACCCameraBeautyItemSmooth,
    ACCCameraBeautyItemWhite,
    ACCCameraBeautyItemSharp,
    // 形变
    ACCCameraBeautyItemBigEye,
    ACCCameraBeautyItemFaceLift,
    // 美妆
    ACCCameraBeautyItemBlusher,
    ACCCameraBeautyItemLipStick,
};

FOUNDATION_EXTERN IESEffectType VEEffectTypeWithCameraBeautyType(ACCCameraBeautyType cameraBeautyType);

@protocol ACCEffectModel <NSObject>

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *resourcesPath;

@end

@interface ACCCameraBeautyPayload : NSObject <ACCEffectModel>

@property (nonatomic, assign) ACCCameraBeautyType beautyType;
@property (nonatomic, assign) CGFloat ratio;

@end
