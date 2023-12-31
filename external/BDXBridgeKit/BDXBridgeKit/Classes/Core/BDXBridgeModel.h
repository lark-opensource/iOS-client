//
//  BDXBridgeModel.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/19.
//

#import <Mantle/Mantle.h>
#import "BDXBridgeContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSDictionary *extraInfo;
@property (nonatomic, strong) BDXBridgeContext* bridgeContext;

@end

/**
 @NOTE

 All options & enums value should not start from 'zero',
 since the 'zero' one should be reserved as 'AbcNone' for options and 'AbcUnknown' for enum.
 */

#pragma mark - Options

typedef NS_OPTIONS(NSUInteger, BDXBridgeMediaType) {
    BDXBridgeMediaTypeNone = 0,
    BDXBridgeMediaTypeVideo = 1 << 0,
    BDXBridgeMediaTypeImage = 1 << 1,
};

#pragma mark - Enums

typedef NS_ENUM(NSUInteger, BDXBridgeLogLevel) {
    BDXBridgeLogLevelUnknown = 0,
    BDXBridgeLogLevelVerbose,
    BDXBridgeLogLevelDebug,
    BDXBridgeLogLevelInfo,
    BDXBridgeLogLevelWarn,
    BDXBridgeLogLevelError,
};

typedef NS_ENUM(NSUInteger, BDXBridgePermissionType) {
    BDXBridgePermissionTypeUnknown = 0,
    BDXBridgePermissionTypeCamera,
    BDXBridgePermissionTypeMicrophone,
    BDXBridgePermissionTypePhotoAlbum,
    BDXBridgePermissionTypeVibration,
    BDXBridgePermissionTypeCalendar,
};

typedef NS_ENUM(NSUInteger, BDXBridgePermissionStatus) {
    BDXBridgePermissionStatusUnknown = 0,
    BDXBridgePermissionStatusPermitted,
    BDXBridgePermissionStatusDenied,
    BDXBridgePermissionStatusUndetermined,
    BDXBridgePermissionStatusRestricted,
};

typedef NS_ENUM(NSUInteger, BDXBridgeMediaSourceType) {
    BDXBridgeMediaSourceTypeUnknown = 0,
    BDXBridgeMediaSourceTypeAlbum,
    BDXBridgeMediaSourceTypeCamera,
};

typedef NS_ENUM(NSUInteger, BDXBridgeCameraType) {
    BDXBridgeCameraTypeUnknown = 0,
    BDXBridgeCameraTypeFront,
    BDXBridgeCameraTypeBack,
};

typedef NS_ENUM(NSUInteger, BDXBridgeToastType) {
    BDXBridgeToastTypeUnknown = 0,
    BDXBridgeToastTypeSuccess,
    BDXBridgeToastTypeError,
};

typedef NS_ENUM(NSUInteger, BDXBridgeModalActionType) {
    BDXBridgeModalActionTypeUnknown = 0,
    BDXBridgeModalActionTypeConfirm,
    BDXBridgeModalActionTypeCancel,
    BDXBridgeModalActionTypeMask,
};

typedef NS_ENUM(NSUInteger, BDXBridgeActionSheetActionsType) {
    BDXBridgeActionSheetActionsTypeDefault = 0,
    BDXBridgeActionSheetActionsTypeWarn,
};

typedef NS_ENUM(NSUInteger, BDXBridgeActionSheetActionType) {
    BDXBridgeActionSheetActionTypeSelect = 0,
    BDXBridgeActionSheetActionTypeDismiss,
};

typedef NS_ENUM(NSUInteger, BDXBridgeLoginStatus) {
    BDXBridgeLoginStatusUnknown = 0,
    BDXBridgeLoginStatusLoggedIn,
    BDXBridgeLoginStatusCancelled,
};

typedef NS_ENUM(NSUInteger, BDXBridgeLogoutStatus) {
    BDXBridgeLogoutStatusUnknown = 0,
    BDXBridgeLogoutStatusLoggedOut,
    BDXBridgeLogoutStatusCancelled,
};

typedef NS_ENUM(NSUInteger, BDXBridgeVibrationStyle) {
    BDXBridgeVibrationStyleUnknown = 0,
    BDXBridgeVibrationStyleLight,
    BDXBridgeVibrationStyleMedium,
    BDXBridgeVibrationStyleHeavy,
};

typedef NS_ENUM(NSUInteger, BDXBridgeStatusStyle) {
    BDXBridgeStatusStyleUnknown = 0,
    BDXBridgeStatusStyleLight,
    BDXBridgeStatusStyleDark,
};

NS_ASSUME_NONNULL_END
