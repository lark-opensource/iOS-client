//
//  AWELazyRegisterWebImage.h
//  AWELazyRegister
//
//  Created by liqingyao on 2019/12/1.
//

#import <Foundation/Foundation.h>
#import "AWELazyRegister.h"

#define AWELazyRegisterModuleWebImage "WebImage"
#define AWELazyRegisterWebImage() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleWebImage)

NS_ASSUME_NONNULL_BEGIN

@interface AWELazyRegisterWebImage : NSObject

@end

NS_ASSUME_NONNULL_END
