//
//  CJPayPassKitSafeUtil.h
//  CJPay
//
//  Created by 张海阳 on 2019/6/25.
//

#import <Foundation/Foundation.h>
#import "CJPaySafeManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayPassKitSafeUtil : NSObject

+ (BOOL)checkStringSecureEnough:(NSString *)string;

+ (NSDictionary *)pMemberSecureRequestParams:(NSDictionary *)contentDic;

@end

NS_ASSUME_NONNULL_END
