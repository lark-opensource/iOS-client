//
//  AWELazyRegisterAccountPlatform.h
//  AWELazyRegister
//
//  Created by liqingyao on 2019/12/3.
//

#import <Foundation/Foundation.h>
#import "AWELazyRegister.h"

#define AWELazyRegisterModuleAccountPlatform "AccountPlatform"
#define AWELazyRegisterAccountPlatform() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleAccountPlatform)

NS_ASSUME_NONNULL_BEGIN

@interface AWELazyRegisterAccountPlatform : NSObject

@end

NS_ASSUME_NONNULL_END
