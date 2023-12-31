//
//  AWELazyRegisterCarrierService.h
//  AWELazyRegister
//
//  Created by liqingyao on 2019/12/3.
//

#import <Foundation/Foundation.h>
#import "AWELazyRegister.h"

#define AWELazyRegisterModuleCarrierService "CarrierService"
#define AWELazyRegisterCarrierService() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleCarrierService)

NS_ASSUME_NONNULL_BEGIN

@interface AWELazyRegisterCarrierService : NSObject

@end

NS_ASSUME_NONNULL_END
