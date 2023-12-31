//
//  IESWebPRepresentation.h
//  IESWebKit
//
//  Created by li keliang on 2018/10/12.
//

FOUNDATION_EXTERN BOOL IESDataIsWebPFormat(NSData * __nonnull webPData);

FOUNDATION_EXTERN NSData * __nullable IESConvertDataWebP2APNG(NSData * __nonnull webPData, NSError * _Nullable __autoreleasing * _Nullable error);
