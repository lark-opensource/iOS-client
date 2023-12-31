//
//  AWELazyRegisterDebugTools.h
//  AWELazyRegister
//
//  Created by 陈煜钏 on 2020/12/25.
//

#if INHOUSE_TARGET

#import "AWELazyRegister.h"

#define AWELazyRegisterModuleDebugTools "DebugTools"
#define AWELazyRegisterDebugTools() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleDebugTools)

extern void AWEEvaluateLazyRegisterDebugTools();

NS_ASSUME_NONNULL_BEGIN

@interface AWELazyRegisterDebugTools : NSObject

@end

NS_ASSUME_NONNULL_END

#endif
