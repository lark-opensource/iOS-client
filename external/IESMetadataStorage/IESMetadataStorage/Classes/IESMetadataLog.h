//
//  IESMetadataLog.h
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/28.
//

#import <Foundation/Foundation.h>

#import "IESMetadataStorageDefines.h"

NS_ASSUME_NONNULL_BEGIN

#define IESMetadataLogInfo(format, ...)         IESMetadataLog(IESMetadataLogLevelInfo, format, ##__VA_ARGS__)
#define IESMetadataLogWarning(format, ...)      IESMetadataLog(IESMetadataLogLevelWarning, format, ##__VA_ARGS__)
#define IESMetadataLogError(format, ...)        IESMetadataLog(IESMetadataLogLevelError, format, ##__VA_ARGS__)

extern void IESMetadataSetLogBlock (IESMetadataLogBlock logBlock);
extern void IESMetadataLog(IESMetadataLogLevel level, const char *format, ...);

NS_ASSUME_NONNULL_END
