#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "IESMetadataIndexesMap.h"
#import "IESMetadataLog.h"
#import "IESMetadataMappedFile.h"
#import "IESMetadataProtocol.h"
#import "IESMetadataStorage.h"
#import "IESMetadataStorageConfiguration.h"
#import "IESMetadataStorageDefines+Private.h"
#import "IESMetadataStorageDefines.h"
#import "IESMetadataStorageInfo.h"
#import "IESMetadataUtils.h"
#import "NSData+IESMetadata.h"
#import "NSError+IESMetadata.h"

FOUNDATION_EXPORT double IESMetadataStorageVersionNumber;
FOUNDATION_EXPORT const unsigned char IESMetadataStorageVersionString[];
