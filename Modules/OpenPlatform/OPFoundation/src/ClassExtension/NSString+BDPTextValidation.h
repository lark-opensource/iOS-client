//
//  NSString+BDPTextValidation.h
//  Timor
//
//  Created by 刘春喜 on 2019/12/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (BDPTextValidation)

/// 是否为合法的身份证号码
- (BOOL)bdp_isValidIdentityCard;

/// 是否为汉字
- (BOOL)bdp_isValidChineseCharacters;

/// 是否为合法的身份证号码输入,由数字和X组成
- (BOOL)bdp_isValidIdentityCardInput;

@end

NS_ASSUME_NONNULL_END
