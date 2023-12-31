//
//  CJPayBindCardValidateManager.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBindCardValidateManager : NSObject

// 校验身份证号码(严格)
+ (BOOL)isNormalIDCardNumExtremeValid:(NSString *)idNumStr;
// 校验姓名
+ (BOOL)isNameValid:(NSString *)nameStr;
// 校验姓名中是否含有特殊字符
+ (BOOL)isContainSpecialCharacterInString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
