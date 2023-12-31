//
//  AWELazyRegisterRN.h
//  AWELazyRegister
//
//  Created by liqingyao on 2019/12/4.
//

#import <Foundation/Foundation.h>
#import "AWELazyRegister.h"

#define AWELazyRegisterModuleRN "RN"
#define AWELazyRegisterRN() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleRN)

NS_ASSUME_NONNULL_BEGIN

@interface AWELazyRegisterRN : NSObject

@end

NS_ASSUME_NONNULL_END
