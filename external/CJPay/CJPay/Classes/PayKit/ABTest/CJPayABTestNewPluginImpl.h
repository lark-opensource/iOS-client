//
//  CJPayABTestNewPluginImpl.h
//  CJPay-CJPayDemoTools-Example
//
//  Created by 孟源 on 2022/5/16.
//

#import <Foundation/Foundation.h>
#import "CJPayABTestNewPlugin.h"

#define CJPayRegisterABTest [CJPayABTestNewPluginImpl defaultService]
NS_ASSUME_NONNULL_BEGIN

@interface CJPayABTestNewPluginImpl : NSObject<CJPayABTestNewPlugin>

+ (instancetype)defaultService;

@end

NS_ASSUME_NONNULL_END
