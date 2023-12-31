//
//  IESGurdLogProxy.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2021/3/12.
//

#import <Foundation/Foundation.h>

#import "IESGurdProtocolDefines.h"

NS_ASSUME_NONNULL_BEGIN

#define IESGurdLogInfo(format, ...)         IESGurdLog(IESGurdLogLevelInfo, format, ##__VA_ARGS__)
#define IESGurdLogWarning(format, ...)      IESGurdLog(IESGurdLogLevelWarning, format, ##__VA_ARGS__)
#define IESGurdLogError(format, ...)        IESGurdLog(IESGurdLogLevelError, format, ##__VA_ARGS__)

extern void IESGurdLogAddDelegate(id<IESGurdLogProxyDelegate> delegate);
extern void IESGurdLogRemoveDelegate(id<IESGurdLogProxyDelegate> delegate);
extern void IESGurdLog(IESGurdLogLevel level, NSString *format, ...);

NS_ASSUME_NONNULL_END
