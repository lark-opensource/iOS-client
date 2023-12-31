//
//  HMDProtectDefine.h
//  Pods
//
//  Created by 白昆仑 on 2020/4/2.
//

#ifndef HMDProtectDefine_h
#define HMDProtectDefine_h


typedef NS_ENUM(NSInteger, HMDProtectionType) {
    
    HMDProtectionTypeNone = 0,
    
    HMDProtectionTypeUnrecognizedSelector = 1<<0,
    
    HMDProtectionTypeContainers = 1<<1,
    
    HMDProtectionTypeNotification = 1<<2,
    
    HMDProtectionTypeKVO = 1<<3,
    
    HMDProtectionTypeKVC = 1<<4,
    
    HMDProtectionTypeUserDefaults = 1<<5,
    
    HMDProtectionTypeAll =
    HMDProtectionTypeUnrecognizedSelector|
    HMDProtectionTypeContainers|
    HMDProtectionTypeNotification|
    HMDProtectionTypeKVO|
    HMDProtectionTypeKVC|
    HMDProtectionTypeUserDefaults
};

#endif /* HMDProtectDefine_h */
