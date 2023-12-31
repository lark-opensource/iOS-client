//
//  CJPayEnvManager.h
//  CJPay
//
//  Created by 王新华 on 2019/1/6.
//

#import <Foundation/Foundation.h>
#import "CJPayCommonSafeHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayEnvManager : NSObject

+ (instancetype)shared;

- (BOOL)isSafeEnv;

- (NSDictionary *)appendParamTo:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
