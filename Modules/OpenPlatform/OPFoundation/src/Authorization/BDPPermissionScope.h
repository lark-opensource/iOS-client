//
//  BDPPermissionScope.h
//  Timor
//
//  Created by liuxiangxin on 2019/6/14.
//

#ifndef BDPPermissionScope_h
#define BDPPermissionScope_h

typedef NS_ENUM(NSInteger, BDPPermissionScopeType) {
    BDPPermissionScopeTypeUnknown = 0,
    BDPPermissionScopeTypeLocation,
    BDPPermissionScopeTypeAddress,
    BDPPermissionScopeTypeCamera,
    BDPPermissionScopeTypeUserInfo,
    BDPPermissionScopeTypeMicrophone,
    BDPPermissionScopeTypePhoneNumber,
    BDPPermissionScopeTypeAlbum,
    BDPPermissionScopeTypeScreenRecord,
    BDPPermissionScopeTypeClipboard,
    BDPPermissionScopeTypeAppBadge,
    BDPPermissionScopeTypeRunData,
    BDPPermissionScopeTypeBluetooth
};

#endif /* BDPPermissionScope_h */
