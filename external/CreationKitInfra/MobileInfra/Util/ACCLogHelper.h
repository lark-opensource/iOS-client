//
//  ACCLogHelper.h
//  CameraClient-Pods-Aweme
//
//  Created by lixingdong on 2021/1/9.
//

#import <Foundation/Foundation.h>
#import "ACCCommonDefine.h"
#import "ACCLogProtocol.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN void AWELogToolInfo(AWELogToolTag tag, NSString * _Nonnull format, ...);
FOUNDATION_EXTERN void AWELogToolError(AWELogToolTag tag, NSString * _Nonnull format, ...);
FOUNDATION_EXTERN void AWELogToolWarn(AWELogToolTag tag, NSString * _Nonnull format, ...);
FOUNDATION_EXTERN void AWELogToolDebug(AWELogToolTag tag, NSString * _Nonnull format, ...);
FOUNDATION_EXTERN void AWELogToolVerbose(AWELogToolTag tag, NSString * _Nonnull format, ...);

FOUNDATION_EXTERN void AWELogToolInfo2(NSString *subTag, AWELogToolTag tag, NSString * _Nonnull format, ...);
FOUNDATION_EXTERN void AWELogToolError2(NSString *subTag, AWELogToolTag tag, NSString * _Nonnull format, ...);
FOUNDATION_EXTERN void AWELogToolWarn2(NSString *subTag, AWELogToolTag tag, NSString * _Nonnull format, ...);
FOUNDATION_EXTERN void AWELogToolDebug2(NSString *subTag, AWELogToolTag tag, NSString * _Nonnull format, ...);
FOUNDATION_EXTERN void AWELogToolVerbose2(NSString *subTag, AWELogToolTag tag, NSString * _Nonnull format, ...);

NS_ASSUME_NONNULL_END
