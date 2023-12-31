//
//  AWELazyRegisterJSBridge.h
//  AWELazyRegister
//
//  Created by liqingyao on 2019/12/4.
//

#import <Foundation/Foundation.h>
#import "AWELazyRegister.h"

#if __has_include(<AWELazyRegister/AWELazyRegister_Rename.h>)
#import <AWELazyRegister/AWELazyRegister_Rename.h>
#endif

#define AWELazyRegisterModulePiper "JSBridge"
#define AWELazyRegisterPiper() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModulePiper)

extern void evaluateLazyRegisterPiperHandler();
extern bool shouldRegisterPiperHandler();

NS_ASSUME_NONNULL_BEGIN

@interface AWELazyRegisterPiper : NSObject

@end

NS_ASSUME_NONNULL_END
