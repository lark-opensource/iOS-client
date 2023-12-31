//
//  ACCDeviceAuth.m
//  Pods
//
//  Created by Liu Deping on 2019/9/11.
//

#import "ACCDeviceAuth.h"
#import <AVFoundation/AVFoundation.h>

static NSInteger ACCPhotoLibrayAuthorizationStatus = PHAuthorizationStatusNotDetermined;
static NSInteger ACCVideoAVAuthorizationStatus = AVAuthorizationStatusNotDetermined;
static NSInteger ACCAudioAVAuthorizationStatus = AVAuthorizationStatusNotDetermined;

@implementation ACCDeviceAuth

+ (BOOL)isCameraAuth
{
    AVAuthorizationStatus status = [self acc_authorizationStatusForVideo];
    return status == AVAuthorizationStatusAuthorized;
}

+ (BOOL)isCameraNotDetermined
{
    AVAuthorizationStatus status = [self acc_authorizationStatusForVideo];
    return status == AVAuthorizationStatusNotDetermined;
}

+ (BOOL)isCameraDenied
{
    AVAuthorizationStatus status = [self acc_authorizationStatusForVideo];
    return (status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied);
}

+ (BOOL)isMicroPhoneAuth
{
    AVAuthorizationStatus status = [self acc_authorizationStatusForAudio];
    return status == AVAuthorizationStatusAuthorized;
}

+ (BOOL)isMicroPhoneNotDetermined
{
    AVAuthorizationStatus status = [self acc_authorizationStatusForAudio];
    return status == AVAuthorizationStatusNotDetermined;
}

+ (BOOL)isMicroPhoneDenied
{
    AVAuthorizationStatus status = [self acc_authorizationStatusForAudio];
    return (status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied);
}

+ (void)requestPhotoLibraryPermission:(void(^)(BOOL success))completion
{
    PHAuthorizationStatus status = [self acc_authorizationStatusForPhoto];
    switch (status) {
        case PHAuthorizationStatusNotDetermined: {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    switch (status) {
                        case PHAuthorizationStatusAuthorized: {
                            if (completion) {
                                completion(YES);
                            }
                            break;
                        }
                        case PHAuthorizationStatusNotDetermined:
                        case PHAuthorizationStatusRestricted:
                        case PHAuthorizationStatusDenied:
                        default: {
                            if (completion) {
                                completion(NO);
                            }
                        }
                    }
                });
            }];
            break;
        }
        case PHAuthorizationStatusAuthorized: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(YES);
                }
            });
            break;
        }
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied:
        default: {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(NO);
                }
            });
        }
    }
}

+ (PHAuthorizationStatus)acc_authorizationStatusForPhoto
{
    if (ACCPhotoLibrayAuthorizationStatus == PHAuthorizationStatusNotDetermined) {
        ACCPhotoLibrayAuthorizationStatus = [PHPhotoLibrary authorizationStatus];
    }
    return (PHAuthorizationStatus)ACCPhotoLibrayAuthorizationStatus;
}

+ (AVAuthorizationStatus)acc_authorizationStatusForVideo
{
    if (ACCVideoAVAuthorizationStatus == AVAuthorizationStatusNotDetermined) {
        ACCVideoAVAuthorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    }
    return (AVAuthorizationStatus)ACCVideoAVAuthorizationStatus;
}

+ (AVAuthorizationStatus)acc_authorizationStatusForAudio
{
    if (ACCAudioAVAuthorizationStatus == AVAuthorizationStatusNotDetermined) {
        ACCAudioAVAuthorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    }
    return (AVAuthorizationStatus)ACCAudioAVAuthorizationStatus;
}

+ (BOOL)isiOS14PhotoNotDetermined
{
#ifdef __IPHONE_14_0 // xcode12
    if (@available(iOS 14.0, *)) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
        return status == PHAuthorizationStatusNotDetermined;
    }
#endif
    return NO;
}

+ (BOOL)isiOS14PhotoLimited
{
#ifdef __IPHONE_14_0 // xcode12
    if (@available(iOS 14.0, *)) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
        return status == PHAuthorizationStatusLimited;
    }
#endif
    return NO;
}

+ (BOOL)hasCameraAndMicroPhoneAuth
{
    AVAuthorizationStatus videoStatus = [self acc_authorizationStatusForVideo];
    AVAuthorizationStatus audioStatus = [self acc_authorizationStatusForAudio];
    return videoStatus == AVAuthorizationStatusAuthorized && audioStatus == AVAuthorizationStatusAuthorized;
}

+ (ACCRecordAuthComponentAuthType)currentAuthType
{
    ACCRecordAuthComponentAuthType type;
    if ([self isCameraAuth]) {
        type = ACCRecordAuthComponentCameraAuthed;
    } else if ([self isCameraNotDetermined]) {
        type = ACCRecordAuthComponentCameraNotDetermined;
    } else {
        type = ACCRecordAuthComponentCameraDenied;
    }
    
    if ([self isMicroPhoneAuth]) {
        type |= ACCRecordAuthComponentMicAuthed;
    } else if ([self isMicroPhoneNotDetermined]) {
        type |= ACCRecordAuthComponentMicNotDetermined;
    } else if ([self isMicroPhoneDenied]) {
        type |= ACCRecordAuthComponentMicDenied;
    }
    return type;
}

@end
