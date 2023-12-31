//
//  AWELazyRegisterRouter.h
//  AWELazyRegister-Pods-Aweme
//
//  Created by 陈煜钏 on 2020/4/26.
//

#import <Foundation/Foundation.h>

#import "AWELazyRegister.h"

#define AWELazyRegisterModuleRouter "Router"
#define AWELazyRegisterRouter(URLString) AWELazyRegisterBlock(URLString, AWELazyRegisterModuleRouter)

#define AWELazyRegisterModuleRouterBackup "RouterBackup"
#define AWELazyRegisterRouterBackup() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleRouterBackup)

#if INHOUSE_TARGET && TEST_MODE
#define AWELazyRegisterModuleRouterRecord "RouterRecord"
#define AWELazyRegisterRouterRecord() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleRouterRecord)
#endif

extern BOOL AWECanEvaluateLazyRegisterRouterInfo(NSString *URLString);
extern void AWEEvaluateLazyRegisterRouterInfo(NSString *URLString);
extern void AWEEvaluateLazyRegisterRouterBackup();

#if INHOUSE_TARGET && TEST_MODE
extern void AWEEvaluateLazyRegisterRouterRecord();
#endif

NS_ASSUME_NONNULL_BEGIN

@interface AWELazyRegisterRouter : NSObject

@end

NS_ASSUME_NONNULL_END
