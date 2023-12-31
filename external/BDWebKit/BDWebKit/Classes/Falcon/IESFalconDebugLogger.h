//
//  IESFalconDebugLogger.h
//  BDWebKit-Pods-Aweme
//
//  Created by 陈煜钏 on 2020/3/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern void IESFalconDebugLogWrapper (NSString *message);

#define IESFalconDebugLog(__message, ...)     \
IESFalconDebugLogWrapper([NSString stringWithFormat:(__message), ##__VA_ARGS__]);    \

NS_ASSUME_NONNULL_END
