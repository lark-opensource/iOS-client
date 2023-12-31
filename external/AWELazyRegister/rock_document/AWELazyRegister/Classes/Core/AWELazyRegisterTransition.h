//
//  AWELazyRegisterTransition.h
//  AWETransition
//
//  Created by liqingyao on 2019/11/20.
//

#import <Foundation/Foundation.h>
#import "AWELazyRegister.h"

#define AWELazyRegisterModuleTransition "Transition"
#define AWELazyRegisterTransition() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleTransition)

NS_ASSUME_NONNULL_BEGIN

@interface AWELazyRegisterTransition : NSObject

@end

NS_ASSUME_NONNULL_END
