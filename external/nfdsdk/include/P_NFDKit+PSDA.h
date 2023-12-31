//
//  P_NFDKit+PSDA.h
//  nfdsdk
//
//  Created by lujunhui.2nd on 2023/8/25.
//
#import <Foundation/Foundation.h>
#import "NFDKit.h"
#if __has_include(<LarkSensitivityControl/LarkSensitivityControl-Swift.h>)
#import <Photos/Photos.h>
#import <CoreMotion/CoreMotion.h>
#import <LarkSensitivityControl/LarkSensitivityControl-Swift.h>
#endif

#ifndef P_NFDKit_PSDA_h
#define P_NFDKit_PSDA_h
NS_ASSUME_NONNULL_BEGIN


@interface NFDKit (PSDA)

#if __has_include(<LarkSensitivityControl/LarkSensitivityControl-Swift.h>)
+ (Token *)p_getBleScanPSDAToken;
+ (void)p_setBleScanPSDAToken:(nullable Token *)newValue;
#endif

@end



NS_ASSUME_NONNULL_END
#endif /* P_NFDKit_PSDA_h */
