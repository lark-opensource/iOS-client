//
//  ACCCameraDefine.h
//  Pods
//
// Created by Hao Yipeng on December 17, 2019
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
    // Beauty
    ACCCameraBeautyItemFullBeauty,
    ACCCameraBeautyItemSmooth,
    ACCCameraBeautyItemWhite,
    ACCCameraBeautyItemSharp,
    // Deformation
    ACCCameraBeautyItemBigEye,
    ACCCameraBeautyItemFaceLift,
    // Make up
    ACCCameraBeautyItemBlusher,
    ACCCameraBeautyItemLipStick,
};

FOUNDATION_EXPORT void * const ACCCameraVideoRecordContext;
