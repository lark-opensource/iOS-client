//
//  BDXBridgeCheckPermissionMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeCheckPermissionMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import <AVFoundation/AVCaptureDevice.h>
#import <Photos/PHPhotoLibrary.h>
#import <EventKit/EKEventStore.h>

@implementation BDXBridgeCheckPermissionMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeCheckPermissionMethod);

- (void)callWithParamModel:(BDXBridgeCheckPermissionMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    BDXBridgePermissionStatus permissionStatus = BDXBridgePermissionStatusUnknown;
    switch (paramModel.permission) {
        case BDXBridgePermissionTypeCamera:
            permissionStatus = [self permissionStatusForMediaType:AVMediaTypeVideo];
            break;
        case BDXBridgePermissionTypeMicrophone:
            permissionStatus = [self permissionStatusForMediaType:AVMediaTypeAudio];
            break;
        case BDXBridgePermissionTypePhotoAlbum:
            permissionStatus = [self permissionStatusForPhotoAlbum];
            break;
        case BDXBridgePermissionTypeVibration:
            permissionStatus = BDXBridgePermissionStatusPermitted;
            break;
        case BDXBridgePermissionTypeCalendar:
            permissionStatus = [self permissionStatusForCalendar];
        default:
            break;
    }
    
    BDXBridgeCheckPermissionMethodResultModel *resultModel = nil;
    BDXBridgeStatus *status = nil;
    if (permissionStatus == BDXBridgePermissionStatusUnknown) {
        status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidResult message:@"Unknown permission status."];
    } else {
        resultModel = [BDXBridgeCheckPermissionMethodResultModel new];
        resultModel.status = permissionStatus;
    }
    bdx_invoke_block(completionHandler, resultModel, status);
}

#pragma mark - Helpers

- (BDXBridgePermissionStatus)permissionStatusForMediaType:(AVMediaType)mediaType
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    switch (status) {
        case AVAuthorizationStatusAuthorized: return BDXBridgePermissionStatusPermitted;
        case AVAuthorizationStatusDenied: return BDXBridgePermissionStatusDenied;
        case AVAuthorizationStatusNotDetermined: return BDXBridgePermissionStatusUndetermined;
        case AVAuthorizationStatusRestricted: return BDXBridgePermissionStatusRestricted;
        default: return BDXBridgePermissionStatusUnknown;
    }
}

- (BDXBridgePermissionStatus)permissionStatusForPhotoAlbum
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusAuthorized: return BDXBridgePermissionStatusPermitted;
        case PHAuthorizationStatusDenied: return BDXBridgePermissionStatusDenied;
        case PHAuthorizationStatusNotDetermined: return BDXBridgePermissionStatusUndetermined;
        case PHAuthorizationStatusRestricted: return BDXBridgePermissionStatusRestricted;
        default:
            if (@available(iOS 14.0, *)) {
                return (status == PHAuthorizationStatusLimited) ? BDXBridgePermissionStatusPermitted : BDXBridgePermissionStatusUnknown;
            } else {
                return BDXBridgePermissionStatusUnknown;
            }
    }
}

- (BDXBridgePermissionStatus)permissionStatusForCalendar
{
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    switch (status) {
        case EKAuthorizationStatusAuthorized: return BDXBridgePermissionStatusPermitted;
        case EKAuthorizationStatusDenied: return BDXBridgePermissionStatusDenied;
        case EKAuthorizationStatusNotDetermined: return BDXBridgePermissionStatusUndetermined;
        case EKAuthorizationStatusRestricted: return BDXBridgePermissionStatusRestricted;
        default: return BDXBridgePermissionStatusUnknown;
    }
}

@end
