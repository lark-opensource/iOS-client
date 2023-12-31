//
//  AWELazyRegisterUserModel.h
//  AWELazyRegister
//
//  Created by liqingyao on 2019/12/1.
//

#import <Foundation/Foundation.h>
#import "AWELazyRegister.h"

#define AWELazyRegisterModuleUserModel "UserModel"
#define AWELazyRegisterUserModel() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleUserModel)

NS_ASSUME_NONNULL_BEGIN

@interface AWELazyRegisterUserModel : NSObject

@end

NS_ASSUME_NONNULL_END
