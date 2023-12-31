//
//  AWELazyRegisterDebugAlert.h
//  AWELazyRegister
//
//  Created by liqingyao on 2019/11/27.
//

#import <Foundation/Foundation.h>
#import "AWELazyRegister.h"

#define AWELazyRegisterModuleDebugAlert "DebugAlert"
#define AWELazyRegisterDebugAlert() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleDebugAlert)

NS_ASSUME_NONNULL_BEGIN

@interface AWELazyRegisterDebugAlert : NSObject

@end

NS_ASSUME_NONNULL_END
