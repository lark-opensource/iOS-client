//
//  IESMetadataStorageDefines.h
//  Pods
//
//  Created by 陈煜钏 on 2021/2/3.
//

#ifndef IESMetadataStorageDefines_h
#define IESMetadataStorageDefines_h

typedef NS_ENUM(NSInteger, IESMetadataLogLevel) {
    IESMetadataLogLevelInfo,
    IESMetadataLogLevelWarning,
    IESMetadataLogLevelError
};

typedef void(^IESMetadataLogBlock)(IESMetadataLogLevel level, NSString *message);

#endif /* IESMetadataStorageDefines_h */
