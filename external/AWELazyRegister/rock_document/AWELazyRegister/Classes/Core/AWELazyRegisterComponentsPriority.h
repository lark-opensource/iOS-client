//
//  AWELazyRegisterComponentsPriority.h
//  AWELazyRegister
//
//  Created by liqingyao on 2019/11/28.
//

#import <Foundation/Foundation.h>
#import "AWELazyRegister.h"

#define AWELazyRegisterModuleComponentPriority "CompPriority"
#define AWELazyRegisterComponentPriority() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleComponentPriority)

NS_ASSUME_NONNULL_BEGIN

@interface AWELazyRegisterComponentsPriority : NSObject

@end

NS_ASSUME_NONNULL_END
